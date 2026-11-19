//
//  HabitDetailView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-14.
//

import SwiftUI
import SwiftData
import UserNotifications

struct HabitDetailView: View {
    
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Heatmap Month Navigation State
    @State private var displayedMonth: Date = Date()
    @State private var showingDeleteAlert = false
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    var body: some View {
        ScrollView{
            VStack(spacing: 20) {
                
                // 1. Stat Summary Cards
                HStack (spacing: 12) {
                    StatBox(
                        title: "Current Streak",
                        value: "\(calculateCurrentStreak()) Days",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    StatBox(
                        title: "Best Streak",
                        value: "\(calculateBestStreak()) Days",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                    
                    StatBox(
                        title: "Total Completed",
                        value: "\(habit.logs.filter { $0.isCompleted }.count)",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // 2. Monthly Calendar Heatmap Card
                VStack(spacing: 4) {
                    
                    // Month Switcher Header
                    HStack {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title3)
                                .foregroundStyle(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                            .bold()
                            .foregroundStyle(theme.textPrimary)
                        
                        Spacer()
                        
                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title3)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Weekday Headers (Sun - Sat)
                    HStack {
                        ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                            Text(day.prefix(1))
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(theme.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Heatmap Grid
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<daysForHeatmapGrid().count, id: \.self) { index in
                            if let date = daysForHeatmapGrid()[index] {
                                let isCompleted = isDateCompleted(date)
                                let isToday = calendar.isDateInToday(date)
                                let isFutureDate = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(
                                            isCompleted
                                            ? (Color(hex: habit.colorHex) ?? .purple)
                                            : theme.trackRing
                                        )
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(isToday ? theme.accent : Color.clear, lineWidth: 2)
                                        )
                                        .opacity(isFutureDate ? 0.35 : 1.0)
                                    
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.caption2)
                                        .fontWeight(isCompleted ? .bold : .regular)
                                        .foregroundColor(isCompleted ? .white : theme.textPrimary)
                                        .opacity(isFutureDate ? 0.35 : 1.0)
                                }
                                .onTapGesture {
                                    toggleCompletion(for: date)
                                }
                                .disabled(isFutureDate)
                            } else {
                                // Blank padding tile for days before start of month
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(theme.cardBackground))
                )
                .padding(.horizontal)
                
                // 3. Completion Rate Progress Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Monthly Consistency")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Text("\(Int(monthlyCompletionPercentage() * 100))%")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(Color(hex: habit.colorHex) ?? .purple)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.trackRing)
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(Color(hex: habit.colorHex) ?? .blue)
                                .frame(width: geo.size.width * monthlyCompletionPercentage(), height: 10)
                                .animation(.spring, value: monthlyCompletionPercentage())
                        }
                    }
                    .frame(height: 10)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(theme.cardBackground))
                )
                .padding(.horizontal)
                
                
                // 4. Delete Habit Button
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("Delete Habit", systemImage: "trash.fill")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(theme.destructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.destructive.opacity(0.12))
                        )
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.vertical)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Habit?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(habit.name)'? This action cannot be undone.")
        }
        .tint(.themeAccent)
        .preferredColorScheme(theme.colorScheme)
        .scrollContentBackground(.hidden)
        
    }
    // MARK: - Calendar Heatmap Matrix Logic
    
    /// Generates grid tiles including leading `nil` values for empty calendar slots
    private func daysForHeatmapGrid() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1 = Sun, 2 = Mon ...
        let leadingPadding = firstWeekday - 1
        
        var grid: [Date?] = Array(repeating: nil, count: leadingPadding)
        
        var currentDate = firstDay
        while currentDate < monthInterval.end {
            grid.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return grid
    }
    
    private func changeMonth(by amount: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: amount, to: displayedMonth) {
            withAnimation {
                displayedMonth = newMonth
            }
        }
    }
    
    private func isDateCompleted(_ date: Date) -> Bool {
        habit.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: date) && $0.isCompleted })
    }
    
    private func toggleCompletion(for date: Date) {
        let targetDate = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        // Prevent selecting future dates
        guard targetDate <= today else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            
            if let index = habit.logs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
                habit.logs.remove(at: index)
//                modelContext.delete(habit.logs[index])
            } else {
                let newLog = HabitLog(date: targetDate, isCompleted: true)
                habit.logs.append(newLog)
            }
            try? modelContext.save()
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let completedDates = Set(
            habit.logs
                .filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.date) }
        )
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // Allow today to not break current streak if not completed yet
        if !completedDates.contains(checkDate),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) {
            checkDate = yesterday
        }
        
        while completedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return streak
    }
    
    private func calculateBestStreak() -> Int {
        let sortedDates = habit.logs
            .filter { $0.isCompleted }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
        
        guard !sortedDates.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let previous = sortedDates[i-1]
            let current = sortedDates[i]
            
            if let expected = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(expected, inSameDayAs: current) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if !calendar.isDate(previous, inSameDayAs: current) {
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
    
    private func monthlyCompletionPercentage() -> Double {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return 0.0 }
        let totalDaysInMonth = range.count
        
        let completedInMonth = daysForHeatmapGrid().compactMap { $0 }.filter { isDateCompleted($0) }.count
        return Double(completedInMonth) / Double(totalDaysInMonth)
    }
    
    private func deleteHabit() {
        
        cancelNotification(for: habit)
        
        modelContext.delete(habit)
        dismiss()
    }
    
    private func cancelNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        let notificationID = habit.id.uuidString
        
        // Remove pending scheduled notifications
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        
        // Optional: Remove any notification that was already delivered and sitting in Notification Center
        center.removeDeliveredNotifications(withIdentifiers: [notificationID])
    }
}

// MARK: - Supporting Metric Subview

struct StatBox: View{
    let title: String
    let value: String
    let icon: String
    let color: Color
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    var body: some View{
        VStack (spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .bold()
                .foregroundStyle(theme.textPrimary)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(theme.cardBackground))
        )
    }
    
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)
    
    let sampleHabit = Habit(name: "Drink Water", icon: "drop.fill", colorHex: "#3498db")
    
    return HabitDetailView(habit: sampleHabit)
        .modelContainer(container)
}
