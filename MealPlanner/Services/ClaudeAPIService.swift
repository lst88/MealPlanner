//
//  ClaudeAPIService.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import Foundation
import Combine

@MainActor
class ClaudeAPIService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func generateMealPlan(
        budget: Double,
        numberOfDays: Int = 7,
        selectedDates: [DateComponents] = [],
        includeIngredients: Bool = false,
        dietaryPreference: DietaryPreference = .none,
        mealPreferences: String? = nil
    ) async throws -> MealPlan {
        guard APIConfig.isConfigured else {
            throw APIError.notConfigured
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Build prompts
        let systemInstructions = PromptBuilder.buildSystemInstructions(
            includeIngredients: includeIngredients,
            dietaryPreference: dietaryPreference
        )
        
        let userPrompt = PromptBuilder.buildUserPrompt(
            budget: budget,
            numberOfDays: numberOfDays,
            selectedDates: selectedDates
        )
        
        let maxTokens = PromptBuilder.calculateMaxTokens(
            numberOfDays: numberOfDays,
            includeIngredients: includeIngredients
        )
        
        print("📊 Token Allocation:")
        print("   Days: \(numberOfDays), Ingredients: \(includeIngredients)")
        print("   Max tokens: \(maxTokens)")
        
        // Build request
        let requestBody = ClaudeRequestWithCache(
            model: APIConfig.model,
            maxTokens: maxTokens,
            system: [CachedSystemMessage(
                type: "text",
                text: systemInstructions,
                cacheControl: CacheControl(type: "ephemeral")
            )],
            messages: [ClaudeMessage(role: "user", content: userPrompt)]
        )
        
        // Make API call
        let claudeResponse = try await makeAPIRequest(requestBody: requestBody)
        
        // Log usage
        print("📊 Token Usage:")
        print("   Input tokens: \(claudeResponse.usage.inputTokens)")
        print("   Output tokens: \(claudeResponse.usage.outputTokens)")
        print("   \(claudeResponse.usage.cacheSavings)")
        
        if claudeResponse.stopReason == "max_tokens" {
            print("⚠️ Warning: Response was truncated due to token limit")
        }
        
        // Parse response
        return try parseResponse(
            claudeResponse: claudeResponse,
            budget: budget,
            numberOfDays: numberOfDays,
            includeIngredients: includeIngredients
        )
    }
    
    // MARK: - Private Methods
    
    private func makeAPIRequest(requestBody: ClaudeRequestWithCache) async throws -> ClaudeResponse {
        var request = URLRequest(url: URL(string: APIConfig.baseURL)!)
        request.httpMethod = "POST"
        request.setValue(APIConfig.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(APIConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw APIError.apiError(errorResponse.error.message)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // Debug: Print the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 API Response:")
            print(jsonString)
        }
        
        return try JSONDecoder().decode(ClaudeResponse.self, from: data)
    }
    
    private func parseResponse(
        claudeResponse: ClaudeResponse,
        budget: Double,
        numberOfDays: Int,
        includeIngredients: Bool
    ) throws -> MealPlan {
        guard let textContent = claudeResponse.content.first?.text else {
            throw APIError.invalidResponse
        }
        
        let cleanedContent = ResponseParser.cleanMarkdownCodeBlocks(from: textContent)
        
        guard let mealPlanData = cleanedContent.data(using: .utf8) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Try to parse complete response
            let mealPlanResponse = try decoder.decode(MealPlanResponse.self, from: mealPlanData)
            return mealPlanResponse.toMealPlan()
        } catch {
            // If parsing fails, try to recover partial JSON
            print("⚠️ Failed to parse complete JSON, attempting to recover partial data...")
            
            if let recoveredPlan = try? ResponseParser.recoverPartialMealPlan(
                from: cleanedContent,
                budget: budget,
                numberOfDays: numberOfDays
            ) {
                print("✅ Successfully recovered partial meal plan with \(recoveredPlan.meals.count) day(s)")
                return recoveredPlan
            }
            
            // If recovery also fails, provide helpful error
            if claudeResponse.stopReason == "max_tokens" {
                throw APIError.responseTruncated(
                    daysRequested: numberOfDays,
                    includeIngredients: includeIngredients,
                    suggestion: "Try reducing the number of days or disabling ingredients"
                )
            }
            
            throw APIError.jsonParseError(originalError: error)
        }
    }
}

