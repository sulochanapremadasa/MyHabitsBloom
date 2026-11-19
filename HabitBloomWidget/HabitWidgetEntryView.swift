//
//  HabitWidgetEntryView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-17.
//

import SwiftUI
import WidgetKit
import AppIntents

struct HabitWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: HabitEntry
    
    @AppStorage("isProUser", store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)) var isProUser = false
    
    var body: some View {
        if isProUser {
            switch family {
                // 1. Lock Screen Circular (Progress Ring)
            case .accessoryCircular:
                CircularAccessoryView(entry: entry)
                
                // 2. Lock Screen Rectangular (Top 2 Habits)
            case .accessoryRectangular:
                RectangularAccessoryView(entry: entry)
                
                // 3. Lock Screen Inline Text Above Clock
            case .accessoryInline:
                InlineAccessoryView(entry: entry)
                
                // 4. StandBy / Home Screen Medium & Small Widgets
            case .systemSmall, .systemMedium,.systemLarge,.systemExtraLarge,.systemExtraLargePortrait:
                StandardWidgetView(entry: entry)
            @unknown default:
                StandardWidgetView(entry: entry)
            }
        }else{
            lockedWidgetView()
        }
        
    }
    
}

struct lockedWidgetView : View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(Color.themeAccent)
            
            Text("Pro Feature")
                .font(.caption)
                .bold()
            
            Text("Tap to upgrade & unlock Home Screen widgets.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "habitbloom://paywall")) // Deep link into your paywall
    }
}
// MARK: - Lock Screen Circular View
struct CircularAccessoryView: View {
    var entry: HabitEntry

    var completionRatio: Double {
        guard !entry.habits.isEmpty else { return 0 }
        let completed = entry.habits.filter { $0.isCompleted }.count
        return Double(completed) / Double(entry.habits.count)
    }

    var body: some View {
        Gauge(value: completionRatio) {
            Image(systemName: "checkmark.seal.fill")
        } currentValueLabel: {
            Text("\(Int(completionRatio * 100))%")
                .font(.system(size: 10, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

// MARK: - Lock Screen Rectangular View
struct RectangularAccessoryView: View {
    var entry: HabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Today's Habits")
                    .font(.caption2)
                    .bold()
                Spacer()
                Text("\(entry.habits.filter { $0.isCompleted }.count)/\(entry.habits.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ForEach(entry.habits.prefix(2)) { habit in
                HStack(spacing: 4) {
                    Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.caption2)
                    
                    Text(habit.name)
                        .font(.caption2)
                        .lineLimit(1)
                        .strikethrough(habit.isCompleted)
                }
            }
        }
    }
}

// MARK: - Lock Screen Inline Text View
struct InlineAccessoryView: View {
    var entry: HabitEntry

    var body: some View {
        let completed = entry.habits.filter { $0.isCompleted }.count
        Label("Habits: \(completed)/\(entry.habits.count) completed", systemImage: "checkmark.seal.fill")
    }
}

// MARK: - StandBy & Standard Home Screen View
struct StandardWidgetView: View {
    var entry: HabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Habits")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(Color.themeAccent)
            }

            if entry.habits.isEmpty {
                VStack {
                    Spacer()
                    Text("No habits scheduled")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.habits) { habit in
                        HStack(spacing: 8) {
                            Image(systemName: habit.icon)
                                .font(.caption2)
                                .foregroundStyle(Color(habit.colorHex))
                                .frame(width: 22, height: 22)
                                .background((Color(habit.colorHex)))
                                .clipShape(Circle())

                            Text(habit.name)
                                .font(.caption)
                                .bold()
                                .lineLimit(1)
                                .strikethrough(habit.isCompleted, color: .secondary)
                                .foregroundStyle(habit.isCompleted ? .secondary : .primary)

                            Spacer()

                            // Interactive Toggle via AppIntent
                            Button(intent: ToggleHabitIntent(habitID: habit.id)) {
                                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(habit.isCompleted ? Color.themeAccent : Color.secondary.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Widget Bundle Configuration
@main
struct HabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitInteractiveWidget()
    }
}

struct HabitInteractiveWidget: Widget {
    let kind: String = "HabitInteractiveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitTimelineProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Habit Checklist")
        .description("Check off habits directly from your Home Screen.")
        .supportedFamilies([
                    .systemSmall,
                    .systemMedium,
                    .accessoryCircular,
                    .accessoryRectangular,
                    .accessoryInline,
                    .systemLarge,
                    .systemExtraLarge
                ])
    }
}
