//
//  HabitWidgetModel.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-17.
//

import WidgetKit
import SwiftData

struct HabitWidgetModel: Identifiable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    let isCompleted: Bool
}

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [HabitWidgetModel]
}

struct HabitTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habits: [
            HabitWidgetModel(id: "1", name: "Drink Water", icon: "drop.fill", colorHex: "#3B82F6", isCompleted: true),
            HabitWidgetModel(id: "2", name: "Read 20 mins", icon: "book.fill", colorHex: "#8B5CF6", isCompleted: false)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(fetchCurrentHabits())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = fetchCurrentHabits()
        
        // Refresh automatically every 15 minutes or when AppIntent reloads
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }

    private func fetchCurrentHabits() -> HabitEntry {
        do {
            let container = try SharedModelContainer.create()
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
            
            let allHabits = try context.fetch(descriptor)
            let today = Calendar.current.startOfDay(for: Date())

            // Limit to top 4 habits for small/medium widget fit
            let widgetHabits = allHabits.prefix(4).map { habit in
                let isDone = habit.logs.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: today) && $0.isCompleted })
                return HabitWidgetModel(
                    id: habit.id.uuidString,
                    name: habit.name,
                    icon: habit.icon,
                    colorHex: habit.colorHex,
                    isCompleted: isDone
                )
            }
            
            return HabitEntry(date: Date(), habits: Array(widgetHabits))
        } catch {
            return HabitEntry(date: Date(), habits: [])
        }
    }
}
