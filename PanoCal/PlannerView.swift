//
//  PlannerView.swift
//  PanoCal
//
//  Created by Donald Edwards on 11/11/2026.
//

import SwiftUI
import EventKit

private func plannerColor(for event: EKEvent) -> Color {
    if let cg = event.calendar?.cgColor {
        return Color(cgColor: cg)
    }
    return .blue
}

private func plannerSorted(_ list: [EKEvent]) -> [EKEvent] {
    list.sorted { a, b in
        if a.isAllDay != b.isAllDay { return a.isAllDay }
        return a.startDate < b.startDate
    }
}

struct PlannerView: View {
    let calendar: CalendarStore
    let months: Int
    let onSelect: (EKEvent) -> Void
    let onShowDay: (Date, [EKEvent]) -> Void

    private var monthStarts: [Date] {
        let cal = Calendar.current
        guard let first = cal.dateInterval(of: .month, for: Date())?.start else { return [] }
        return (0..<months).compactMap { cal.date(byAdding: .month, value: $0, to: first) }
    }

    // Groups the events by the day(s) they fall on, so each cell can look its events up quickly.
    private func eventsByDay(rangeStart: Date, rangeEnd: Date) -> [Date: [EKEvent]] {
        let cal = Calendar.current
        var result: [Date: [EKEvent]] = [:]
        guard let lastAllowed = cal.date(byAdding: .day, value: -1, to: rangeEnd) else { return result }

        for event in calendar.visibleEvents {
            guard let start = event.startDate, let end = event.endDate else { continue }
            let lastMoment = end > start ? end.addingTimeInterval(-1) : start
            var day = max(cal.startOfDay(for: start), rangeStart)
            let lastDay = min(cal.startOfDay(for: lastMoment), lastAllowed)

            while day <= lastDay {
                result[day, default: []].append(event)
                guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }
        return result
    }

    var body: some View {
        let starts = monthStarts
        let rangeStart = starts.first ?? Date()
        let rangeEnd = Calendar.current.date(byAdding: .month, value: months, to: rangeStart) ?? rangeStart
        let byDay = eventsByDay(rangeStart: rangeStart, rangeEnd: rangeEnd)

        GeometryReader { geo in
            let spacing: CGFloat = 4
            let outerPad: CGFloat = 12
            let headerH: CGFloat = 24
            let rowGap: CGFloat = 2
            let count = CGFloat(max(starts.count, 1))
            let colW = (geo.size.width - outerPad * 2 - spacing * (count - 1)) / count
            let rowH = max(18, (geo.size.height - outerPad * 2 - headerH - rowGap * 31) / 31)

            ScrollView(.vertical) {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(starts, id: \.self) { monthStart in
                        monthColumn(monthStart, byDay: byDay, colW: colW, rowH: rowH,
                                    headerH: headerH, rowGap: rowGap)
                    }
                }
                .padding(outerPad)
            }
        }
    }

    private func monthColumn(_ monthStart: Date, byDay: [Date: [EKEvent]], colW: CGFloat,
                             rowH: CGFloat, headerH: CGFloat, rowGap: CGFloat) -> some View {
        let cal = Calendar.current
        let dayCount = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30

        return VStack(spacing: rowGap) {
            Text(monthStart.formatted(.dateTime.month(.abbreviated).year()))
                .font(.caption.bold())
                .frame(maxWidth: .infinity, minHeight: headerH, maxHeight: headerH)

            ForEach(0..<31, id: \.self) { i in
                if i < dayCount, let date = cal.date(byAdding: .day, value: i, to: monthStart) {
                    PlannerDayCell(
                        date: date,
                        events: plannerSorted(byDay[cal.startOfDay(for: date)] ?? []),
                        width: colW,
                        height: rowH,
                        onSelect: onSelect,
                        onShowDay: onShowDay
                    )
                } else {
                    Color.clear.frame(height: rowH)
                }
            }
        }
        .frame(width: colW)
    }
}

struct PlannerDayCell: View {
    let date: Date
    let events: [EKEvent]
    let width: CGFloat
    let height: CGFloat
    let onSelect: (EKEvent) -> Void
    let onShowDay: (Date, [EKEvent]) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isWeekend: Bool {
        Calendar.current.isDateInWeekend(date)
    }

    private var maxChips: Int {
        let eventWidth = width - 36
        return min(3, max(1, Int(eventWidth / 60)))
    }

    private var cellBackground: Color {
        if isToday { return Color.red.opacity(0.12) }
        if isWeekend { return Color.gray.opacity(colorScheme == .dark ? 0.30 : 0.20) }
        return Color.gray.opacity(colorScheme == .dark ? 0.14 : 0.07)
    }

    private func chip(_ event: EKEvent) -> some View {
        let color = plannerColor(for: event)
        return Text(event.title ?? "Untitled")
            .font(.system(size: 9))
            .lineLimit(1)
            .padding(.leading, 5)
            .padding(.trailing, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: min(height - 6, 18))
            .background(color.opacity(0.3))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(color)
                    .frame(width: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .onTapGesture { onSelect(event) }
    }

    var body: some View {
        let shown = Array(events.prefix(maxChips))
        let overflow = events.count - shown.count

        HStack(spacing: 3) {
            HStack(spacing: 1) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 10, weight: .bold))
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 26, alignment: .leading)

            ForEach(Array(shown.enumerated()), id: \.offset) { item in
                chip(item.element)
            }

            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.blue)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 3)
        .frame(height: height)
        .background(cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isToday ? Color.red : Color.clear, lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture { onShowDay(date, events) }
    }
}
