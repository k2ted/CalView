//
//  OverviewView.swift
//  PanoCal
//
//  Created by Donald Edwards on 13/11/2026.
//

import SwiftUI
import EventKit

private func overviewColor(for event: EKEvent) -> Color {
    if let cg = event.calendar?.cgColor {
        return Color(cgColor: cg)
    }
    return .blue
}

private func overviewSorted(_ list: [EKEvent]) -> [EKEvent] {
    list.sorted { a, b in
        if a.isAllDay != b.isAllDay { return a.isAllDay }
        return a.startDate < b.startDate
    }
}

struct OverviewView: View {
    let calendar: CalendarStore
    let months: Int
    let onSelect: (EKEvent) -> Void
    let onShowDay: (Date, [EKEvent]) -> Void

    private var monthStarts: [Date] {
        let cal = Calendar.current
        guard let first = cal.dateInterval(of: .month, for: Date())?.start else { return [] }
        return (0..<months).compactMap { cal.date(byAdding: .month, value: $0, to: first) }
    }

    // Groups the events by the day(s) they fall on.
    private func eventsByDay(events: [EKEvent], rangeStart: Date, rangeEnd: Date) -> [Date: [EKEvent]] {
        let cal = Calendar.current
        var result: [Date: [EKEvent]] = [:]
        guard let lastAllowed = cal.date(byAdding: .day, value: -1, to: rangeEnd) else { return result }

        for event in events {
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

    // How many tiles across and down, depending on the range and the window's shape.
    private func arrangement(width: CGFloat, height: CGFloat) -> (cols: Int, rows: Int) {
        let landscape = width >= height
        switch months {
        case 1: return (1, 1)
        case 3: return landscape ? (3, 1) : (1, 3)
        case 6: return landscape ? (3, 2) : (2, 3)
        default: return landscape ? (4, 3) : (3, 4)
        }
    }

    var body: some View {
        let events = calendar.visibleEvents
        let starts = monthStarts
        let rangeStart = starts.first ?? Date()
        let rangeEnd = Calendar.current.date(byAdding: .month, value: months, to: rangeStart) ?? rangeStart
        let byDay = eventsByDay(events: events, rangeStart: rangeStart, rangeEnd: rangeEnd)

        GeometryReader { geo in
            let outerPad: CGFloat = 12
            let tileGap: CGFloat = 10
            let grid = arrangement(width: geo.size.width, height: geo.size.height)
            let tileW = (geo.size.width - outerPad * 2 - tileGap * CGFloat(grid.cols - 1)) / CGFloat(grid.cols)
            let tileH = (geo.size.height - outerPad * 2 - tileGap * CGFloat(grid.rows - 1)) / CGFloat(grid.rows)

            VStack(spacing: tileGap) {
                ForEach(0..<grid.rows, id: \.self) { r in
                    HStack(spacing: tileGap) {
                        ForEach(0..<grid.cols, id: \.self) { c in
                            let index = r * grid.cols + c
                            if index < starts.count {
                                MonthTile(
                                    monthStart: starts[index],
                                    byDay: byDay,
                                    width: tileW,
                                    height: tileH,
                                    onSelect: onSelect,
                                    onShowDay: onShowDay
                                )
                            } else {
                                Color.clear.frame(width: tileW, height: tileH)
                            }
                        }
                    }
                }
            }
            .padding(outerPad)
        }
    }
}

private struct MonthTile: View {
    let monthStart: Date
    let byDay: [Date: [EKEvent]]
    let width: CGFloat
    let height: CGFloat
    let onSelect: (EKEvent) -> Void
    let onShowDay: (Date, [EKEvent]) -> Void

    private var weekdaySymbols: [String] {
        let cal = Calendar.current
        let symbols = cal.veryShortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    var body: some View {
        let cal = Calendar.current
        let dayCount = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let weekday = cal.component(.weekday, from: monthStart)
        let offset = (weekday - cal.firstWeekday + 7) % 7

        let cellGap: CGFloat = 1
        let innerW = max(width - 12, 10)
        let titleH: CGFloat = 18
        let weekdayH: CGFloat = 12
        let gridH = max(height - 12 - titleH - weekdayH - 4, 10)
        let cellW = max((innerW - cellGap * 6) / 7, 4)
        let cellH = max((gridH - cellGap * 5) / 6, 4)

        VStack(spacing: 2) {
            Text(monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 12, weight: .bold))
                .frame(height: titleH)

            HStack(spacing: cellGap) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { item in
                    Text(item.element)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .frame(width: cellW, height: weekdayH)
                }
            }

            VStack(spacing: cellGap) {
                ForEach(0..<6, id: \.self) { r in
                    HStack(spacing: cellGap) {
                        ForEach(0..<7, id: \.self) { c in
                            let day = r * 7 + c - offset + 1
                            if day >= 1 && day <= dayCount,
                               let date = cal.date(byAdding: .day, value: day - 1, to: monthStart) {
                                OverviewDayCell(
                                    date: date,
                                    events: overviewSorted(byDay[cal.startOfDay(for: date)] ?? []),
                                    width: cellW,
                                    height: cellH,
                                    onSelect: onSelect,
                                    onShowDay: onShowDay
                                )
                            } else {
                                Color.clear.frame(width: cellW, height: cellH)
                            }
                        }
                    }
                }
            }
        }
        .padding(6)
        .frame(width: width, height: height, alignment: .top)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct OverviewDayCell: View {
    let date: Date
    let events: [EKEvent]
    let width: CGFloat
    let height: CGFloat
    let onSelect: (EKEvent) -> Void
    let onShowDay: (Date, [EKEvent]) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.highlightedDays) private var highlightedDays

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isWeekend: Bool {
        Calendar.current.isDateInWeekend(date)
    }

    private var isHighlighted: Bool {
        guard let highlightedDays else { return false }
        return highlightedDays.contains(Calendar.current.startOfDay(for: date))
    }

    // Roomy cells show titles; tight cells show small coloured bars instead.
    private var showChips: Bool {
        width >= 80 && height >= 40
    }

    private var cellBackground: Color {
        if isHighlighted { return Color.accentColor.opacity(0.25) }
        if isToday { return Color.red.opacity(0.12) }
        if isWeekend { return Color.gray.opacity(colorScheme == .dark ? 0.30 : 0.20) }
        return Color.gray.opacity(colorScheme == .dark ? 0.14 : 0.07)
    }

    private func chip(_ event: EKEvent) -> some View {
        let color = overviewColor(for: event)
        return Text(event.title ?? "Untitled")
            .font(.system(size: 8.5))
            .lineLimit(1)
            .padding(.leading, 4)
            .padding(.trailing, 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 12)
            .background(color.opacity(0.3))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(color)
                    .frame(width: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .onTapGesture { onSelect(event) }
    }

    private func bar(_ event: EKEvent) -> some View {
        Capsule()
            .fill(overviewColor(for: event))
            .frame(height: 3)
            .padding(.horizontal, 2)
    }

    var body: some View {
        let lineH: CGFloat = showChips ? 14 : 5
        let capacity = max(1, Int((height - 14) / lineH))
        let overflowing = events.count > capacity
        let shownCount = (overflowing && showChips) ? max(capacity - 1, 1) : min(events.count, capacity)
        let shown = Array(events.prefix(shownCount))
        let overflow = events.count - shown.count

        VStack(alignment: .leading, spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: width >= 50 ? 10 : 8, weight: .semibold))
                .padding(.horizontal, 3)
                .background(isToday ? Color.red : Color.clear)
                .foregroundStyle(isToday ? Color.white : Color.primary)
                .clipShape(Capsule())
                .padding(.leading, 2)

            if showChips {
                ForEach(Array(shown.enumerated()), id: \.offset) { item in
                    chip(item.element)
                }
                if overflow > 0 {
                    Text("+\(overflow) more")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.blue)
                        .padding(.leading, 3)
                }
            } else {
                ForEach(Array(shown.enumerated()), id: \.offset) { item in
                    bar(item.element)
                }
            }
        }
        .padding(.top, 2)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(isHighlighted ? Color.accentColor : (isToday ? Color.red : Color.clear), lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture { onShowDay(date, events) }
    }
}
