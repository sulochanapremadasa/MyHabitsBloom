//
//  AddHabitModalView.swift
//  HabitBloom
//
//  Created by Sulochana Premadasa on 2026-08-13.
//

import SwiftUI
import SwiftData

struct AddHabitModalView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    private var theme: AppTheme { AppTheme(isDark: isDarkMode) }
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Query all habits to sync notifications globally on save
    @Query private var habits: [Habit]
    
    // Form State
    @State private var habitName: String = ""
    @State private var targetDaysPerWeek: Int = 7
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedColorHex: String = "#14B8A6"
    
    // Local Notification State
    @State private var enableReminder: Bool = false
    @State private var reminderTime: Date = {
        var component = DateComponents()
        component.hour = 9
        component.minute = 0
        return Calendar.current.date(from: component) ?? Date()
    }()
    @State private var showPermissionAlert: Bool = false
    
    // Available Icons (SF Symbols)
    private let availableIcons = [
        "star.fill", "flame.fill", "drop.fill", "figure.walk", "figure.run",
        "book.fill", "pencil.and.scribble", "brain.head.profile", "moon.stars.fill",
        "heart.fill", "leaf.fill", "cup.and.saucer.fill",
        "dumbbell.fill", "cross.case.fill", "checkmark.seal.fill",
        "bed.double.fill", "pills.fill", "fork.knife"
    ]
    
    // Predefined Color Palette
    private let availableColors = [
        "#14B8A6", // Teal
        "#3B82F6", // Blue
        "#10B981", // Green
        "#EF4444", // Red
        "#F59E0B", // Orange
        "#8B5CF6", // Purple
        "#EC4899", // Pink
        "#6366F1"  // Indigo
    ]
    
    var isFormValid: Bool {
        !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Habit Details")) {
                    TextField("Habit Name (e.g. Read 20 mins)", text: $habitName)
                        .autocorrectionDisabled()
                        .foregroundStyle(theme.textPrimary)
                    Stepper("Target: \(targetDaysPerWeek) days / week", value: $targetDaysPerWeek, in: 1...7)
                        .foregroundStyle(theme.textPrimary)
                }
                .listRowBackground(theme.cardBackground)
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(selectedIcon == icon ? .white : Color(hex: selectedColorHex))
                                .frame(width: 40, height: 40)
                                .background(
                                    selectedIcon == icon
                                    ? Color(hex: selectedColorHex)
                                    : Color(hex: selectedColorHex)?.opacity(0.12)
                                )
                                .clipShape(Circle())
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2)) {
                                        selectedIcon = icon
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(theme.cardBackground)
                
                Section(header: Text("Color Theme")) {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(theme.textPrimary, lineWidth: selectedColorHex == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2)) {
                                        selectedColorHex = hex
                                    }
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                }
                .listRowBackground(theme.cardBackground)
                
                Section(header: Text("Reminders"), footer: Text("Notifications are scheduled directly on your device without using external servers.")) {
                    Toggle("Enable Daily Reminder", isOn: $enableReminder)
                        .onChange(of: enableReminder) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                    
                    if enableReminder {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                .listRowBackground(theme.cardBackground)
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .bold()
                    .disabled(!isFormValid)
                }
            }
            .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    enableReminder = false
                }
            } message: {
                Text("Please allow notifications in System Settings to receive daily habit reminders.")
            }
            .background(theme.background.ignoresSafeArea())
            .tint(.themeAccent)
            .preferredColorScheme(theme.colorScheme)
            .scrollContentBackground(.hidden)
            
        }
    }
    
    // MARK: - Save Logic
    
    private func saveHabit() {
        let trimmedName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let habitReminder = enableReminder ? reminderTime : nil
        
        // 1. Create SwiftData Model with reminderTime
        let newHabit = Habit(
            name: trimmedName,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            targetDaysPerWeek: targetDaysPerWeek,
            reminderTime: habitReminder
        )
        
        // 2. Insert into Local Database
        modelContext.insert(newHabit)
        try? modelContext.save()
        
        // 3. Sync all notifications considering settings state and silent hours
        var allHabits = habits
        allHabits.append(newHabit)
        NotificationManager.syncAllNotifications(habits: allHabits)
        
        dismiss()
    }
    
    // MARK: - Notification Utilities
    
    private func requestNotificationPermission() {
        NotificationManager.requestAuthorization { granted in
            DispatchQueue.main.async {
                if granted {
                    notificationsEnabled = true
                } else {
                    enableReminder = false
                    showPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    AddHabitModalView()
}
