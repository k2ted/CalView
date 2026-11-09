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

    private var days: [Date] {
        (0..<7).map { Calendar.current.date(byAdding: .day, value: $0, to: weekStart)! }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(days, id: \.self) { day in
                DayCell(day: day, events: eventsOn(day))
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

    private func color(for event: EKEvent) -> Color {
        if let cg = event.calendar?.cgColor {
            return Color(cgColor: cg)
        }
        return .blue
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(day, format: .dateTime.weekday(.abbreviated).day())
                .font(.caption.bold())
                .padding(.horizontal, 4)
                .background(isToday ? Color.red : Color.clear)
                .foregroundStyle(isToday ? Color.white : Color.primary)
                .clipShape(Capsule())

            ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { item in
                let eventColor = color(for: item.element)
                Text(item.element.title ?? "Untitled")
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
            }

            if events.count > 3 {
                Text("+\(events.count - 3) more")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
        .padding(4)
        .background(isToday ? Color.red.opacity(0.12) : Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isToday ? Color.red : Color.clear, lineWidth: 2)
        ).opacity(day < Calendar.current.startOfDay(for: Date()) ? 0.45 : 1)
    }
}
