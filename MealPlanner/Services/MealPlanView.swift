//
//  MealPlanView.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import SwiftUI

struct MealPlanView: View {
    let mealPlan: MealPlan
    @State private var selectedTab = 0
    @EnvironmentObject private var storage: MealPlanStorage
    @State private var isSaved = false
    @State private var showingSavedConfirmation = false
    @State private var showingShareSheet = false
    @State private var shareText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Budget Overview
            BudgetOverviewCard(budget: mealPlan.budget, totalCost: mealPlan.totalCost)
                .padding()
            
            // Tab Selection
            Picker("View", selection: $selectedTab) {
                Text("Meal Plan").tag(0)
                Text("Shopping List").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Content
            TabView(selection: $selectedTab) {
                // Meal Plan Tab
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(mealPlan.meals) { dailyMeal in
                            DailyMealCard(dailyMeal: dailyMeal)
                        }
                    }
                    .padding()
                }
                .tag(0)
                
                // Shopping List Tab
                ShoppingListView(ingredients: mealPlan.shoppingList, totalCost: mealPlan.totalCost)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Your Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button(action: shareplan) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: savePlan) {
                        Label("Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityViewController(activityItems: [shareText])
        }
        .onAppear {
            // Check if this plan is already saved
            isSaved = storage.savedPlans.contains { $0.id == mealPlan.id }
        }
        .alert("Plan Saved", isPresented: $showingSavedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your meal plan has been saved successfully.")
        }
    }
    
    private func savePlan() {
        storage.savePlan(mealPlan)
        isSaved = true
        showingSavedConfirmation = true
    }
    
    private func shareplan() {
        shareText = generateShareText()
        showingShareSheet = true
    }
    
    private func generateShareText() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var text = "🍽️ My Meal Plan\n\n"
        text += "Budget: £\(String(format: "%.2f", mealPlan.budget))\n"
        text += "Total Cost: £\(String(format: "%.2f", mealPlan.totalCost))\n"
        text += "Days: \(mealPlan.meals.count)\n\n"
        
        for daily in mealPlan.meals {
            text += "📅 \(daily.dayOfWeek) - \(formatter.string(from: daily.date))\n"
            text += "   Cost: £\(String(format: "%.2f", daily.dailyCost))\n\n"
            
            if let breakfast = daily.breakfast {
                text += "   🌅 Breakfast: \(breakfast.name)\n"
                text += "      £\(String(format: "%.2f", breakfast.estimatedCost))\n"
            }
            
            if let lunch = daily.lunch {
                text += "   ☀️ Lunch: \(lunch.name)\n"
                text += "      £\(String(format: "%.2f", lunch.estimatedCost))\n"
            }
            
            if let dinner = daily.dinner {
                text += "   🌙 Dinner: \(dinner.name)\n"
                text += "      £\(String(format: "%.2f", dinner.estimatedCost))\n"
            }
            
            text += "\n"
        }
        
        // Add shopping list if ingredients are included
        let ingredients = mealPlan.shoppingList
        if !ingredients.isEmpty {
            text += "🛒 Shopping List\n\n"
            for ingredient in ingredients {
                text += "• \(ingredient.name) - \(ingredient.quantity) (£\(String(format: "%.2f", ingredient.estimatedPrice)))\n"
            }
        }
        
        return text
    }
}

struct BudgetOverviewCard: View {
    let budget: Double
    let totalCost: Double
    
    var remainingBudget: Double {
        budget - totalCost
    }
    
    var percentageUsed: Double {
        min(totalCost / budget, 1.0)
    }
    
    var statusColor: Color {
        if percentageUsed <= 0.9 { return .green }
        if percentageUsed <= 1.0 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("£\(String(format: "%.2f", budget))")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("£\(String(format: "%.2f", totalCost))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(statusColor)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * percentageUsed)
                }
            }
            .frame(height: 8)
            
            HStack {
                Image(systemName: remainingBudget >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(statusColor)
                Text(remainingBudget >= 0 ? "£\(String(format: "%.2f", remainingBudget)) remaining" : "Over budget by £\(String(format: "%.2f", abs(remainingBudget)))")
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct DailyMealCard: View {
    let dailyMeal: DailyMeals
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(dailyMeal.dayOfWeek)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(dailyMeal.date, format: .dateTime.day().month())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("£\(String(format: "%.2f", dailyMeal.dailyCost))")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text("per day")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Meals
            if let breakfast = dailyMeal.breakfast {
                MealRow(mealType: "Breakfast", recipe: breakfast)
            }
            
            if let lunch = dailyMeal.lunch {
                MealRow(mealType: "Lunch", recipe: lunch)
            }
            
            if let dinner = dailyMeal.dinner {
                MealRow(mealType: "Dinner", recipe: dinner)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct MealRow: View {
    let mealType: String
    let recipe: Recipe
    @State private var showingDetail = false
    
    var icon: String {
        switch mealType {
        case "Breakfast": return "sunrise.fill"
        case "Lunch": return "sun.max.fill"
        case "Dinner": return "moon.stars.fill"
        default: return "fork.knife"
        }
    }
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mealType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(recipe.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text("£\(String(format: "%.2f", recipe.estimatedCost))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .sheet(isPresented: $showingDetail) {
            RecipeDetailView(recipe: recipe, mealType: mealType)
        }
    }
}

struct ShoppingListView: View {
    let ingredients: [Ingredient]
    let totalCost: Double
    
    var body: some View {
        ScrollView {
            if ingredients.isEmpty {
                // Show message when no ingredients
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("No Ingredients Included")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Enable 'Include Ingredients' when generating a meal plan to see the shopping list.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else {
                VStack(spacing: 15) {
                    // Header
                    HStack {
                        Text("Shopping List")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(ingredients.count) items")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Ingredients
                    VStack(spacing: 0) {
                        ForEach(ingredients) { ingredient in
                            ShoppingListRow(ingredient: ingredient)
                            
                            if ingredient.id != ingredients.last?.id {
                                Divider()
                                    .padding(.leading, 50)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Total
                    HStack {
                        Text("Estimated Total")
                            .font(.headline)
                        Spacer()
                        Text("£\(String(format: "%.2f", totalCost))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
    }
}

struct ShoppingListRow: View {
    let ingredient: Ingredient
    @State private var isChecked = false
    
    var body: some View {
        HStack {
            Button(action: { isChecked.toggle() }) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isChecked ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.body)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                
                Text(ingredient.quantity)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("£\(String(format: "%.2f", ingredient.estimatedPrice))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    let mealType: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recipe Info
                    HStack {
                        Label("\(recipe.servings) servings", systemImage: "person.2.fill")
                        Spacer()
                        Label("£\(String(format: "%.2f", recipe.estimatedCost))", systemImage: "tag.fill")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // Ingredients
                    if !recipe.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ingredients")
                                .font(.headline)
                            
                            ForEach(recipe.ingredients) { ingredient in
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(ingredient.name)
                                    Text("—")
                                        .foregroundStyle(.secondary)
                                    Text(ingredient.quantity)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("£\(String(format: "%.2f", ingredient.estimatedPrice))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                        
                        Divider()
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ingredients")
                                .font(.headline)
                            
                            Text("Ingredient list not included")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                        
                        Divider()
                    }
                    
                    // Instructions
                    if !recipe.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Instructions")
                                .font(.headline)
                            
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1).")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                    
                                    Text(instruction)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MealPlanView(mealPlan: MealPlan(
            weekStartDate: Date(),
            budget: 50,
            meals: [
                DailyMeals(
                    dayOfWeek: "Monday",
                    date: Date(),
                    breakfast: Recipe(
                        name: "Scrambled Eggs on Toast",
                        ingredients: [
                            Ingredient(name: "Eggs", quantity: "2", estimatedPrice: 0.40),
                            Ingredient(name: "Bread", quantity: "2 slices", estimatedPrice: 0.20)
                        ],
                        instructions: ["Beat eggs", "Cook in pan", "Serve on toast"],
                        servings: 1,
                        estimatedCost: 0.60
                    ),
                    lunch: nil,
                    dinner: nil
                )
            ],
            totalCost: 45.50
        ))
        .environmentObject(MealPlanStorage())
    }
}
// MARK: - Activity View Controller for Sharing

#if os(iOS)
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}
#endif

