//
//  SidebarView.swift
//  Panorama Cal
//
//  Created by Donald Edwards on 10/11/2026.
//

import SwiftUI
import EventKit

struct SidebarView: View {
    let calendar: CalendarStore
    @Binding var months: Int
    @AppStorage("showEventTimes") private var showTimes = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Range (months)")
                    .font(.headline)
                Picker("Range", selection: $months) {
                    Text("3").tag(3)
                    Text("6").tag(6)
                    Text("12").tag(12)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Display")
                    .font(.headline)
                Toggle("Show event times", isOn: $showTimes)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Calendars")
                    .font(.headline)

                HStack(spacing: 16) {
                    Button("Show All") { calendar.showAll() }
                    Button("Hide All") { calendar.hideAll() }
                }
                .buttonStyle(.borderless)
                .font(.callout)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(calendar.calendars, id: \.calendarIdentifier) { cal in
                            Toggle(isOn: Binding(
                                get: { calendar.isVisible(cal) },
                                set: { _ in calendar.toggle(cal) }
                            )) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(cgColor: cal.cgColor))
                                        .frame(width: 10, height: 10)
                                    Text(cal.title)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.gray.opacity(0.08))
    }
}
