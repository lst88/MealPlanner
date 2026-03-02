# 🍽️ AI Meal Planner

An intelligent iOS meal planning app that generates personalized meal plans based on your budget, schedule, and dietary preferences using Claude AI.

![iOS 16.0+](https://img.shields.io/badge/iOS-16.0%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwiftUI-green)

<!-- TODO: Add screenshots here -->
<!-- Screenshot suggestions:
1. Main day selection screen showing calendar with selected days
2. Budget configuration page with dietary preferences
3. Generated meal plan view showing daily meals
4. Shopping list tab with consolidated ingredients and prices
-->

## 🎯 What Does This App Do?

AI Meal Planner helps you plan your meals intelligently by:

1. **Select Your Days** - Choose any combination of days from this week and next week
2. **Set Your Budget** - Define your total budget or per-day budget in pounds (£)
3. **Choose Dietary Preferences** - Select from vegetarian, vegan, pescatarian, gluten-free, or no restrictions
4. **Generate Smart Plans** - AI creates balanced meal plans with breakfast, lunch, and dinner
5. **Get Shopping Lists** - Automatically consolidates all ingredients with estimated prices
6. **Save & Share** - Keep your favorite plans and share them via Messages, Email, or other apps

### Key Features

✨ **Smart Day Selection**
- Calendar-style picker for this week and next week
- Past days are automatically disabled
- Visual selection state for easy planning

💰 **Flexible Budget Management**
- Set total budget or per-day budget
- Real-time calculation shows both views
- AI optimizes meals to fit your budget

🥗 **Dietary Preferences**
- **No Restrictions** - All foods included
- **Vegetarian** - No meat, poultry, fish, or seafood
- **Vegan** - No animal products
- **Pescatarian** - No meat or poultry
- **Gluten-Free** - No gluten-containing grains

🛒 **Smart Shopping Lists**
- Optional detailed ingredient lists with prices
- Consolidated across all meals (e.g., "eggs" combined from multiple recipes)
- Quick mode without ingredients for faster generation

💾 **Meal Plan Library**
- Save meal plans locally on your device
- Browse past plans with budget and date info
- Quick access to your favorite meal combinations
- Automatic limit to 20 most recent plans

📤 **Easy Sharing**
- Export full meal plan as formatted text
- Share via native iOS share sheet
- Compatible with Messages, Email, Notes, and more

## 🚀 Setup Instructions

### Prerequisites

- **Xcode 15.0** or later
- **iOS 16.0+** deployment target
- A [Claude API account](https://console.anthropic.com/) (free tier available)

### Step 1: Get Your Claude API Key

1. Visit [https://console.anthropic.com/](https://console.anthropic.com/)
2. Sign up for an account (if you don't have one)
3. Navigate to **API Keys** in the dashboard
4. Click **Create Key** and give it a name
5. Copy your API key (starts with `sk-ant-api03-...`)

> **Note**: Keep your API key secure and never commit it to public repositories.

### Step 2: Clone & Configure

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/meal-planner.git
   cd meal-planner
   ```

2. Create your secrets file:
   ```bash
   cp Secrets.swift.template Secrets.swift
   ```

3. Open `Secrets.swift` in Xcode and replace the placeholder with your actual API key:
   ```swift
   struct Secrets {
       static let claudeAPIKey = "sk-ant-api03-YOUR_ACTUAL_KEY_HERE"
   }
   ```

> **Security Note**: `Secrets.swift` is in `.gitignore` and will never be committed to version control. The template file shows the structure but doesn't contain your actual key.

### Step 3: Build & Run

1. Open `MealPlanner.xcodeproj` in Xcode
2. Select your target device or simulator (iOS 16.0+)
3. Press **⌘R** or click the Run button
4. The app will launch on your selected device

## 📱 How to Use

### Creating Your First Meal Plan

1. **Select Days**
   - On the first screen, tap the days you want meals for
   - You can select from this week (excluding past days) and next week
   - The selection count appears at the bottom

2. **Configure Settings**
   - Tap "Next" to proceed to settings
   - Enter your budget amount (£)
   - Choose "Per Day" or "Total" budget type
   - Select your dietary preference from the dropdown
   - Toggle "Include Ingredients" if you want detailed shopping lists

3. **Generate Plan**
   - Tap "Generate Meal Plan" (the sparkle ✨ button)
   - Wait 5-15 seconds while AI creates your plan
   - The plan automatically opens when ready

4. **Browse Your Meals**
   - Scroll through each day's breakfast, lunch, and dinner
   - Tap any meal card to see recipe details
   - Switch to the "Shopping List" tab to see all ingredients

5. **Save or Share**
   - Tap the bookmark icon to save the plan locally
   - Tap the share icon to export and send to others

### Managing Saved Plans

1. Tap the **bookmark icon** in the top-right corner of the main screen
2. Browse your saved meal plans
3. Tap any plan to view it again
4. Swipe left on a plan to delete it

## 🏗️ Project Structure

```
MealPlanner/
├── Models/
│   ├── MealPlan.swift          # Meal plan data structure
│   ├── Recipe.swift             # Recipe and ingredient models
│   └── APIModels.swift          # API request/response models
│
├── Services/
│   ├── APIConfig.swift          # API configuration constants
│   ├── Secrets.swift            # API keys (git-ignored)
│   ├── ClaudeAPIService.swift   # Claude API integration
│   └── MealPlanStorage.swift    # Local persistence layer
│
├── Views/
│   ├── ContentView.swift        # Main input screens (2-page flow)
│   ├── MealPlanView.swift       # Meal plan display with tabs
│   ├── SavedPlansView.swift     # Saved plans library
│   └── RecipeDetailView.swift   # Individual recipe details
│
├── Secrets.swift.template       # Template for API keys
├── .gitignore                   # Git ignore rules
└── README.md                    # This file
```

## 🔧 Technical Details

### Architecture

- **Pattern**: MVVM (Model-View-ViewModel)
- **Concurrency**: Swift async/await for API calls
- **State Management**: SwiftUI's `@State`, `@StateObject`, and `@Binding`
- **Persistence**: UserDefaults with Codable protocol
- **Navigation**: NavigationStack and NavigationLink

### API Integration

- **Model**: Claude 3.5 Sonnet (latest)
- **Features Used**:
  - Prompt caching (90% cost reduction on repeated calls)
  - JSON response mode
  - Dynamic token allocation based on plan complexity
  - Partial response recovery for large plans

### Cost Optimization

- **Without ingredients**: ~$0.01-0.02 per meal plan
- **With ingredients**: ~$0.03-0.05 per meal plan
- Prompt caching reduces costs by ~90% (5-minute cache window)
- Token allocation scales with number of selected days

### Performance Considerations

- API responses typically take 5-15 seconds
- Larger plans (7+ days with ingredients) may take longer
- Partial response warnings if AI response is truncated
- Automatic retry logic for failed requests

## ⚠️ Troubleshooting

### "API key not configured" Error

**Problem**: The API key isn't set correctly

**Solution**:
1. Ensure you've created `Secrets.swift` from the template
2. Open `Secrets.swift` and verify your API key is properly pasted
3. Verify it starts with `sk-ant-api03-`
4. Make sure there are no extra spaces or quotes
5. Rebuild the project (⌘B)

### "Invalid response" or Network Errors

**Problem**: Can't connect to Claude API

**Solution**:
1. Check your internet connection
2. Verify your API key at [console.anthropic.com](https://console.anthropic.com/)
3. Ensure you have available API credits
4. Try reducing the number of days or disabling ingredients

### App Won't Build

**Problem**: Compilation errors in Xcode

**Solution**:
1. Ensure you're using **Xcode 15.0+**
2. Verify iOS deployment target is **16.0+**
3. Clean build folder: **Product > Clean Build Folder** (⇧⌘K)
4. Restart Xcode and try again

### Partial Meal Plan Warning

**Problem**: You selected 7 days but only got 5

**Solution**:
- This happens when the AI response is very large
- The app will warn you but the plan is still usable
- Try disabling "Include Ingredients" for longer plans
- Or split into two shorter plans

## 🎓 Learning Resources

This project is great for learning iOS development. Key concepts demonstrated:

- ✅ SwiftUI view composition and layouts
- ✅ State management with property wrappers
- ✅ Async/await for network requests
- ✅ JSON encoding/decoding with Codable
- ✅ Custom view modifiers and reusable components
- ✅ NavigationStack and programmatic navigation
- ✅ UserDefaults for data persistence
- ✅ Share sheet integration with UIKit
- ✅ Form input validation
- ✅ Error handling and user feedback

### Recommended Next Steps

1. **Add SwiftData**: Replace UserDefaults with SwiftData for more robust persistence
2. **Implement Unit Tests**: Use Swift Testing framework to test business logic
3. **Add Widgets**: Create a Today widget showing the current day's meals
4. **Support macOS**: Enable Mac Catalyst for desktop support
5. **Add Animations**: Enhance transitions and loading states
6. **Implement Search**: Add search/filter in saved plans
7. **Recipe Instructions**: Extend AI prompt to include cooking steps
8. **Nutrition Facts**: Request calorie and macro information from AI

### Helpful Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/) - Official SwiftUI reference
- [Claude API Documentation](https://docs.anthropic.com/) - API reference and guides
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) - Async/await guide
- [Swift Testing](https://developer.apple.com/documentation/testing) - Modern testing framework
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) - iOS design best practices

## 🤝 Contributing

Contributions are welcome! Some ideas:

- 🐛 Bug fixes and error handling improvements
- ✨ New features (see "Next Steps" above)
- 📝 Documentation improvements
- 🎨 UI/UX enhancements
- 🧪 Test coverage

## 📄 License

This project is available under the MIT License. See LICENSE file for details.

## 🙏 Acknowledgments

- Powered by [Claude AI](https://www.anthropic.com/) from Anthropic
- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

---

**Built with ❤️ and SwiftUI**
Questions? Issues? Open an issue on GitHub or contact the maintainer.
