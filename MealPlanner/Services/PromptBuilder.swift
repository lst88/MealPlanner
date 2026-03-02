//
//  PromptBuilder.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import Foundation

struct PromptBuilder {
    
    static func buildSystemInstructions(
        includeIngredients: Bool,
        dietaryPreference: DietaryPreference
    ) -> String {
        let dietaryRestriction = buildDietaryRestriction(dietaryPreference)
        
        if includeIngredients {
            return """
            You are a helpful meal planning assistant.
            
            Requirements for all meal plans:
            - Simple, affordable recipes
            - Provide ingredient lists with quantities and estimated UK prices in £
            - Stay within the budget
            - Focus on common, easy-to-find ingredients
            \(dietaryRestriction)
            
            IMPORTANT: Respond with raw JSON only. Do NOT wrap your response in markdown code blocks (```json or ```). Do NOT include any text before or after the JSON.
            
            Response format - Always respond ONLY with valid JSON in this exact format (no additional text):
            {
              "weekStartDate": "2026-02-10T00:00:00Z",
              "budget": <budget>,
              "meals": [
                {
                  "dayOfWeek": "Monday",
                  "date": "2026-02-10T00:00:00Z",
                  "breakfast": {
                    "name": "Recipe Name",
                    "ingredients": [
                      {"name": "Ingredient", "quantity": "amount", "estimatedPrice": 0.00}
                    ],
                    "servings": 2,
                    "estimatedCost": 0.00
                  },
                  "lunch": {
                    "name": "Recipe Name",
                    "ingredients": [
                      {"name": "Ingredient", "quantity": "amount", "estimatedPrice": 0.00}
                    ],
                    "servings": 2,
                    "estimatedCost": 0.00
                  },
                  "dinner": {
                    "name": "Recipe Name",
                    "ingredients": [
                      {"name": "Ingredient", "quantity": "amount", "estimatedPrice": 0.00}
                    ],
                    "servings": 2,
                    "estimatedCost": 0.00
                  }
                }
              ],
              "totalCost": 0.00
            }
            """
        } else {
            return """
            You are a helpful meal planning assistant.
            
            Requirements for all meal plans:
            - Simple, affordable recipes
            - Stay within the budget
            - Focus on common, easy-to-find meals
            - Provide meal names only (no ingredient details needed)
            \(dietaryRestriction)
            
            IMPORTANT: Respond with raw JSON only. Do NOT wrap your response in markdown code blocks (```json or ```). Do NOT include any text before or after the JSON.
            
            Response format - Always respond ONLY with valid JSON in this exact format (no additional text):
            {
              "weekStartDate": "2026-02-10T00:00:00Z",
              "budget": <budget>,
              "meals": [
                {
                  "dayOfWeek": "Monday",
                  "date": "2026-02-10T00:00:00Z",
                  "breakfast": {
                    "name": "Recipe Name",
                    "servings": 2,
                    "estimatedCost": 0.00
                  },
                  "lunch": {
                    "name": "Recipe Name",
                    "servings": 2,
                    "estimatedCost": 0.00
                  },
                  "dinner": {
                    "name": "Recipe Name",
                    "servings": 2,
                    "estimatedCost": 0.00
                  }
                }
              ],
              "totalCost": 0.00
            }
            """
        }
    }
    
    static func buildUserPrompt(
        budget: Double,
        numberOfDays: Int,
        selectedDates: [DateComponents]
    ) -> String {
        let dayDescription = numberOfDays == 1 ? "a single day" : "\(numberOfDays) days"
        let timeFrame = numberOfDays == 1 ? "for the day" : "for each day"
        
        var dateSpecificInfo = ""
        if !selectedDates.isEmpty {
            let calendar = Calendar.current
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
            
            let sortedDates = selectedDates.compactMap { calendar.date(from: $0) }.sorted()
            if !sortedDates.isEmpty {
                let datesList = sortedDates.map { dateFormatter.string(from: $0) }.joined(separator: ", ")
                dateSpecificInfo = "\nGenerate meals for these specific dates: \(datesList)"
            }
        }
        
        return """
        Generate a meal plan for \(dayDescription) with a total budget of £\(String(format: "%.2f", budget)).
        Include breakfast, lunch, and dinner \(timeFrame).\(dateSpecificInfo)
        Generate exactly \(numberOfDays) day(s) of meals.
        """
    }
    
    private static func buildDietaryRestriction(_ preference: DietaryPreference) -> String {
        switch preference {
        case .none:
            return ""
        case .vegetarian:
            return "- ALL meals must be vegetarian (no meat, poultry, fish, or seafood)"
        case .vegan:
            return "- ALL meals must be vegan (no animal products including meat, dairy, eggs, honey)"
        case .pescatarian:
            return "- ALL meals must be pescatarian (fish and seafood allowed, but no meat or poultry)"
        case .glutenFree:
            return "- ALL meals must be gluten-free (no wheat, barley, rye, or gluten-containing grains)"
        }
    }
    
    static func calculateMaxTokens(numberOfDays: Int, includeIngredients: Bool) -> Int {
        let tokensPerDay: Int
        if includeIngredients {
            tokensPerDay = 650 // With ingredients: ~600 tokens per day
        } else {
            tokensPerDay = 250 // Without ingredients: ~200 tokens per day
        }
        
        let baseTokens = 300 // Buffer for JSON structure
        let calculatedTokens = baseTokens + (tokensPerDay * numberOfDays)
        
        // Add 20% safety margin to prevent truncation
        return Int(Double(calculatedTokens) * 1.2)
    }
}
