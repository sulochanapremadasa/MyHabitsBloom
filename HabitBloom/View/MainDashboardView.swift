//
//  MainDashboardView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-11.
//

import SwiftUI
import SwiftData
import WidgetKit

struct MainDashboardView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    @Query(sort:\Habit.createdAt, order: .forward) private var habits :[Habit]
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedDate : Date = Date()
    @State private var showingAddHabitSheet = false
    @State private var showingPaywallSheet = false
    @AppStorage("isProUser", store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)) var isProUser = false // Toggle via StoreKit
    
    private let maxFreeHabits = 8

    // Only habits scheduled on the selected day's weekday
    private var scheduledHabits: [Habit] {
        habits.filter { $0.isScheduled(on: selectedDate) }
    }

    var body: some View {
        NavigationStack{
            ZStack{
//                theme.background.ignoresSafeArea()
//                Color(uiColor: .systemGroupedBackground)
//                    .ignoresSafeArea()
                
                VStack (spacing: 16) {
                    
                    // 1. Weekly Date Strip Selector
                    WeekHeaderView(selectedDate: $selectedDate)
                        .padding(.top, 8)
                    
                    // 2. Progress Ring / Overall Stats Card
                    ProgressCardView(habits: scheduledHabits, selectedDate: selectedDate)
                        .padding(.horizontal)
                    
                    // 3. Habit List Section
                    if habits.isEmpty{
                        EmptyHabitView(showingAddHabitSheet: $showingAddHabitSheet)
                    }else if scheduledHabits.isEmpty{
                        VStack {
                            Spacer()
                            Text("No habits scheduled for this day")
                                .font(.subheadline)
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                        }
                    }else{
                        List{
                            ForEach(scheduledHabits){habit in
                                // Value-based NavigationLink for each Habit model
                                HabitsRowView(habit: habit, selectedDate: selectedDate) {
                                    toggleHabitCompletion(habit)
                                }
                                .overlay {
                                    NavigationLink(value: habit) {
                                        EmptyView()
                                    }
                                    .opacity(0) // Hides the arrow/disclosure indicator [6.8]
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                        .navigationDestination(for: Habit.self) { habit in
                            HabitDetailView(habit: habit)
                        }
                    }
                    
                }
                
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if !isProUser && habits.count >= maxFreeHabits {
                            showingPaywallSheet = true
                        } else {
                            showingAddHabitSheet = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .bold))
//                            .foregroundStyle(.themeAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                AddHabitModalView()
            }
            .sheet(isPresented: $showingPaywallSheet) {
                PaywallView()
            }
            .tint(.themeAccent)
            .preferredColorScheme(theme.colorScheme)
            .background(theme.background.ignoresSafeArea())
        }
    }
    // Toggle Habit Completion for the Selected Date
    private func toggleHabitCompletion(_ habit: Habit) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            let calendar = Calendar.current
            let targetDate = calendar.startOfDay(for: selectedDate)
            
            if let existingIndex = habit.logs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
                // If logged, remove log
                let logToDelete = habit.logs[existingIndex]
                habit.logs.remove(at: existingIndex)
                modelContext.delete(logToDelete)
            } else {
                // Add new completion log
                let newLog = HabitLog(date: targetDate, isCompleted: true)
                habit.logs.append(newLog)
            }
            try? modelContext.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct WeekHeaderView : View {
    @Binding var selectedDate : Date
    private let caledar = Calendar.current
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    var weekDates : [Date] {
        let today = caledar.startOfDay(for: Date())
        guard let weekInterval = caledar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        return (0..<7).compactMap { caledar.date(byAdding: .day, value: $0, to: weekInterval.start)}
    }
    
    var body: some View {
        
        HStack (spacing: 12) {
            ForEach (weekDates, id: \.self) { date in
                let isSelected = caledar.isDate(date, inSameDayAs: selectedDate)
                let isToday = caledar.isDateInToday(date)

                VStack(spacing: 6) {
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption)
                        .bold()
                        .foregroundColor(isSelected ? .white : theme.textSecondary)
                    
                    Text(date.formatted(.dateTime.day()))
                        .font(.callout)
                        .fontWeight(isSelected ? .bold : .regular)
                        .foregroundColor(isSelected ? .white : theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? theme.dateSelect : (isToday ? theme.dateSelect.opacity(0.25) : Color(theme.cardBackground)))
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)){
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
//        .tint(.themeAccent)
//        .preferredColorScheme(theme.colorScheme)
//        .background(theme.cardBackground)
    }
}

struct ProgressCardView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    let habits : [Habit]
    let selectedDate : Date
    
    var completedCount : Int {
        let calendar = Calendar.current
        return habits.filter { habit in
            habit.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) })
        }.count
    }
    
    var progressPercentage : Double {
        habits.isEmpty ? 0 : Double(completedCount) / Double(habits.count)
    }
   
    var body: some View {
        HStack (spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(completedCount == habits.count && !habits.isEmpty ? "All Done! 🎉" : "Daily Progress")
                    .font(.headline)
                    .foregroundStyle(theme.textPrimary)
                
                Text("\(completedCount) of \(habits.count) habits completed")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
            
            Spacer()
            
            // Circular Progress Indicator
            ZStack {
                Circle()
                    .stroke(theme.trackRing, lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(Color.themeAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progressPercentage)
                
                Text("\(Int(progressPercentage * 100))%")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(theme.textPrimary)
            }
            .frame(width: 50, height: 50)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.cardBackground))
    }
}

/// Placeholder state when no habits exist
struct EmptyHabitView: View {
    @Binding var showingAddHabitSheet: Bool
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.seal")
                .font(.system(size: 50))
                .foregroundStyle(theme.textPrimary)
            Text("No Habits Yet")
                .font(.title3)
                .bold()
                .foregroundStyle(theme.textPrimary)
            Text("Start building a healthier routine by adding your first daily habit.")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Add Habit") {
                showingAddHabitSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            Spacer()
        }
    }
}

struct HabitsRowView : View {
    
    let habit : Habit
    let selectedDate : Date
    let onToggle : () -> Void
    
    var isCompleted : Bool {
        let calendar = Calendar.current
        return habit.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: selectedDate)})
    }

    // Habits can't be completed ahead of time
    var isFutureDate : Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: selectedDate) > calendar.startOfDay(for: Date())
    }

    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    var body: some View {
        
        HStack (spacing: 16) {
            Image (systemName: habit.icon)
                .font(.title3)
//                .foregroundColor(Color(habit.colorHex))
                .foregroundColor(Color(hex: habit.colorHex) ?? .blue)
                .frame(width: 42, height: 42)
                .background(Color(hex: habit.colorHex)?.opacity(0.15) ?? Color.blue.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted, color: theme.textSecondary)
                    .foregroundStyle(isCompleted ? theme.textSecondary : theme.textPrimary)
                
            }
            Spacer()
            
            // Completion Checkbox Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onToggle()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? theme.accent : theme.textSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .disabled(isFutureDate)
            .opacity(isFutureDate ? 0.4 : 1)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.cardBackground))
    }
    
    
    // Quick streak logic computed locally
    private func calculateStreak() -> Int {
        return habit.logs.filter { $0.isCompleted }.count
    }
    
}
// MARK: - Color Hex Utility Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}
#Preview {
    MainDashboardView()
}
