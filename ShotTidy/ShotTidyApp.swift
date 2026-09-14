//
//  ShotTidyApp.swift
//  ShotTidy
//

import SwiftUI
import SwiftData

@main
struct ShotTidyApp: App {

    // MARK: - Managers (injected into the environment)

    @State private var subscriptionManager: SubscriptionManager
    @State private var usageManager        = UsageManager()
    @State private var categoryStore       = CategoryStore()
    @State private var updateService       = AppUpdateService()
    @State private var localizationManager: LocalizationManager
    @State private var analysisEngineSettings = AnalysisEngineSettings()

    // MARK: - SwiftData container

    /// The live container. Rebuilt in place when the Pro status changes so
    /// iCloud sync switches on/off without restarting the app.
    @State private var modelContainer: ModelContainer
    /// The Pro state the current container was built for (CloudKit on/off).
    @State private var containerIsPro: Bool
    /// Bumped on every container swap so the whole view tree (and its
    /// `@Query` / `modelContext` bindings) is recreated against the new container.
    @State private var containerGeneration = 0

    // MARK: - Init

    init() {
        #if DEBUG
        // App Store screenshot scenes: seed Pro status and language before the managers read them.
        DemoMode.prepareSharedState()
        #endif
        _subscriptionManager = State(initialValue: SubscriptionManager())
        _localizationManager = State(initialValue: LocalizationManager())

        // OpenAI key now lives in Supabase Secrets (server-side).
        // No local key to sync — AppGroupManager.apiKey is no longer used.

        // Remove the legacy PendingImages directory left over from v1 of the Share Extension flow.
        AppGroupManager.purgeLegacyPendingImages()

        let isPro = AppGroupManager.loadIsProStatus()
        _modelContainer = State(initialValue: Self.initialModelContainer(isPro: isPro))
        _containerIsPro = State(initialValue: isPro)
    }

    private static func initialModelContainer(isPro: Bool) -> ModelContainer {
        #if DEBUG
        if DemoMode.isActive { return DemoMode.makeModelContainer() }
        #endif
        return makeModelContainer(isPro: isPro)
    }

    /// Builds the container for the shared App Group store. Pro tier gets a
    /// CloudKit-backed configuration; everything else stays local-only.
    private static func makeModelContainer(isPro: Bool) -> ModelContainer {
        let schema = Schema([
            Screenshot.self,
            CatalogItem.self,
            UserCategory.self,
        ])

        // Store lives in the App Group container so the Share Extension can write directly.
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroupManager.groupID)!
        let storeURL = groupURL.appending(path: "ShotTidy.sqlite")

        // One-time migration: copy the store from the old app-sandbox location.
        let oldURL = URL.applicationSupportDirectory.appending(path: "ShotTidy.sqlite")
        if !FileManager.default.fileExists(atPath: storeURL.path),
           FileManager.default.fileExists(atPath: oldURL.path) {
            for suffix in ["", "-wal", "-shm"] {
                let src = URL(fileURLWithPath: oldURL.path + suffix)
                let dst = URL(fileURLWithPath: storeURL.path + suffix)
                try? FileManager.default.copyItem(at: src, to: dst)
            }
        }

        if isPro {
            // Pro tier: CloudKit sync enabled.
            let cloudConfig = ModelConfiguration(
                "ShotTidy",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private("iCloud.com.mbx.ShotTidier")
            )
            do {
                return try ModelContainer(for: schema, configurations: [cloudConfig])
            } catch {
                // Falling back to local-only storage. Log the reason so CloudKit
                // sync misconfiguration (entitlements, container schema) is visible.
                print("⚠️ CloudKit ModelContainer creation failed, falling back to local store: \(error)")
            }
        }

        // Free tier (or CloudKit fallback): local storage only, no sync.
        let localConfig = ModelConfiguration(
            "ShotTidy",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        if let container = try? ModelContainer(for: schema, configurations: [localConfig]) {
            return container
        }

        fatalError("Failed to create ModelContainer")
    }

    /// Swaps the container when the Pro status no longer matches the one the
    /// container was built for. The store file stays the same — only the
    /// CloudKit configuration changes — so this is what a restart used to do,
    /// minus the restart.
    private func applySyncConfigurationIfNeeded() {
        Task { @MainActor in
            // Let the paywall's dismiss animation finish before the view tree is rebuilt.
            try? await Task.sleep(for: .milliseconds(600))
            let isPro = subscriptionManager.isProActive
            guard isPro != containerIsPro else { return }
            modelContainer = Self.makeModelContainer(isPro: isPro)
            containerIsPro = isPro
            containerGeneration += 1
        }
    }

    /// Grants or clears plan credits and claims the Lifetime credit pool when due.
    private func syncUsageWithPlan() async {
        let plan = subscriptionManager.activePlan
        usageManager.applyPlan(plan)
        if plan == .lifetime {
            await usageManager.claimLifetimeCreditsIfNeeded {
                await subscriptionManager.claimLifetimeCredits()
            }
        }
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .id(containerGeneration)
                .environment(subscriptionManager)
                .environment(usageManager)
                .environment(categoryStore)
                .environment(localizationManager)
                .environment(analysisEngineSettings)
                .environment(\.locale, localizationManager.resolvedLocale)
                .task {
                    #if DEBUG
                    // Demo scenes run against seeded data — no StoreKit, quota or update checks.
                    guard !DemoMode.isActive else { return }
                    #endif
                    // Load StoreKit products and verify subscription status on launch.
                    await subscriptionManager.onLaunch()
                    // Align usage counters and credits with the plan StoreKit reported.
                    await syncUsageWithPlan()
                    // Check remote config for a required update (runs in background).
                    await updateService.check()
                }
                .onChange(of: subscriptionManager.isProActive) { _, _ in
                    applySyncConfigurationIfNeeded()
                }
                .onChange(of: subscriptionManager.activePlan) { _, _ in
                    Task { await syncUsageWithPlan() }
                }
                // Force update overlay — covers the entire UI, cannot be dismissed.
                .overlay {
                    if updateService.state == .required {
                        ForceUpdateView()
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: updateService.state == .required)
        }
        .modelContainer(modelContainer)
    }
}
