//
//  CalendarService.swift
//  ShotTidy
//
//  Manages EventKit access and event creation from CatalogItem.
//

import Combine
import EventKit
import EventKitUI
import SwiftUI

@MainActor
final class CalendarService: NSObject, ObservableObject, EKEventEditViewDelegate {

    static let shared = CalendarService()

    let store = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var showEditor = false
    @Published var pendingEvent: EKEvent?
    @Published var showDeniedAlert = false

    private override init() {
        super.init()
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Public API

    func addToCalendar(item: CatalogItem) {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess, .writeOnly:
            openEditor(for: item)
        case .notDetermined:
            requestAccess { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.openEditor(for: item)
                } else {
                    self.showDeniedAlert = true
                }
            }
        default:
            showDeniedAlert = true
        }
    }

    // MARK: - EKEventEditViewDelegate

    nonisolated func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        Task { @MainActor in
            self.showEditor = false
            self.pendingEvent = nil
        }
    }

    // MARK: - Private

    private func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17, *) {
            store.requestWriteOnlyAccessToEvents { granted, _ in
                DispatchQueue.main.async { completion(granted) }
            }
        } else {
            store.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async { completion(granted) }
            }
        }
    }

    private func openEditor(for item: CatalogItem) {
        let event = EKEvent(eventStore: store)
        event.title = item.title

        if let date = item.calendarDate {
            event.startDate = date
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
            event.isAllDay = isLikelyAllDay(date: date)
        } else {
            // No date parsed — default to tomorrow at noon
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 12
            event.startDate = Calendar.current.date(from: components) ?? tomorrow
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: event.startDate) ?? event.startDate
        }

        let notes = item.calendarEventNotes
        if !notes.isEmpty {
            event.notes = notes
        }

        event.calendar = store.defaultCalendarForNewEvents

        pendingEvent = event
        showEditor = true
    }

    // Heuristic: if the time is exactly midnight it was likely date-only detection
    private func isLikelyAllDay(date: Date) -> Bool {
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return comps.hour == 0 && comps.minute == 0 && comps.second == 0
    }
}

// MARK: - SwiftUI Representable

struct CalendarEventEditorView: UIViewControllerRepresentable {
    @ObservedObject var service: CalendarService
    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()
        vc.event = service.pendingEvent
        vc.eventStore = service.store
        vc.editViewDelegate = service
        return vc
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
}
