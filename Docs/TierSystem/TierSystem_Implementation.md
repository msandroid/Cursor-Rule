# Tier System Implementation Documentation

## Overview

This document describes the implementation of the Tier System and Spending Limits functionality in Cription, which is based on OpenAI's tier system and uses StoreKit 2 for transaction management.

## Architecture

### Core Components

1. **TierSystemManager** - Main manager for tier calculations and StoreKit integration
2. **SpendingLimitsManager** - Delegates to TierSystemManager for backward compatibility
3. **SpendingLimitsViewModel** - UI state management for the spending limits view
4. **SpendingLimitsView** - SwiftUI view for displaying tier information

### Data Flow

```
StoreKit 2 Transactions → TierSystemManager → SpendingLimitsManager → SpendingLimitsViewModel → SpendingLimitsView
```

## Implementation Details

### 1. Tier System Logic

The tier system follows OpenAI's tier structure:

| Tier | Monthly Limit | Historical Spend Requirement | Days Requirement |
|------|---------------|------------------------------|------------------|
| Tier 1 | $50 | Default (valid payment method) | Immediate |
| Tier 2 | $500 | $50+ | 7+ days |
| Tier 3 | $5,000 | $500+ | 14+ days |
| Tier 4 | $50,000 | $5,000+ | 30+ days |
| Custom | Variable | Contact support | N/A |

### 2. StoreKit 2 Integration

#### Transaction History Retrieval
```swift
// Uses Transaction.all to get all user transactions
for await result in Transaction.all {
    let transaction = try checkVerified(result)
    // Process transaction for historical spend calculation
}
```

#### Real-time Transaction Updates
```swift
// Monitors Transaction.updates for new purchases
for await result in Transaction.updates {
    let transaction = try checkVerified(result)
    await handleTransactionUpdate(transaction)
}
```

#### Product Price Mapping
The system maps product IDs to prices for historical spend calculation:
- Credit purchases: `Cription.credits.*`
- Subscriptions: `Cription.plus.*`
- Model purchases: `Cription.model.*`

### 3. Data Storage

#### Secure Data (Keychain)
- Historical spend amount
- First payment date

#### UserDefaults
- Current tier
- Monthly spend (resets monthly)
- Custom limit
- Last reset date

### 4. Monthly Reset Logic

The system automatically resets monthly spending on the first day of each month:

```swift
private func checkMonthlyReset() {
    let calendar = Calendar.current
    let now = Date()
    
    if let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date {
        if let nowMonthStart = calendar.dateInterval(of: .month, for: now)?.start,
           let lastMonthStart = calendar.dateInterval(of: .month, for: lastResetDate)?.start {
            if nowMonthStart != lastMonthStart {
                resetMonthlySpend()
            }
        }
    }
}
```

## Key Features

### 1. Automatic Tier Calculation
- Calculates tier based on historical spend and days since first payment
- Updates automatically when new transactions are processed
- Handles edge cases and data validation

### 2. Spending Limit Enforcement
- Checks spending limits before allowing API usage
- Prevents spending that would exceed monthly limits
- Provides real-time limit checking

### 3. Credit Purchase Integration
- Integrates with StoreKit 2 for credit purchases
- Automatically updates historical spend when credits are purchased
- Maps credit amounts to appropriate product IDs

### 4. Data Persistence and Security
- Uses Keychain for sensitive data (historical spend, first payment date)
- Uses UserDefaults for non-sensitive data
- Implements data integrity checks

### 5. Error Handling
- Comprehensive error handling for StoreKit operations
- Data validation for spending amounts and limits
- Graceful fallbacks for edge cases

## Usage Examples

### Checking Spending Limits
```swift
let tierSystemManager = TierSystemManager.shared

// Check if user can spend a certain amount
if tierSystemManager.canSpend(25.0) {
    // Allow spending
    tierSystemManager.addSpending(25.0)
} else {
    // Show limit exceeded message
}
```

### Purchasing Credits
```swift
let tierSystemManager = TierSystemManager.shared

do {
    try await tierSystemManager.purchaseCredits(100.0)
    // Purchase successful, tier will be updated automatically
} catch {
    // Handle purchase error
}
```

### Getting Tier Information
```swift
let tierSystemManager = TierSystemManager.shared

let currentTier = tierSystemManager.currentTier
let monthlyLimit = tierSystemManager.getCurrentLimit()
let remainingLimit = tierSystemManager.getRemainingLimit()
let nextTier = tierSystemManager.getNextTier()
```

## Testing

The implementation includes comprehensive unit tests covering:
- Tier determination logic
- Spending limit enforcement
- Custom limit management
- Edge cases and error conditions
- Data validation

Run tests with:
```bash
xcodebuild test -scheme Cription -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Security Considerations

1. **Data Encryption**: Sensitive data is stored in Keychain with encryption
2. **Transaction Verification**: All StoreKit transactions are verified before processing
3. **Data Integrity**: Regular integrity checks ensure data consistency
4. **Input Validation**: All user inputs are validated before processing

## Performance Considerations

1. **Async Operations**: All StoreKit operations are performed asynchronously
2. **Data Caching**: Frequently accessed data is cached in memory
3. **Batch Processing**: Transaction processing is optimized for performance
4. **Memory Management**: Proper cleanup of resources and observers

## Future Enhancements

1. **Server-side Validation**: Add server-side spending limit validation
2. **Analytics**: Track spending patterns and tier progression
3. **Notifications**: Alert users when approaching spending limits
4. **Team Management**: Support for team/organization spending limits
5. **Regional Limits**: Different limits based on user location

## Troubleshooting

### Common Issues

1. **Transactions Not Updating**: Ensure StoreKit 2 is properly configured
2. **Tier Not Updating**: Check that historical spend and days requirements are met
3. **Data Sync Issues**: Verify Keychain and UserDefaults access permissions
4. **Purchase Failures**: Check product IDs and StoreKit configuration

### Debug Logging

The implementation includes comprehensive logging for debugging:
- Transaction processing logs
- Tier calculation logs
- Data persistence logs
- Error condition logs

Enable debug logging by setting the appropriate log level in the app configuration.

## Conclusion

The Tier System implementation provides a robust, secure, and scalable solution for managing user spending limits based on their payment history. It integrates seamlessly with StoreKit 2 and provides a smooth user experience while maintaining data integrity and security.
