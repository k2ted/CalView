//
//  ContentView.swift
//  PanoCal
//
//  Created by Donald Edwards on 09/11/2026.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @State private var calendar = CalendarStore()
    @AppStorage("selectedMonths") private var months = 3
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("viewMode") private var viewMode = "calendar"
    @State private var showSidebar = false
    @State private var selected: EventItem?
    @State private var selectedDay: DayItem?

    var body: some View {
        HStack(spacing: 0) {
            if showSidebar {
                SidebarView(calendar: calendar, months: $months)
                    .frame(width: 280)
                    .transition(.move(edge: .leading))
                Divider()
            }
            mainContent
        }
        .animation(.easeInOut(duration: 0.2), value: showSidebar)
        .preferredColorScheme(preferredScheme)
        .task(id: months) { await calendar.load(months: months) }
        .task { await calendar.startObservingChanges() }
        .sheet(item: $selected) { item in
            EventDetailView(event: item.event)
                .preferredColorScheme(preferredScheme)
        }
        .sheet(item: $selectedDay) { item in
            DayListView(day: item.day, events: item.events)
                .preferredColorScheme(preferredScheme)
        }
    }

    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var monthStarts: [Date] {
        let cal = Calendar.current
        guard let first = cal.dateInterval(of: .month, for: Date())?.start else { return [] }
        return (0..<months).compactMap { cal.date(byAdding: .month, value: $0, to: first) }
    }

    private var mainContent: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                HStack {
                    Button {
                        showSidebar.toggle()
                    } label: {
                        Label("Sidebar", systemImage: "sidebar.left")
                            .labelStyle(.iconOnly)
                    }
                    .help("Show or hide the sidebar")
                    .keyboardShortcut("s", modifiers: [.command, .control])

                    Spacer()

                    if viewMode == "calendar" {
                        Menu("Jump to") {
                            ForEach(monthStarts, id: \.self) { month in
                                Button(month.formatted(.dateTime.month(.wide).year())) {
                                    scrollToMonth(month, proxy)
                                }
                            }
                        }
                        .fixedSize()

                        Button("Today") {
                            jumpToToday(proxy)
                        }
                        .keyboardShortcut("t", modifiers: .command)
                    }
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .padding()

                if calendar.accessDenied {
                    Text("Calendar access was denied. You can allow it in System Settings > Privacy & Security > Calendars.")
                        .padding()
                } else if viewMode == "planner" {
                    PlannerView(
                        calendar: calendar,
                        months: months,
                        onSelect: { selected = EventItem(event: $0) },
                        onShowDay: { day, events in selectedDay = DayItem(day: day, events: events) }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(calendar.weekStarts.enumerated()), id: \.element) { index, weekStart in
                                VStack(spacing: 4) {
                                    if let label = monthLabel(for: weekStart, index: index) {
                                        Text(label)
                                            .font(.headline)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.top, 8)
                                    }
                                    WeekRow(
                                        weekStart: weekStart,
                                        events: calendar.visibleEvents,
                                        onSelect: { selected = EventItem(event: $0) },
                                        onShowDay: { day, events in selectedDay = DayItem(day: day, events: events) }
                                    )
                                }
                                .id(weekStart)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }

    private func scrollToMonth(_ monthStart: Date, _ proxy: ScrollViewProxy) {
        let cal = Calendar.current
        if let week = calendar.weekStarts.first(where: {
            cal.isDate(monthStart, equalTo: $0, toGranularity: .weekOfYear)
        }) {
            withAnimation {
                proxy.scrollTo(week, anchor: .top)
            }
        }
    }

    private func jumpToToday(_ proxy: ScrollViewProxy) {
        guard let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start else { return }
        scrollToMonth(monthStart, proxy)
    }

    private func monthLabel(for weekStart: Date, index: Int) -> String? {
        let cal = Calendar.current
        for offset in 0..<7 {
            let day = cal.date(byAdding: .day, value: offset, to: weekStart)!
            if cal.component(.day, from: day) == 1 {
                return day.formatted(.dateTime.month(.wide).year())
            }
        }
        if index == 0 {
            return weekStart.formatted(.dateTime.month(.wide).year())
        }
        return nil
    }
}
