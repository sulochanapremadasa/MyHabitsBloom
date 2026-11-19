//
//  ToggleHabitIntent.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-17.
//

import AppIntents
import SwiftData
import WidgetKit

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit Completion"
    static var description = IntentDescription("Toggles a habit's completed status for today directly from the Widget.")

    @Parameter(title: "Habit ID")
    var habitID: String

    init() {}

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitID) else { return .result() }

        // Access shared database container
        let container = try SharedModelContainer.create()
        let context = ModelContext(container)
        
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == uuid })
        
        if let habit = try context.fetch(descriptor).first {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            if let index = habit.logs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                // If logged today, delete log
                context.delete(habit.logs[index])
            } else {
                // Otherwise mark as completed
                habit.logs.append(HabitLog(date: today, isCompleted: true))
            }
            
            try context.save()
        }

        // Trigger a timeline reload for all active widgets
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
