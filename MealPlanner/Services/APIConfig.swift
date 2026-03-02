//
//  APIConfig.swift
//  MealPlanner
//
//  Created by Lucian Stan on 10/02/2026.
//

import Foundation

struct APIConfig {
    // API key is now stored in Secrets.swift (which is git-ignored)
    // See Secrets.swift.template for setup instructions
    static let apiKey = Secrets.claudeAPIKey
    
    static let baseURL = "https://api.anthropic.com/v1/messages"
    static let model = "claude-sonnet-4-5-20250929"
    static let apiVersion = "2023-06-01"
    
    // Validate that API key is set
    static var isConfigured: Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_CLAUDE_API_KEY_HERE"
    }
}


