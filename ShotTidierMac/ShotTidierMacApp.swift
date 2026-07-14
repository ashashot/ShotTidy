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
    @State private var updateService = AppUpdateService()
    @State private var extensionInbox = MacExtensionInbox()
    @State private var showImportBanner = false
    @State private var bannerDismissTask: Task<Void, Never>?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Screenshot.self,
            CatalogItem.self,
            UserCategory.self,
        ])
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "ShotTidierMac", directoryHint: .isDirectory)
            .appending(path: "ShotTidy.sqlite")

        let isPro = MacSubscriptionManager.loadIsProStatus()

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
    }()

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
                .environment(categoryStore)
                .environment(subscriptionManager)
                .environment(syncMonitor)
                .environment(usageManager)
                .task {
                    // Import items saved by the Safari extension (also subscribes
                    // to live updates while the app is running).
                    extensionInbox.start(context: sharedModelContainer.mainContext)
                    await subscriptionManager.onLaunch()
                    // Check rolling 30-day reset now that we know the subscription state.
                    usageManager.performRollingReset(isPro: subscriptionManager.isProActive)
                    // Check remote config for a required update (runs in background).
                    await updateService.check()
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
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: updateService.state == .required)
                .alert(
                    "Restart Required",
                    isPresented: .init(
                        get: { subscriptionManager.needsRestartForSyncChange },
                        set: { _ in subscriptionManager.acknowledgeRestartPrompt() }
                    )
                ) {
                    Button("OK") {
                        subscriptionManager.acknowledgeRestartPrompt()
                    }
                } message: {
                    if subscriptionManager.isProActive {
                        Text("iCloud sync has been enabled. Please restart the app to start syncing your catalog across devices.")
                    } else {
                        Text("iCloud sync has been disabled. Please restart the app to apply changes.")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .newItem) {
                EmptyView()
            }
        }

        Settings {
            MacSettingsView()
                .modelContainer(sharedModelContainer)
                .environment(subscriptionManager)
                .environment(syncMonitor)
                .environment(usageManager)
        }
    }
}
