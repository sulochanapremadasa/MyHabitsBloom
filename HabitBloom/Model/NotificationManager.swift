//
//  NotificationManager.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-09-02.
//

import Foundation
import UserNotifications
import SwiftData

struct NotificationManager {
    
    /// Requests notification permissions from the user.
    static func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }
    
    /// Re-evaluates and updates notification triggers for all active habits.
    static func syncAllNotifications(habits: [Habit]) {
        let center = UNUserNotificationCenter.current()
        let defaults = UserDefaults.standard
        
        let notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        let silentHoursEnabled = defaults.bool(forKey: "silentHoursEnabled")
        
        // If master notifications are off, clear all scheduled alerts
        guard notificationsEnabled else {
            center.removeAllPendingNotificationRequests()
            return
        }
        
        for habit in habits {
            // Cancel existing notifications for this habit first
            center.removePendingNotificationRequests(withIdentifiers: notificationIdentifiers(for: habit))
            
            // Skip if habit has no reminder set
            guard let reminderTime = habit.reminderTime else { continue }
            
            // Skip if reminder falls inside Silent Hours
            if silentHoursEnabled && isTimeInSilentHours(time: reminderTime) {
                continue
            }
            
            // Schedule valid notification
            scheduleNotification(for: habit, reminderTime: reminderTime)
        }
    }
    
    /// Evaluates if a given Date's time component falls within the configured Silent Hours span.
    private static func isTimeInSilentHours(time: Date) -> Bool {
        let defaults = UserDefaults.standard
        
        // Read start/end hours and minutes directly from UserDefaults (with defaults)
        let startHour = defaults.object(forKey: "silentStartHour") as? Int ?? 22
        let startMinute = defaults.object(forKey: "silentStartMinute") as? Int ?? 0
        let endHour = defaults.object(forKey: "silentEndHour") as? Int ?? 5
        let endMinute = defaults.object(forKey: "silentEndMinute") as? Int ?? 0
        
        // Convert components to total minutes from midnight for direct comparison
        let calendar = Calendar.current
        let timeMinutes = calendar.component(.hour, from: time) * 60 + calendar.component(.minute, from: time)
        
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        // Handle overnight spans (e.g., 22:00 to 05:00) vs same-day spans (e.g., 01:00 to 05:00)
        if startMinutes > endMinutes {
            return timeMinutes >= startMinutes || timeMinutes < endMinutes
        } else {
            return timeMinutes >= startMinutes && timeMinutes < endMinutes
        }
    }
    
    /// All notification identifiers a habit may own: one per weekday, plus the legacy
    /// daily identifier used before per-day scheduling so old requests get cleaned up.
    static func notificationIdentifiers(for habit: Habit) -> [String] {
        [habit.id.uuidString] + (1...7).map { weekdayIdentifier(for: habit, weekday: $0) }
    }

    private static func weekdayIdentifier(for habit: Habit, weekday: Int) -> String {
        "\(habit.id.uuidString)-\(weekday)"
    }

    /// Schedules a weekly repeating local notification for each of the habit's target weekdays.
    private static func scheduleNotification(for habit: Habit, reminderTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for \(habit.name)!"
        content.body = "Keep your streak going today. Tap to check it off."
        content.sound = .default

        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        for weekday in Set(habit.targetWeekdays) {
            var dateComponents = timeComponents
            dateComponents.weekday = weekday
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(
                identifier: weekdayIdentifier(for: habit, weekday: weekday),
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }
}
