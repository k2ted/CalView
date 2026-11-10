//
//  WeekRow.swift
//  CalView
//
//  Created by Donald Edwards on 09/11/2026.
//

import SwiftUI
import EventKit

struct WeekRow: View {
    let weekStart: Date
    let events: [EKEvent]
    let onSelect: (EKEvent) -> Void
    let onShowDay: (Date, [EKEvent]) -> Void

    private var days: [Date] {
        (0..<7).map { Calendar.current.date(byAdding: .day, value: $0, to: weekStart)! }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(days, id: \.self) { day in
                DayCell(day: day, events: eventsOn(day), onSelect: onSelect, onShowDay: onShowDay)
            }
        }
    }

    private func eventsOn(_ day: Date) -> [EKEvent] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: day)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        return events.filter {
            $0.startDate < dayEnd && ($0.endDate > dayStart || $0.startDate >= dayStart)
        }
    }
}

struct DayCell: View {
    let day: Date
    let events: [EKEvent]
    let onSelect: (EKEvent) -> Void
    let onShowDay: (Date, [EKEvent]) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showEventTimes") private var showTimes = false

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    private var isEvenMonth: Bool {
        Calendar.current.component(.month, from: day) % 2 == 0
    }

    private var headerText: String {
        let isFirst = Calendar.current.component(.day, from: day) == 1
        return day.formatted(
            isFirst
                ? .dateTime.weekday(.abbreviated).month(.abbreviated).day()
                : .dateTime.weekday(.abbreviated).day()
        )
    }

    private var sortedEvents: [EKEvent] {
        events.sorted { a, b in
            if a.isAllDay != b.isAllDay { return a.isAllDay }
            return a.startDate < b.startDate
        }
    }

    private func label(for event: EKEvent) -> String {
        let title = event.title ?? "Untitled"
        guard showTimes,
              !event.isAllDay,
              Calendar.current.isDate(event.startDate, inSameDayAs: day) else {
            return title
        }
        let time = event.startDate.formatted(.dateTime.hour().minute())
        return "\(time) \(title)"
    }

    private func color(for event: EKEvent) -> Color {
        if let cg = event.calendar?.cgColor {
            return Color(cgColor: cg)
        }
        return .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headerText)
                .font(.caption.bold())
                .padding(.horizontal, 4)
                .background(isToday ? Color.red : Color.clear)
                .foregroundStyle(isToday ? Color.white : Color.primary)
                .clipShape(Capsule())

            ForEach(Array(sortedEvents.prefix(3).enumerated()), id: \.offset) { item in
                let eventColor = color(for: item.element)
                Text(label(for: item.element))
                    .font(.caption2)
                    .lineLimit(1)
                    .padding(.vertical, 2)
                    .padding(.leading, 6)
                    .padding(.trailing, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(eventColor.opacity(0.25))
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(eventColor)
                            .frame(width: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .onTapGesture { onSelect(item.element) }
            }

            if events.count > 3 {
                Text("+\(events.count - 3) more")
                    .font(.caption2.bold())
                    .foregroundStyle(.blue)
                    .onTapGesture { onShowDay(day, sortedEvents) }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
        .padding(4)
        .background(
            isToday
                ? Color.red.opacity(0.12)
                : Color.gray.opacity(isEvenMonth ? 0.08 : (colorScheme == .dark ? 0.32 : 0.22))
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isToday ? Color.red : Color.clear, lineWidth: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture { onShowDay(day, sortedEvents) }
    }
}
