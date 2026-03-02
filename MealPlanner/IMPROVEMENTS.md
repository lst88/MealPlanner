# Meal Planner App - Improvements Summary

## Overview
This meal planner app uses Claude AI to generate personalized meal plans based on budget, dates, and dietary preferences.

## Recent Enhancements

### 1. ✅ Use Actual Selected Dates
**What changed:**
- Previously, the app only counted the number of selected dates
- Now it passes the actual selected dates to Claude AI
- The generated meal plan will reflect the specific days of the week you selected

**Files modified:**
- `ContentView.swift` - Sorts and passes selected dates
- `ClaudeAPIService.swift` - Includes specific dates in the prompt

### 2. 🥗 Expanded Dietary Preferences
**What changed:**
- Replaced simple vegetarian toggle with a comprehensive picker
- Now supports: No Restrictions, Vegetarian, Vegan, Pescatarian, Gluten-Free
- Each option has a description and icon

**Files modified:**
- `ClaudeAPIService.swift` - Added `DietaryPreference` enum
- `ContentView.swift` - Replaced toggle with picker UI

### 3. 💾 Meal Plan Persistence
**What added:**
- Save and load meal plans locally
- View all saved plans in a dedicated screen
- Delete saved plans with swipe gesture
- Automatically limits to 20 most recent plans

**New files:**
- `MealPlanStorage.swift` - Handles saving/loading with UserDefaults
- `SavedPlansView.swift` - UI for browsing saved plans

**Files modified:**
- `ContentView.swift` - Added storage and navigation to saved plans
- `MealPlanView.swift` - Added save button and bookmark indicator

### 4. 📤 Share & Export
**What added:**
- Share button in meal plan view
- Generates formatted text with all meals and shopping list
- Uses native iOS share sheet
- Can share via Messages, Email, Notes, etc.

**Files modified:**
- `MealPlanView.swift` - Added share functionality and ActivityViewController

### 5. 🎨 UI Polish
**What changed:**
- Improved header description
- Better spacing and visual hierarchy
- Dietary preference icons and descriptions
- Cleaner toolbar with multiple actions

## Key Features

### Current Functionality:
✅ Multi-date selection from calendar
✅ Budget input (per day or total)
✅ Five dietary preference options
✅ Toggle for detailed ingredients
✅ AI-powered meal generation
✅ Shopping list consolidation
✅ Save meal plans locally
✅ View saved plans history
✅ Share meal plans
✅ Handles partial responses gracefully
✅ Prompt caching for cost savings

### Data Flow:
1. User selects dates, budget, and preferences
2. ContentView validates input
3. ClaudeAPIService builds prompt with cached system instructions
4. Claude generates JSON meal plan
5. Response is parsed into MealPlan model
6. MealPlanView displays with tabs for meals and shopping
7. User can save or share the plan

## Architecture

```
ContentView (Main Input)
    ├── ClaudeAPIService (API Communication)
    ├── MealPlanStorage (Persistence)
    └── MealPlanView (Display & Actions)
        ├── BudgetOverviewCard
        ├── DailyMealCard
        ├── ShoppingListView
        ├── RecipeDetailView
        ├── SavedPlansView
        └── ActivityViewController (Sharing)
```

## Models

- **MealPlan**: Top-level container with budget, meals, total cost
- **DailyMeals**: One day with breakfast, lunch, dinner
- **Recipe**: Meal name, ingredients, cost, servings
- **Ingredient**: Name, quantity, estimated price
- **DietaryPreference**: Enum for dietary restrictions

## API Integration

### Claude API Features Used:
- Prompt caching (system messages cached for 5 minutes)
- Streaming response handling
- Dynamic token allocation based on complexity
- Error recovery for truncated responses
- JSON-only response mode

### Token Optimization:
- Without ingredients: ~250 tokens/day
- With ingredients: ~650 tokens/day
- Adds 20% safety margin
- Recovers partial JSON if truncated

## Future Enhancement Ideas

### Potential Additions:
1. **Recipe Instructions**: Ask Claude to include cooking steps
2. **Nutritional Info**: Add calories, protein, carbs per meal
3. **Favorites System**: Mark and reuse favorite meals
4. **Custom Restrictions**: Allergies, dislikes, specific ingredients
5. **Store Preferences**: Save default budget and dietary preferences
6. **Meal Swapping**: Regenerate a single meal within the plan
7. **Export to Calendar**: Add meals to iOS Calendar app
8. **PDF Export**: Professional printable meal plans
9. **Cost Tracking**: Compare estimated vs actual costs
10. **Multi-person Planning**: Scale recipes for family size

### Possible Integrations:
- HealthKit for nutritional tracking
- Reminders app for shopping list
- Maps for nearby grocery stores
- Photos for meal logging

## Testing Checklist

- [ ] Select various date ranges (1 day, 7 days, 14 days)
- [ ] Test all dietary preferences
- [ ] Verify budget calculations (per day vs total)
- [ ] Generate plan with and without ingredients
- [ ] Save and load multiple meal plans
- [ ] Delete saved plans
- [ ] Share meal plan via different apps
- [ ] Test with no network connection
- [ ] Test with invalid API key
- [ ] Verify calendar respects selected dates
- [ ] Check shopping list consolidation
- [ ] Test recipe detail view

## Configuration

Remember to set your Claude API key in `APIConfig.swift`:
```swift
static let apiKey = "YOUR_CLAUDE_API_KEY_HERE"
```

Get your API key from: https://console.anthropic.com/

## Cost Considerations

- Prompt caching reduces costs by ~90% on repeated system messages
- Cache lasts 5 minutes
- Without ingredients: ~$0.01-0.02 per plan
- With ingredients: ~$0.03-0.05 per plan
- Token allocation scales with number of days

## Platform Compatibility

- **iOS 16.0+**: Full functionality
- **iPadOS 16.0+**: Optimized for larger screens
- **macOS 13.0+**: Works with Mac Catalyst (if enabled)

## Dependencies

- SwiftUI (Native)
- Foundation (Native)
- Combine (for @Published properties)
- UIKit (for share sheet only)

No external packages required!
