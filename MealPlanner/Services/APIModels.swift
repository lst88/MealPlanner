//
//  APIModels.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import Foundation

// MARK: - Dietary Preferences

enum DietaryPreference: String, CaseIterable, Codable {
    case none = "No Restrictions"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case glutenFree = "Gluten-Free"
}

// MARK: - API Error

enum APIError: LocalizedError {
    case notConfigured
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case jsonParseError(originalError: Error)
    case responseTruncated(daysRequested: Int, includeIngredients: Bool, suggestion: String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "API key not configured. Please add your Claude API key in APIConfig.swift"
        case .invalidResponse:
            return "Invalid response from API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .jsonParseError(let originalError):
            return "Failed to parse response: \(originalError.localizedDescription)"
        case .responseTruncated(let days, let includeIngredients, let suggestion):
            let ingredientInfo = includeIngredients ? " with ingredients" : ""
            return "Response was cut off while generating \(days) day(s)\(ingredientInfo). \(suggestion)."
        }
    }
}

// MARK: - Claude Request Models

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeRequestWithCache: Codable {
    let model: String
    let maxTokens: Int
    let system: [CachedSystemMessage]
    let messages: [ClaudeMessage]
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

struct CachedSystemMessage: Codable {
    let type: String
    let text: String
    let cacheControl: CacheControl
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case cacheControl = "cache_control"
    }
}

struct CacheControl: Codable {
    let type: String
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Claude Response Models

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    let usage: ClaudeUsage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case usage
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationInputTokens: Int?
    let cacheReadInputTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
    }
    
    var totalTokens: Int {
        inputTokens + outputTokens + (cacheCreationInputTokens ?? 0)
    }
    
    var cacheSavings: String {
        if let cacheRead = cacheReadInputTokens, cacheRead > 0 {
            return "💰 Cache hit! Read \(cacheRead) tokens from cache (90% cost reduction)"
        } else if let cacheCreation = cacheCreationInputTokens, cacheCreation > 0 {
            return "💾 Cached \(cacheCreation) tokens for future requests"
        }
        return "No cache used"
    }
}

struct ClaudeErrorResponse: Codable {
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let message: String
}

// MARK: - Meal Plan Response Models

struct MealPlanResponse: Codable {
    let weekStartDate: String
    let budget: Double
    let meals: [DailyMealsResponse]
    let totalCost: Double
    
    func toMealPlan() -> MealPlan {
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.date(from: weekStartDate) ?? Date()
        
        let dailyMeals = meals.map { $0.toDailyMeals() }
        
        return MealPlan(
            weekStartDate: startDate,
            budget: budget,
            meals: dailyMeals,
            totalCost: totalCost
        )
    }
}

struct DailyMealsResponse: Codable {
    let dayOfWeek: String
    let date: String
    let breakfast: RecipeResponse?
    let lunch: RecipeResponse?
    let dinner: RecipeResponse?
    
    func toDailyMeals() -> DailyMeals {
        let dateFormatter = ISO8601DateFormatter()
        let mealDate = dateFormatter.date(from: date) ?? Date()
        
        return DailyMeals(
            dayOfWeek: dayOfWeek,
            date: mealDate,
            breakfast: breakfast?.toRecipe(),
            lunch: lunch?.toRecipe(),
            dinner: dinner?.toRecipe()
        )
    }
}

struct RecipeResponse: Codable {
    let name: String
    let ingredients: [IngredientResponse]?
    let servings: Int
    let estimatedCost: Double
    
    func toRecipe() -> Recipe {
        Recipe(
            name: name,
            ingredients: ingredients?.map { $0.toIngredient() } ?? [],
            instructions: [], // No instructions requested from API
            servings: servings,
            estimatedCost: estimatedCost
        )
    }
}

struct IngredientResponse: Codable {
    let name: String
    let quantity: String
    let estimatedPrice: Double
    
    func toIngredient() -> Ingredient {
        Ingredient(
            name: name,
            quantity: quantity,
            estimatedPrice: estimatedPrice
        )
    }
}
