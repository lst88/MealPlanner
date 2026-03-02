//
//  MealPlan.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import Foundation
struct MealPlan: Identifiable, Codable {
    let id: UUID
    let weekStartDate: Date
    let budget: Double
    let meals: [DailyMeals]
    let totalCost: Double
    
    init(id: UUID = UUID(), weekStartDate: Date, budget: Double, meals: [DailyMeals], totalCost: Double) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.budget = budget
        self.meals = meals
        self.totalCost = totalCost
    }
    
    var shoppingList: [Ingredient] {
        // Combine all ingredients from all meals
        var allIngredients: [Ingredient] = []
        for dailyMeal in meals {
            if let breakfast = dailyMeal.breakfast {
                allIngredients.append(contentsOf: breakfast.ingredients)
            }
            if let lunch = dailyMeal.lunch {
                allIngredients.append(contentsOf: lunch.ingredients)
            }
            if let dinner = dailyMeal.dinner {
                allIngredients.append(contentsOf: dinner.ingredients)
            }
        }
        
        // Group by ingredient name and sum quantities (simplified)
        var consolidatedIngredients: [String: Ingredient] = [:]
        for ingredient in allIngredients {
            if let existing = consolidatedIngredients[ingredient.name] {
                // Combine prices
                let combinedIngredient = Ingredient(
                    id: existing.id,
                    name: existing.name,
                    quantity: "\(existing.quantity), \(ingredient.quantity)",
                    estimatedPrice: existing.estimatedPrice + ingredient.estimatedPrice
                )
                consolidatedIngredients[ingredient.name] = combinedIngredient
            } else {
                consolidatedIngredients[ingredient.name] = ingredient
            }
        }
        
        return Array(consolidatedIngredients.values).sorted { $0.name < $1.name }
    }
}

struct DailyMeals: Identifiable, Codable {
    let id: UUID
    let dayOfWeek: String
    let date: Date
    let breakfast: Recipe?
    let lunch: Recipe?
    let dinner: Recipe?
    
    init(id: UUID = UUID(), dayOfWeek: String, date: Date, breakfast: Recipe?, lunch: Recipe?, dinner: Recipe?) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.date = date
        self.breakfast = breakfast
        self.lunch = lunch
        self.dinner = dinner
    }
    
    var dailyCost: Double {
        (breakfast?.estimatedCost ?? 0) + (lunch?.estimatedCost ?? 0) + (dinner?.estimatedCost ?? 0)
    }
}

