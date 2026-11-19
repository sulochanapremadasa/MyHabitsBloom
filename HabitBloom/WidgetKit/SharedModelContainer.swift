//
//  SharedModelContainer.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-17.
//

import SwiftUI
import SwiftData

enum SharedModelContainer {
    
    static let appGroupIdentifier = "group.com.sulo.HabitBloom"

    static func create() throws -> ModelContainer {
        let schema = Schema([Habit.self, HabitLog.self])
        
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )?.appendingPathComponent("HabitTracker.sqlite") else {
            fatalError("Could not retrieve App Group Container URL")
        }

        let config = ModelConfiguration(schema: schema, url: containerURL)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
