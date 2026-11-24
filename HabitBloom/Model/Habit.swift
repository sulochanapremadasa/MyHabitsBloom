//
//  Habit.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-11.
//

import Foundation
import SwiftData

@Model
final class Habit{
    @Attribute(.unique) var id : UUID
    var name: String
    var icon: String // SF Symbol name
    var colorHex: String
    var createdAt: Date
    var targetDaysPerWeek: Int
    var reminderTime: Date?
    // Scheduled weekdays using Calendar numbering (1 = Sunday ... 7 = Saturday).
    // Default keeps existing habits scheduled every day after migration.
    var targetWeekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]

    @Relationship( deleteRule: .cascade)
    var logs : [HabitLog] = []

    init( name: String, icon: String = "star.fill", colorHex: String = "#FF5733", targetWeekdays: [Int] = [1, 2, 3, 4, 5, 6, 7], reminderTime: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.targetWeekdays = targetWeekdays
        self.targetDaysPerWeek = targetWeekdays.count
        self.reminderTime =  reminderTime
    }

    /// Whether the habit is scheduled on the weekday of the given date
    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        targetWeekdays.contains(calendar.component(.weekday, from: date))
    }
}
