//
//  SearchView.swift
//  PanoCal
//
//  Created by Donald Edwards on 11/11/2026.
//

import SwiftUI
import EventKit

struct SearchView: View {
    let events: [EKEvent]
    let onPick: (EKEvent) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [EKEvent] {
        guard !trimmed.isEmpty else { return [] }
        return events
            .filter { ($0.title ?? "").localizedCaseInsensitiveContains(trimmed) }
            .sorted { $0.startDate < $1.startDate }
    }

    private func color(for event: EKEvent) -> Color {
        if let cg = event.calendar?.cgColor {
            return Color(cgColor: cg)
        }
        return .blue
    }

    private func dateText(for event: EKEvent) -> String {
        event.startDate.formatted(date: .abbreviated, time: event.isAllDay ? .omitted : .shortened)
    }

    private func row(_ event: EKEvent) -> some View {
        Button {
            onPick(event)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(color(for: event))
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.title ?? "Untitled")
                        .lineLimit(1)
                    Text(dateText(for: event))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        let found = results

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search event titles", text: $text)
                    .textFieldStyle(.plain)
                    .focused($focused)
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if trimmed.isEmpty {
                Text("Type to search the events in the current range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if found.isEmpty {
                Text("No matching events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(found.count > 100
                     ? "Showing the first 100 of \(found.count) matches"
                     : "\(found.count) match\(found.count == 1 ? "" : "es")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(found.prefix(100).enumerated()), id: \.offset) { item in
                            row(item.element)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(width: 340, height: 420)
        .onAppear { focused = true }
    }
}
