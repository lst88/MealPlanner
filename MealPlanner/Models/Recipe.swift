//
//  Recipe.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import Foundation
struct Recipe: Identifiable, Codable {
    let id: UUID
    let name: String
    let ingredients: [Ingredient]
    let instructions: [String]
    let servings: Int
    let estimatedCost: Double
    
    init(id: UUID = UUID(), name: String, ingredients: [Ingredient], instructions: [String], servings: Int, estimatedCost: Double) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.servings = servings
        self.estimatedCost = estimatedCost
    }
}

struct Ingredient: Identifiable, Codable {
    let id: UUID
    let name: String
    let quantity: String
    let estimatedPrice: Double
    
    init(id: UUID = UUID(), name: String, quantity: String, estimatedPrice: Double) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.estimatedPrice = estimatedPrice
    }
}

