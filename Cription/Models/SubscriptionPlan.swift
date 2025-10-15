//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation

enum SubscriptionPlan: String, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case unlimited = "unlimited"
    
    var title: String {
        switch self {
        case .weekly: return "1 Week"
        case .monthly: return "1 Month"
        case .unlimited: return "Unlimited"
        }
    }
    
    var price: String {
        switch self {
        case .weekly: return "$5.00"
        case .monthly: return "$20.00"
        case .unlimited: return "Pay as you go"
        }
    }
    
    var productID: String {
        switch self {
        case .weekly: return "Cription.weekly"
        case .monthly: return "Cription.pro.monthly"
        case .unlimited: return "Cription.unlimited.monthly"
        }
    }
    
    var isPopular: Bool {
        return self == .weekly
    }
    
    var description: String {
        switch self {
        case .weekly:
            return "Perfect for trying out our premium features"
        case .monthly:
            return "Best value for regular users with 3000 minutes"
        case .unlimited:
            return "Unlimited access to all features and models"
        }
    }
    
    var bannerImage: String {
        switch self {
        case .weekly: return "plus_banner"
        case .monthly: return "pro_banner"
        case .unlimited: return "unlimited_banner"
        }
    }
}
