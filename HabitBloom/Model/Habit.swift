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
    
    @Relationship( deleteRule: .cascade)
    var logs : [HabitLog] = []
    
    init( name: String, icon: String = "star.fill", colorHex: String = "#FF5733", targetDaysPerWeek: Int = 7, reminderTime: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.targetDaysPerWeek = targetDaysPerWeek
        self.reminderTime =  reminderTime
    }
}
