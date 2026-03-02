//
//  ResponseParser.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import Foundation

struct ResponseParser {
    
    /// Removes markdown code blocks from Claude's response
    static func cleanMarkdownCodeBlocks(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var wasMarkdown = false
        
        // Remove opening markdown code block (```json or ```)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
            wasMarkdown = true
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
            wasMarkdown = true
        }
        
        // Remove closing markdown code block (```)
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
            wasMarkdown = true
        }
        
        // Trim again after removing markers
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if wasMarkdown {
            print("🧹 Cleaned markdown code blocks from response")
        }
        
        return cleaned
    }
    
    /// Attempts to recover a partial meal plan from truncated JSON
    static func recoverPartialMealPlan(
        from jsonString: String,
        budget: Double,
        numberOfDays: Int
    ) throws -> MealPlan {
        var workingJson = jsonString
        
        // Try to close the JSON properly by adding missing closing brackets
        // First, find how many meals we can salvage
        let mealPattern = #"\"dayOfWeek\"\s*:\s*\"[^\"]+\""#
        let regex = try NSRegularExpression(pattern: mealPattern)
        let matches = regex.matches(in: workingJson, range: NSRange(workingJson.startIndex..., in: workingJson))
        let recoveredMealCount = matches.count
        
        if recoveredMealCount == 0 {
            throw APIError.invalidResponse
        }
        
        print("   Found \(recoveredMealCount) potentially complete meal(s)")
        
        // Try to find the last complete meal object
        if let lastMealEnd = findLastCompleteMealEnd(in: workingJson) {
            // Truncate after the last complete meal
            let truncatedIndex = workingJson.index(workingJson.startIndex, offsetBy: lastMealEnd)
            workingJson = String(workingJson[..<truncatedIndex])
            
            // Close the JSON structure properly
            workingJson += "\n  ],\n  \"totalCost\": 0.00\n}"
            
            // Try to parse again
            if let data = workingJson.data(using: .utf8) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let mealPlanResponse = try decoder.decode(MealPlanResponse.self, from: data)
                var mealPlan = mealPlanResponse.toMealPlan()
                
                // Recalculate total cost from recovered meals
                let actualTotal = mealPlan.meals.reduce(0.0) { $0 + $1.dailyCost }
                mealPlan = MealPlan(
                    id: mealPlan.id,
                    weekStartDate: mealPlan.weekStartDate,
                    budget: budget,
                    meals: mealPlan.meals,
                    totalCost: actualTotal
                )
                
                return mealPlan
            }
        }
        
        throw APIError.invalidResponse
    }
    
    /// Finds the position after the last complete meal object in JSON
    private static func findLastCompleteMealEnd(in json: String) -> Int? {
        var braceCount = 0
        var inMealsArray = false
        var lastValidPosition: Int?
        var inString = false
        var escapeNext = false
        
        for (index, char) in json.enumerated() {
            if escapeNext {
                escapeNext = false
                continue
            }
            
            if char == "\\" {
                escapeNext = true
                continue
            }
            
            if char == "\"" {
                inString.toggle()
                continue
            }
            
            if inString {
                continue
            }
            
            // Look for "meals" array
            if !inMealsArray {
                let substring = String(json[json.index(json.startIndex, offsetBy: max(0, index - 10))..<json.index(json.startIndex, offsetBy: min(json.count, index + 1))])
                if substring.contains("\"meals\"") {
                    inMealsArray = true
                }
            }
            
            if inMealsArray {
                if char == "{" {
                    braceCount += 1
                } else if char == "}" {
                    braceCount -= 1
                    
                    // If we're back at the meals array level after closing a meal object
                    if braceCount == 1 {
                        // Look ahead for a comma (more meals) or closing bracket (end of array)
                        let nextNonWhitespace = json[json.index(json.startIndex, offsetBy: index + 1)...]
                            .first(where: { !$0.isWhitespace })
                        
                        if nextNonWhitespace == "," || nextNonWhitespace == "]" {
                            lastValidPosition = index + 1
                        }
                    }
                }
            }
        }
        
        return lastValidPosition
    }
}
