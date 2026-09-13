//
//  ShotTidierMacApp.swift
//  ShotTidierMac
//
//  Entry point for the macOS version of ShotTidier.
//  NavigationSplitView (sidebar + content + detail) replaces the iOS TabView.
//

import SwiftUI
import SwiftData

@main
struct ShotTidierMacApp: App {

    @State private var categoryStore = CategoryStore()
    @State private var subscriptionManager = MacSubscriptionManager()
    @State private var syncMonitor = MacCloudSyncMonitor()
    @State private var usageManager = UsageManager()
    @State private var analysisEngineSettings = AnalysisEngineSettings()
    @State private var updateService = AppUpdateService()
    @State private var extensionInbox = MacExtensionInbox()
    @State private var showImportBanner = false
    @State private var bannerDismissTask: Task<Void, Never>?

    // MARK: - SwiftData container

    /// The live container. Rebuilt in place when the Pro status changes so
    /// iCloud sync switches on/off without restarting the app.
    @State private var modelContainer: ModelContainer
    /// The Pro state the current container was built for (CloudKit on/off).
    @State private var containerIsPro: Bool
    /// Bumped on every container swap so the window's view tree (and its
    /// `@Query` / `modelContext` bindings) is recreated against the new container.
    @State private var containerGeneration = 0

    init() {
        let isPro = MacSubscriptionManager.loadIsProStatus()
        _modelContainer = State(initialValue: Self.makeModelContainer(isPro: isPro))
        _containerIsPro = State(initialValue: isPro)
    }

    /// Pro tier gets a CloudKit-backed configuration; everything else stays local-only.
    private static func makeModelContainer(isPro: Bool) -> ModelContainer {
        let schema = Schema([
            Screenshot.self,
            CatalogItem.self,
            UserCategory.self,
        ])
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "ShotTidierMac", directoryHint: .isDirectory)
            .appending(path: "ShotTidy.sqlite")

        if isPro {
            // Pro tier: CloudKit sync enabled — same container as iOS.
            let cloudConfig = ModelConfiguration(
                "ShotTidierMac",
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

        // Free tier (or CloudKit fallback): local storage only.
        let localConfig = ModelConfiguration(
            "ShotTidierMac",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        guard let container = try? ModelContainer(for: schema, configurations: [localConfig]) else {
            fatalError("Failed to create ModelContainer")
        }
        return container
    }

    /// Swaps the container when the Pro status no longer matches the one the
    /// container was built for. The store file stays the same — only the
    /// CloudKit configuration changes — so this is what a restart used to do,
    /// minus the restart.
    private func applySyncConfigurationIfNeeded() {
        Task { @MainActor in
            let isPro = subscriptionManager.isProActive
            guard isPro != containerIsPro else { return }
            let container = Self.makeModelContainer(isPro: isPro)
            modelContainer = container
            containerIsPro = isPro
            containerGeneration += 1
            // The inbox writes through a stored context — point it at the new store.
            extensionInbox.start(context: container.mainContext)
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

    /// Transient confirmation shown when the Safari extension delivers items.
    private var importBanner: some View {
        Label(
            extensionInbox.lastImportCount == 1
                ? "1 item added from Safari"
                : "\(extensionInbox.lastImportCount) items added from Safari",
            systemImage: "checkmark.circle.fill"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.green)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(containerGeneration)
                .environment(categoryStore)
                .environment(subscriptionManager)
                .environment(syncMonitor)
                .environment(usageManager)
                .environment(analysisEngineSettings)
                .task {
                    // Import items saved by the Safari extension (also subscribes
                    // to live updates while the app is running).
                    extensionInbox.start(context: modelContainer.mainContext)
                    // The update check is independent — run it concurrently with
                    // the StoreKit launch sequence.
                    async let updateCheck: Void = updateService.check()
                    await subscriptionManager.onLaunch()
                    // Align usage counters and credits with the plan StoreKit reported.
                    await syncUsageWithPlan()
                    await updateCheck
                }
                .overlay(alignment: .top) {
                    if showImportBanner {
                        importBanner
                    }
                }
                .onChange(of: extensionInbox.importEvent) {
                    guard extensionInbox.importEvent > 0 else { return }
                    withAnimation(.spring(duration: 0.35)) { showImportBanner = true }
                    bannerDismissTask?.cancel()
                    bannerDismissTask = Task {
                        try? await Task.sleep(for: .seconds(3.5))
                        withAnimation(.easeOut(duration: 0.3)) { showImportBanner = false }
                    }
                }
                .overlay {
                    if updateService.state == .required {
                        MacForceUpdateView()
                    } else if analysisEngineSettings.isUnsupported {
                        // The Mac app is on-device only: without Apple
                        // Intelligence nothing can be analyzed, so the app
                        // refuses to run until the model is available.
                        MacUnsupportedDeviceView(
                            availability: analysisEngineSettings.onDeviceAvailability,
                            onCheckAgain: { analysisEngineSettings.refreshAvailability() }
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: updateService.state == .required)
                .animation(.easeInOut(duration: 0.3), value: analysisEngineSettings.isUnsupported)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    // The user may have just enabled Apple Intelligence in System Settings.
                    analysisEngineSettings.refreshAvailability()
                }
                .onChange(of: subscriptionManager.isProActive) { _, _ in
                    applySyncConfigurationIfNeeded()
                }
                .onChange(of: subscriptionManager.activePlan) { _, _ in
                    Task { await syncUsageWithPlan() }
                }
        }
        .modelContainer(modelContainer)

        Settings {
            MacSettingsView()
                .id(containerGeneration)
                .modelContainer(modelContainer)
                .environment(subscriptionManager)
                .environment(syncMonitor)
                .environment(usageManager)
                .environment(analysisEngineSettings)
        }
    }
}
