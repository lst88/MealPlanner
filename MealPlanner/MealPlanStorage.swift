//
//  MealPlanStorage.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import Foundation

@MainActor
class MealPlanStorage: ObservableObject {
    @Published var savedPlans: [MealPlan] = []
    
    private let storageKey = "savedMealPlans"
    
    init() {
        loadPlans()
    }
    
    func savePlan(_ plan: MealPlan) {
        // Check if plan already exists, update if so
        if let index = savedPlans.firstIndex(where: { $0.id == plan.id }) {
            savedPlans[index] = plan
        } else {
            savedPlans.insert(plan, at: 0) // Add to beginning
        }
        
        // Keep only last 20 plans
        if savedPlans.count > 20 {
            savedPlans = Array(savedPlans.prefix(20))
        }
        
        persistPlans()
    }
    
    func deletePlan(_ plan: MealPlan) {
        savedPlans.removeAll { $0.id == plan.id }
        persistPlans()
    }
    
    func deletePlan(at offsets: IndexSet) {
        savedPlans.remove(atOffsets: offsets)
        persistPlans()
    }
    
    private func persistPlans() {
        do {
            let data = try JSONEncoder().encode(savedPlans)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save meal plans: \(error)")
        }
    }
    
    private func loadPlans() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            savedPlans = try decoder.decode([MealPlan].self, from: data)
        } catch {
            print("Failed to load meal plans: \(error)")
            savedPlans = []
        }
    }
}
