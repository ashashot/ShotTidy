//
//  CloudSyncMonitor.swift
//  ShotTidy
//

import SwiftUI
import CoreData
import SwiftData

@Observable
@MainActor
final class CloudSyncMonitor {

    // MARK: - State

    enum SyncState {
        case idle
        case syncing
        case error(String)

        var isSyncing: Bool {
            if case .syncing = self { return true }
            return false
        }

        var errorMessage: String? {
            if case .error(let msg) = self { return msg }
            return nil
        }
    }

    private(set) var state: SyncState = .idle
    private(set) var lastSyncDate: Date?

    var isSyncing: Bool { state.isSyncing }

    // MARK: - Private

    private var observer: NSObjectProtocol?
    private var fallbackTask: Task<Void, Never>?

    private static let lastSyncKey = "CloudSyncMonitor.lastSyncDate"

    // MARK: - Init

    init() {
        lastSyncDate = UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Date
        startObserving()
    }

    // MARK: - Trigger manual sync

    func triggerSync(context: ModelContext) {
        guard !state.isSyncing else { return }
        state = .syncing
        try? context.save()

        // Fallback: if no CloudKit event arrives within 5 s, mark as done.
        fallbackTask?.cancel()
        fallbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard let self, case .syncing = self.state else { return }
            self.state = .idle
            self.updateLastSyncDate(Date())
        }
    }

    // MARK: - CloudKit event observation

    private func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            MainActor.assumeIsolated { self.handle(notification) }
        }
    }

    private func handle(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }

        if event.endDate == nil {
            state = .syncing
        } else if event.succeeded {
            fallbackTask?.cancel()
            state = .idle
            updateLastSyncDate(event.endDate ?? Date())
        } else {
            fallbackTask?.cancel()
            state = .error(event.error?.localizedDescription ?? String(localized: "Unknown iCloud error", bundle: AppLocale.bundle))
        }
    }

    private func updateLastSyncDate(_ date: Date) {
        lastSyncDate = date
        UserDefaults.standard.set(date, forKey: Self.lastSyncKey)
    }
}
