//
//  CalendarManager.swift
//  sustainableWatch
//
//  Created by Leif Middelschulte on 03.05.23.
//
import SwiftUI
import CoreBluetooth
import EventKit

#if os(macOS)
import AppKit
#endif

struct CalendarEvent: Identifiable {
    var id: UUID
    let title: String
    let startTime: String
}

class CalendarManager: NSObject, ObservableObject {
    private let eventStore = EKEventStore()

    @Published var upcomingEvents: [CalendarEvent] = []
    override init() {
        super.init()
        requestCalendarAccess()
    }

    func requestCalendarAccess() {
        #if os(iOS)
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    self.fetchUpcomingEvents()
                }
            } else {
                print("Calendar access denied")
            }
        }
        #elseif os(macOS)
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            fetchUpcomingEvents()
        case .notDetermined:
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    DispatchQueue.main.async {
                        self.fetchUpcomingEvents()
                    }
                } else {
                    print("Calendar access denied")
                }
            }
        default:
            print("Calendar access denied")
        }
        #endif
    }

    func fetchUpcomingEvents() {
        let predicate = eventStore.predicateForEvents(withStart: Date(), end: Date().addingTimeInterval(60 * 60 * 48), calendars: nil)
        let events = eventStore.events(matching: predicate)

        let sortedEvents = events.sorted(by: { $0.startDate < $1.startDate })
        upcomingEvents = sortedEvents.map { event in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    let startTime = formatter.string(from: event.startDate)
            return CalendarEvent(id: UUID(uuidString: event.eventIdentifier)!, title: event.title, startTime: startTime)
                }
    }
}
