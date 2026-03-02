//
//  ContentView.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import SwiftUI

// MARK: - Day Selection Model

struct DaySelection: Identifiable {
    let id = UUID()
    let dayName: String
    let shortName: String
    let dayIndex: Int // 0 = Monday, 6 = Sunday
    let weekOffset: Int // 0 = current week, 1 = next week
    var isSelected: Bool
    var isPast: Bool
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var apiService = ClaudeAPIService()
    @StateObject private var storage = MealPlanStorage()
    @State private var currentPage = 0
    @State private var budget: String = "50"
    @State private var budgetType: BudgetType = .total
    @State private var dietaryPreference: DietaryPreference = .none
    @State private var includeIngredients: Bool = false
    @State private var mealPlan: MealPlan?
    @State private var showingMealPlan = false
    @State private var showingPartialWarning = false
    @State private var partialWarningMessage = ""
    @State private var currentWeekDays: [DaySelection] = []
    @State private var nextWeekDays: [DaySelection] = []
    
    enum BudgetType: String, CaseIterable {
        case daily = "Per Day"
        case total = "Total"
    }
    
    private var allSelectedDays: [DaySelection] {
        (currentWeekDays + nextWeekDays).filter { $0.isSelected }
    }
    
    private var selectedDaysCount: Int {
        allSelectedDays.count
    }
    
    private var totalBudget: Double {
        guard let budgetValue = Double(budget) else { return 0 }
        return budgetType == .daily ? budgetValue * Double(selectedDaysCount) : budgetValue
    }
    
    private var dailyBudget: Double {
        guard selectedDaysCount > 0 else { return 0 }
        return totalBudget / Double(selectedDaysCount)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    // Page 1: Week Selection
                    WeekSelectionPage(
                        currentWeekDays: $currentWeekDays,
                        nextWeekDays: $nextWeekDays,
                        selectedCount: selectedDaysCount
                    )
                    .tag(0)
                    
                    // Page 2: Settings
                    SettingsPage(
                        budget: $budget,
                        budgetType: $budgetType,
                        dietaryPreference: $dietaryPreference,
                        includeIngredients: $includeIngredients,
                        selectedDaysCount: selectedDaysCount,
                        totalBudget: totalBudget,
                        dailyBudget: dailyBudget
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom navigation
                VStack(spacing: 15) {
                    // Page indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(currentPage == 0 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(currentPage == 1 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    // Action button
                    if currentPage == 0 {
                        Button(action: {
                            withAnimation {
                                currentPage = 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedDaysCount > 0 ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                        }
                        .disabled(selectedDaysCount == 0)
                        .padding(.horizontal, 30)
                    } else {
                        Button(action: generateMealPlan) {
                            HStack {
                                if apiService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate Meal Plan")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidInput ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                        }
                        .disabled(!isValidInput || apiService.isLoading)
                        .padding(.horizontal, 30)
                    }
                    
                    // Error Message
                    if let error = apiService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingMealPlan) {
                if let mealPlan = mealPlan {
                    MealPlanView(mealPlan: mealPlan)
                        .environmentObject(storage)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SavedPlansView().environmentObject(storage)) {
                        Label("Saved Plans", systemImage: "bookmark.fill")
                    }
                }
                
                if currentPage == 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            withAnimation {
                                currentPage = 0
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    }
                }
            }
            .alert("Partial Meal Plan", isPresented: $showingPartialWarning) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(partialWarningMessage)
            }
            .onAppear {
                if currentWeekDays.isEmpty {
                    setupWeeks()
                }
            }
        }
    }
    
    private func setupWeeks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get current day of week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let todayWeekday = calendar.component(.weekday, from: today)
        
        // Convert to Monday-based index (0 = Monday, 6 = Sunday)
        let todayIndex = (todayWeekday == 1) ? 6 : todayWeekday - 2
        
        let dayNames = [
            ("Monday", "Mon"),
            ("Tuesday", "Tue"),
            ("Wednesday", "Wed"),
            ("Thursday", "Thu"),
            ("Friday", "Fri"),
            ("Saturday", "Sat"),
            ("Sunday", "Sun")
        ]
        
        // Current week
        currentWeekDays = dayNames.enumerated().map { index, names in
            let isPast = index < todayIndex
            return DaySelection(
                dayName: names.0,
                shortName: names.1,
                dayIndex: index,
                weekOffset: 0,
                isSelected: false,
                isPast: isPast
            )
        }
        
        // Next week (all enabled)
        nextWeekDays = dayNames.enumerated().map { index, names in
            return DaySelection(
                dayName: names.0,
                shortName: names.1,
                dayIndex: index,
                weekOffset: 1,
                isSelected: false,
                isPast: false
            )
        }
    }
    
    private var isValidInput: Bool {
        guard selectedDaysCount > 0 else { return false }
        guard let budgetValue = Double(budget), budgetValue > 0, budgetValue <= 10000 else { return false }
        return true
    }
    
    private func generateMealPlan() {
        guard let budgetValue = Double(budget) else { return }
        
        Task {
            do {
                let plan = try await apiService.generateMealPlan(
                    budget: budgetType == .total ? budgetValue : budgetValue * Double(selectedDaysCount),
                    numberOfDays: selectedDaysCount,
                    selectedDates: [],
                    includeIngredients: includeIngredients,
                    dietaryPreference: dietaryPreference,
                    mealPreferences: nil
                )
                
                // Check if we got fewer days than requested (partial response)
                if plan.meals.count < selectedDaysCount {
                    partialWarningMessage = "Only \(plan.meals.count) of \(selectedDaysCount) days were generated due to response size. The meal plan is still usable but incomplete."
                    showingPartialWarning = true
                }
                
                mealPlan = plan
                showingMealPlan = true
            } catch {
                apiService.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Week Selection Page

struct WeekSelectionPage: View {
    @Binding var currentWeekDays: [DaySelection]
    @Binding var nextWeekDays: [DaySelection]
    let selectedCount: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Select Days")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Choose which days you need meals for")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Current Week
                VStack(alignment: .leading, spacing: 15) {
                    Text("This Week")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 8) {
                        ForEach($currentWeekDays) { $day in
                            DayButton(day: $day)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Next Week
                VStack(alignment: .leading, spacing: 15) {
                    Text("Next Week")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 8) {
                        ForEach($nextWeekDays) { $day in
                            DayButton(day: $day)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Selection summary
                if selectedCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("\(selectedCount) \(selectedCount == 1 ? "day" : "days") selected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 10)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                        Text("Tap to select days")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                    .padding(.top, 10)
                }
                
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Settings Page

struct SettingsPage: View {
    @Binding var budget: String
    @Binding var budgetType: ContentView.BudgetType
    @Binding var dietaryPreference: DietaryPreference
    @Binding var includeIngredients: Bool
    let selectedDaysCount: Int
    let totalBudget: Double
    let dailyBudget: Double
    
    private var dietaryPreferenceIcon: String {
        switch dietaryPreference {
        case .none: return "fork.knife"
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.circle.fill"
        case .pescatarian: return "fish.fill"
        case .glutenFree: return "allergens"
        }
    }
    
    private var dietaryPreferenceDescription: String {
        switch dietaryPreference {
        case .none: return "All foods included"
        case .vegetarian: return "No meat, poultry, fish, or seafood"
        case .vegan: return "No animal products"
        case .pescatarian: return "No meat or poultry"
        case .glutenFree: return "No gluten-containing grains"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Configure Plan")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Set your budget and preferences")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Budget Input
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 15) {
                        Text("Budget")
                            .font(.headline)
                        
                        // Budget input
                        HStack(spacing: 4) {
                            Text("£")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            
                            TextField("Amount", text: $budget)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                                .frame(width: 80)
                        }
                        
                        // Budget type dropdown
                        Picker("Budget Type", selection: $budgetType) {
                            ForEach(ContentView.BudgetType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .fixedSize()
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    
                    // Show alternate budget calculation
                    if selectedDaysCount > 0, let _ = Double(budget) {
                        Text(budgetType == .total ?
                             "£\(String(format: "%.2f", dailyBudget)) per day" :
                             "£\(String(format: "%.2f", totalBudget)) total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 30)
                    }
                }
                .frame(minHeight: 60)
                
                // Dietary Preference Picker
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Dietary Preferences")
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker("Diet", selection: $dietaryPreference) {
                            ForEach(DietaryPreference.allCases, id: \.self) { preference in
                                Text(preference.rawValue).tag(preference)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal, 30)
                    
                    if dietaryPreference != .none {
                        HStack(spacing: 6) {
                            Image(systemName: dietaryPreferenceIcon)
                                .font(.caption)
                            Text(dietaryPreferenceDescription)
                                .font(.caption)
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 30)
                    }
                }
                
                // Include Ingredients Toggle
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $includeIngredients) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Include Ingredients")
                                .font(.headline)
                            Text("Detailed shopping list with prices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    if !includeIngredients {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                            Text("Meal names only — faster and cheaper")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 30)
                    }
                }
                
                // Info Footer
                VStack(spacing: 5) {
                    if !APIConfig.isConfigured {
                        Label("API key not configured", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    Text("Powered by Claude AI")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Day Button View

struct DayButton: View {
    @Binding var day: DaySelection
    
    var body: some View {
        Button(action: {
            if !day.isPast {
                day.isSelected.toggle()
            }
        }) {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .cornerRadius(8)
            .opacity(day.isPast ? 0.4 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(day.isPast)
    }
    
    private var backgroundColor: Color {
        if day.isPast {
            return Color(.systemGray5)
        }
        return day.isSelected ? Color.blue : Color(.systemGray6)
    }
    
    private var foregroundColor: Color {
        if day.isPast {
            return .secondary
        }
        return day.isSelected ? .white : .primary
    }
}

#Preview {
    ContentView()
}

