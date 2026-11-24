//
//  AnalyticsView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-20.
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    
    // 1. Fetch all non-archived habits from SwiftData
    @Query private var habits: [Habit]
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    @AppStorage("isProUser", store: UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)) var isProUser = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Cards
                    HStack(spacing: 12) {
                        MetricCard(title: "30-Day Rate", value: String(format: "%.0f%%", overall30DayRate), icon: "chart.line.uptrend.xyaxis", color: .green)
                        MetricCard(title: "Current Streak", value: "\(currentStreak) Days", icon: "flame.fill", color: .orange)
                    }
                    .padding(.horizontal)
                    
                    // 2. Habit Performance Section
                    if isProUser{
                        HabitPerformanceCard(habits: habits)
                            .padding(.horizontal)
                        
                        // 3. Habit Matrix Section
                        HabitMatrixCard(habits: habits)
                            .padding(.horizontal)
                    }else{
                        ProUpgradeCard()
                    }
                    
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .tint(.themeAccent)
            .preferredColorScheme(theme.colorScheme)
            .background(theme.background.ignoresSafeArea())
        }
    }
    
    // MARK: - Overall Analytics Logic
    
    private var overall30DayRate: Double {
        guard !habits.isEmpty else { return 0.0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today) else { return 0.0 }
        
        var totalLogged = 0
        var totalTarget = 0.0
        
        for habit in habits {
            let logs = habit.logs.filter { calendar.startOfDay(for: $0.date) >= thirtyDaysAgo }.count
            let target = (Double(habit.targetDaysPerWeek) / 7.0) * 30.0
            totalLogged += logs
            totalTarget += target
        }
        
        guard totalTarget > 0 else { return 0.0 }
        return min((Double(totalLogged) / totalTarget) * 100.0, 100.0)
    }
    
    private var currentStreak: Int {
        guard !habits.isEmpty else { return 0 }
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        var streak = 0
        
        let completedDates = Set(habits.flatMap { $0.logs }.map { calendar.startOfDay(for: $0.date) })
        
        if !completedDates.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate),
                  completedDates.contains(yesterday) else { return 0 }
            checkDate = yesterday
        }
        
        while completedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        return streak
    }
}

struct ProUpgradeCard: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    
    @State private var showProSheet = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.themeAccent)
                .padding(.top, 8)
            
            VStack(spacing: 6) {
                Text("Unlock Advanced Analytics")
                    .font(.headline)
                    .foregroundStyle(theme.textPrimary)
                
                Text("Get detailed 30-day performance breakdowns and a 14-day habit matrix with Pro.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textSecondary)
            }
            
            Button {
                showProSheet = true
            } label: {
                Text("Upgrade to Pro")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.themeAccent, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(theme.cardBackground)))
        .sheet(isPresented: $showProSheet) {
            PaywallView()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(theme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12,style: .continuous))
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(theme.cardBackground)))
    }
}

// MARK: - Subcomponent: Habit Performance Card

struct HabitPerformanceCard : View {
    let habits :[Habit]
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    var body: some View{
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Habit Performance")
                    .font(.title3.bold())
                    .foregroundStyle(theme.textPrimary)
                Text("30–day completion rate")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }
            
            VStack (spacing: 14) {
                ForEach(habits) { habit in
                    let rate = calculate30DayRate(for: habit)
                    let habitColor = Color(hex: habit.colorHex) ?? .blue
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: habit.icon)
                                .foregroundStyle(habitColor)
                            Text(habit.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                                .foregroundStyle(theme.textPrimary)
                        }
                        .frame(width: 120, alignment: .leading)
                        
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(theme.trackRing)
                                
                                Capsule()
                                    .fill(habitColor)
                                    .frame(width: proxy.size.width * CGFloat(rate / 100.0))
                            }
                        }
                        .frame(height: 10)
                        
                        Text("\(Int(rate))%")
                            .font(.subheadline.bold())
                            .foregroundStyle(habitColor)
                            .frame(width: 42, alignment: .trailing)
                    }
                }
            }
        }
        .padding(20)
//        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(theme.cardBackground)))
    }
    
    private func calculate30DayRate(for habit: Habit) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today) else { return 0 }
        
        let logsIn30Days = habit.logs.filter { calendar.startOfDay(for: $0.date) >= thirtyDaysAgo }.count
        let targetFor30Days = (Double(habit.targetDaysPerWeek) / 7.0) * 30.0
        
        guard targetFor30Days > 0 else { return 0 }
        return min((Double(logsIn30Days) / targetFor30Days) * 100.0, 100.0)
    }
}

// MARK: - Subcomponent: Habit Matrix Card (14 Days)
struct HabitMatrixCard: View {
    let habits: [Habit]
    
    @State private var selectedDate: Date = Date()
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    private var matrixDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        return (0..<14).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }
    
    // Subtitle date range string (e.g. "Aug 7 – Aug 20, 2026")
    private var dateRangeSubtitle: String {
        guard let first = matrixDays.first, let last = matrixDays.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Habit Matrix")
                        .font(.title3.bold())
                        .foregroundStyle(theme.textPrimary)
                    Text(dateRangeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
                
                Spacer()
                
                // Date Selector Controls
                VStack {
                    HStack(spacing: 8) {
                        // Shift back 14 days
                        
                        Button {
                            shiftDate(by: -14)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.caption.bold())
                                .padding(8)
                                .background(theme.trackRing, in: Circle())
                        }
                        
                        // Compact Date Picker (Prevents selecting future dates)
                        DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        
                        // Shift forward 14 days
                        Button {
                            shiftDate(by: 14)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .padding(8)
                                .background(theme.trackRing, in: Circle())
                        }
                        .disabled(Calendar.current.isDateInToday(selectedDate))
                    }
                    
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = Date()
                            }
                        } label: {
                            Text("Today")
                                .font(.caption.bold())
                                .foregroundStyle(theme.dateSelect)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(theme.trackRing, in: Capsule())
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Header Row (Letters and Numbers)
                HStack(spacing: 0) {
                    Spacer().frame(width: 110)
                    
                    HStack(spacing: 0) {
                        ForEach(matrixDays, id: \.self) { date in
                            VStack(spacing: 2) {
                                Text(shortWeekday(for: date))
                                    .font(.caption2)
                                    .foregroundStyle(theme.textSecondary)
                                Text(dayNumber(for: date))
                                    .font(.caption2.bold())
                                    .foregroundStyle(theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                // Habit Rows
                ForEach(habits) { habit in
                    let habitColor = Color(hex: habit.colorHex) ?? .blue
                    
                    HStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: habit.icon)
                                .foregroundStyle(habitColor)
                            Text(habit.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                                .foregroundStyle(theme.textPrimary)
                        }
                        .frame(width: 110, alignment: .leading)
                        
                        HStack(spacing: 0) {
                            ForEach(matrixDays, id: \.self) { date in
                                let isDone = isCompleted(habit: habit, on: date)

                                Group {
                                    if isDone {
                                        Circle().fill(habitColor)
                                    } else if habit.isScheduled(on: date) {
                                        Circle().fill(theme.trackRing)
                                    } else {
                                        // Unscheduled day: hollow outline marks it as disabled
                                        Circle().strokeBorder(theme.disabledOutline, lineWidth: 1.5)
                                    }
                                }
                                .frame(width: 16, height: 16)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.cardBackground))
        // Triggers lightweight haptic feedback on every selectedDate mutation
        .sensoryFeedback(.selection, trigger: selectedDate)
        .tint(.themeAccent)
        .preferredColorScheme(theme.colorScheme)
        
    }
    
    private func isCompleted(habit: Habit, on date: Date) -> Bool {
        let calendar = Calendar.current
        return habit.logs.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func shortWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
    
    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func shiftDate(by days: Int) {
            if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
                // Cap at today's date
                selectedDate = min(newDate, Date())
            }
        }
}

#Preview {
    AnalyticsView()
}
