//
//  CalendarFilterView.swift
//  CalView
//
//  Created by Donald Edwards on 09/11/2026.
//

import SwiftUI
import EventKit

struct CalendarFilterView: View {
    let calendar: CalendarStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Show All") { calendar.showAll() }
                Button("Hide All") { calendar.hideAll() }
                Spacer()
            }
            .padding(10)

            Divider()

            List(calendar.calendars, id: \.calendarIdentifier) { cal in
                Toggle(isOn: Binding(
                    get: { calendar.isVisible(cal) },
                    set: { _ in calendar.toggle(cal) }
                )) {
                    HStack {
                        Circle()
                            .fill(Color(cgColor: cal.cgColor))
                            .frame(width: 10, height: 10)
                        Text(cal.title)
                    }
                }
            }
        }
        .frame(minWidth: 280, minHeight: 320)
    }
}
