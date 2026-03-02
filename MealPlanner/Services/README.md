# Weekly Meal Planner iOS App

An iOS app that generates personalized weekly meal plans within your budget using Claude AI.

## Features

- 📊 Budget-based meal planning
- 🍳 Simple, affordable recipes
- 🛒 Automatic shopping list generation with prices
- 📱 Clean, intuitive SwiftUI interface
- 🤖 AI-powered meal suggestions using Claude

## Setup Instructions

### 1. Get Your Claude API Key

1. Visit [https://console.anthropic.com/](https://console.anthropic.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key

### 2. Configure the App

1. Open `APIConfig.swift`
2. Replace `"YOUR_CLAUDE_API_KEY_HERE"` with your actual API key:

```swift
static let apiKey = "sk-ant-api03-..."  // Your actual key here
```

### 3. Run the App

1. Open the project in Xcode 15.0 or later
2. Select your target device (iOS 17.0+)
3. Click Run (⌘R)

## How to Use

1. **Enter Your Budget**: Type in your weekly budget in pounds (£)
2. **Generate Plan**: Tap "Generate Meal Plan" and wait for AI to create your plan
3. **View Meals**: Browse through 7 days of breakfast, lunch, and dinner
4. **Check Recipes**: Tap any meal to see full recipe details and cooking instructions
5. **Shopping List**: Switch to the Shopping List tab to see all ingredients you need to buy

## App Structure

### Models
- `Recipe.swift` - Recipe and Ingredient data models
- `MealPlan.swift` - Weekly meal plan and daily meals structures

### Services
- `APIConfig.swift` - API configuration and key storage
- `ClaudeAPIService.swift` - Handles communication with Claude API

### Views
- `ContentView.swift` - Main screen with budget input
- `MealPlanView.swift` - Displays meal plan, recipes, and shopping list

## Technical Details

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Architecture**: MVVM with async/await
- **AI Model**: Claude 3.5 Sonnet

## Learning Points

As a new iOS developer, this project demonstrates:

1. **SwiftUI Basics**: Views, state management, navigation
2. **Async/Await**: Modern Swift concurrency for API calls
3. **ObservableObject**: Reactive state management with `@StateObject`
4. **REST API Integration**: HTTP requests with URLSession
5. **JSON Parsing**: Codable protocol for encoding/decoding
6. **Navigation**: NavigationStack and sheet presentations
7. **List Views**: ScrollView, LazyVStack, ForEach
8. **Custom Components**: Reusable view components

## Customization Ideas

- Add dietary restrictions (vegetarian, vegan, gluten-free)
- Save favorite meal plans locally
- Share shopping lists via Messages or Email
- Add nutritional information
- Include meal prep time estimates
- Support for multiple cuisines

## API Usage Notes

- Each meal plan generation costs approximately $0.01-0.03 in API credits
- The app uses Claude 3.5 Sonnet for best quality results
- API responses typically take 5-15 seconds
- Make sure you have a stable internet connection

## Troubleshooting

**"API key not configured" error:**
- Check that you've updated APIConfig.swift with your key
- Ensure the key starts with "sk-ant-api"

**"Invalid response" error:**
- Check your internet connection
- Verify your API key is valid and has credits

**App won't build:**
- Ensure you're using Xcode 15.0+ with iOS 17.0+ SDK
- Clean build folder (Shift+⌘K) and rebuild

## Next Steps

To continue learning, try:
1. Adding data persistence with SwiftData
2. Implementing user preferences
3. Creating custom animations
4. Adding unit tests with Swift Testing
5. Supporting iPad and Mac with SwiftUI's adaptability

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Claude API Documentation](https://docs.anthropic.com/)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

---

Built with ❤️ using SwiftUI and Claude AI
