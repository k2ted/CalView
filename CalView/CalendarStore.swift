//
//  CalendarStore.swift
//  CalView
//
//  Created by Donald Edwards on 09/11/2026.
//

import SwiftUI
import EventKit

@MainActor
@Observable
class CalendarStore {
    private let store = EKEventStore()
    var events: [EKEvent] = []
    var calendars: [EKCalendar] = []
    var weekStarts: [Date] = []
    var accessDenied = false

    var hiddenIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "hiddenCalendars") ?? []) {
        didSet {
            UserDefaults.standard.set(Array(hiddenIDs), forKey: "hiddenCalendars")
        }
    }

    var visibleEvents: [EKEvent] {
        events.filter { !hiddenIDs.contains($0.calendar?.calendarIdentifier ?? "") }
    }

    func isVisible(_ calendar: EKCalendar) -> Bool {
        !hiddenIDs.contains(calendar.calendarIdentifier)
    }

    func toggle(_ calendar: EKCalendar) {
        if hiddenIDs.contains(calendar.calendarIdentifier) {
            hiddenIDs.remove(calendar.calendarIdentifier)
        } else {
            hiddenIDs.insert(calendar.calendarIdentifier)
        }
    }
    
    func showAll() {
        hiddenIDs = []
    }

    func hideAll() {
        hiddenIDs = Set(calendars.map { $0.calendarIdentifier })
    }

    func load(months: Int) async {
        do {
            let granted = try await store.requestFullAccessToEvents()
            guard granted else {
                accessDenied = true
                return
            }

            calendars = store.calendars(for: .event).sorted { $0.title < $1.title }

            let cal = Calendar.current
            let monthStart = cal.dateInterval(of: .month, for: Date())!.start
            let start = cal.dateInterval(of: .weekOfYear, for: monthStart)!.start
            let end = cal.date(byAdding: .month, value: months, to: monthStart)!

            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
            events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

            var weeks: [Date] = []
            var current = start
            while current < end {
                weeks.append(current)
                current = cal.date(byAdding: .weekOfYear, value: 1, to: current)!
            }
            weekStarts = weeks
        } catch {
            accessDenied = true
        }
    }
}
