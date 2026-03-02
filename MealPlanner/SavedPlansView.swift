//
//  SavedPlansView.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import SwiftUI

struct SavedPlansView: View {
    @EnvironmentObject var storage: MealPlanStorage
    @State private var selectedPlan: MealPlan?
    @State private var showingPlan = false
    
    var body: some View {
        Group {
            if storage.savedPlans.isEmpty {
                emptyStateView
            } else {
                plansList
            }
        }
        .navigationTitle("Saved Plans")
        .navigationDestination(isPresented: $showingPlan) {
            if let selectedPlan = selectedPlan {
                MealPlanView(mealPlan: selectedPlan)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Saved Plans")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your saved meal plans will appear here")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var plansList: some View {
        List {
            ForEach(storage.savedPlans) { plan in
                Button(action: {
                    selectedPlan = plan
                    showingPlan = true
                }) {
                    SavedPlanRow(plan: plan)
                }
            }
            .onDelete(perform: storage.deletePlan)
        }
    }
}

struct SavedPlanRow: View {
    let plan: MealPlan
    
    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if plan.meals.isEmpty {
            return formatter.string(from: plan.weekStartDate)
        }
        
        let firstDate = plan.meals.first?.date ?? plan.weekStartDate
        let lastDate = plan.meals.last?.date ?? plan.weekStartDate
        
        if Calendar.current.isDate(firstDate, inSameDayAs: lastDate) {
            return formatter.string(from: firstDate)
        } else {
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text(dateRange)
                    .font(.headline)
            }
            
            HStack {
                Label("\(plan.meals.count) days", systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("£\(String(format: "%.2f", plan.totalCost))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("of £\(String(format: "%.2f", plan.budget))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SavedPlansView()
            .environmentObject(MealPlanStorage())
    }
}
