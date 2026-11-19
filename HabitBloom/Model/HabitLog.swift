//
//  HabitLog.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-11.
//

import Foundation
import SwiftData

@Model
final class HabitLog {
    var id : UUID
    var date : Date
    var isCompleted : Bool
    
    init(date: Date = Date(), isCompleted: Bool = true) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
    }
}
