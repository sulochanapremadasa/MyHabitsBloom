//
//  HabitDataCSV.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-24.
//

import SwiftUI
import UniformTypeIdentifiers

struct HabitDataCSV: Transferable {
    let csvContent: String
    
    // Cache formatters for performance
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    init(habits: [Habit]) {
        var csv = "Habit Name,Target Days/Week,Logged Date,Logged Time,Completed\n"

        for habit in habits {
            // Proper CSV escaping: wrap in quotes & escape internal double quotes
            let escapedName = "\"\(habit.name.replacingOccurrences(of: "\"", with: "\"\""))\""
            let target = habit.targetDaysPerWeek
            
            if habit.logs.isEmpty {
                csv += "\(escapedName),\(target),N/A,N/A,N/A\n"
            } else {
                for log in habit.logs {
                    let dateStr = Self.dateFormatter.string(from: log.date)
                    let timeStr = Self.timeFormatter.string(from: log.date)
                    let completedStr = log.isCompleted ? "Yes" : "No"
                    csv += "\(escapedName),\(target),\(dateStr),\(timeStr),\(completedStr)\n"
                }
            }
        }
        self.csvContent = csv
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { document in
            Data(document.csvContent.utf8)
        }
        .suggestedFileName("HabitLogs_\(Date().formatted(.dateTime.year().month().day())).csv")
    }
}
