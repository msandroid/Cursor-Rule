//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import XCTest
@testable import Cription

@MainActor
class TierSystemTests: XCTestCase {
    var tierSystemManager: TierSystemManager!
    
    override func setUp() {
        super.setUp()
        tierSystemManager = TierSystemManager.shared
    }
    
    override func tearDown() {
        tierSystemManager = nil
        super.tearDown()
    }
    
    // MARK: - Tier Determination Tests
    
    func testTier1Default() {
        // Given: No historical spend and no first payment date
        tierSystemManager.historicalSpend = 0.0
        tierSystemManager.firstPaymentDate = nil
        
        // When: Determining tier
        let tier = tierSystemManager.currentTier
        
        // Then: Should be Tier 1
        XCTAssertEqual(tier, .tier1)
    }
    
    func testTier2Qualification() {
        // Given: $50+ historical spend and 7+ days since first payment
        tierSystemManager.historicalSpend = 50.0
        tierSystemManager.firstPaymentDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        
        // When: Determining tier
        tierSystemManager.updateCurrentTier()
        
        // Then: Should be Tier 2
        XCTAssertEqual(tierSystemManager.currentTier, .tier2)
    }
    
    func testTier3Qualification() {
        // Given: $500+ historical spend and 14+ days since first payment
        tierSystemManager.historicalSpend = 500.0
        tierSystemManager.firstPaymentDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())
        
        // When: Determining tier
        tierSystemManager.updateCurrentTier()
        
        // Then: Should be Tier 3
        XCTAssertEqual(tierSystemManager.currentTier, .tier3)
    }
    
    func testTier4Qualification() {
        // Given: $5,000+ historical spend and 30+ days since first payment
        tierSystemManager.historicalSpend = 5000.0
        tierSystemManager.firstPaymentDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        
        // When: Determining tier
        tierSystemManager.updateCurrentTier()
        
        // Then: Should be Tier 4
        XCTAssertEqual(tierSystemManager.currentTier, .tier4)
    }
    
    func testTier2InsufficientDays() {
        // Given: $50+ historical spend but only 3 days since first payment
        tierSystemManager.historicalSpend = 50.0
        tierSystemManager.firstPaymentDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        
        // When: Determining tier
        tierSystemManager.updateCurrentTier()
        
        // Then: Should still be Tier 1 (insufficient days)
        XCTAssertEqual(tierSystemManager.currentTier, .tier1)
    }
    
    func testTier2InsufficientSpend() {
        // Given: Only $25 historical spend but 7+ days since first payment
        tierSystemManager.historicalSpend = 25.0
        tierSystemManager.firstPaymentDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        
        // When: Determining tier
        tierSystemManager.updateCurrentTier()
        
        // Then: Should still be Tier 1 (insufficient spend)
        XCTAssertEqual(tierSystemManager.currentTier, .tier1)
    }
    
    // MARK: - Spending Limit Tests
    
    func testMonthlySpendingLimit() {
        // Given: Tier 1 with $50 monthly limit
        tierSystemManager.currentTier = .tier1
        tierSystemManager.currentMonthlySpend = 0.0
        
        // When: Checking if can spend $30
        let canSpend = tierSystemManager.canSpend(30.0)
        
        // Then: Should be able to spend
        XCTAssertTrue(canSpend)
    }
    
    func testMonthlySpendingLimitExceeded() {
        // Given: Tier 1 with $50 monthly limit and $40 already spent
        tierSystemManager.currentTier = .tier1
        tierSystemManager.currentMonthlySpend = 40.0
        
        // When: Checking if can spend $20
        let canSpend = tierSystemManager.canSpend(20.0)
        
        // Then: Should not be able to spend (would exceed limit)
        XCTAssertFalse(canSpend)
    }
    
    func testAddSpending() {
        // Given: Tier 1 with $0 monthly spend
        tierSystemManager.currentTier = .tier1
        tierSystemManager.currentMonthlySpend = 0.0
        
        // When: Adding $25 spending
        tierSystemManager.addSpending(25.0)
        
        // Then: Monthly spend should be $25
        XCTAssertEqual(tierSystemManager.currentMonthlySpend, 25.0)
    }
    
    func testAddSpendingExceedsLimit() {
        // Given: Tier 1 with $40 monthly spend
        tierSystemManager.currentTier = .tier1
        tierSystemManager.currentMonthlySpend = 40.0
        
        // When: Adding $20 spending (would exceed $50 limit)
        tierSystemManager.addSpending(20.0)
        
        // Then: Monthly spend should remain $40 (spending should be rejected)
        XCTAssertEqual(tierSystemManager.currentMonthlySpend, 40.0)
    }
    
    // MARK: - Custom Limit Tests
    
    func testCustomLimit() {
        // Given: Custom limit of $100
        tierSystemManager.setCustomLimit(100.0)
        
        // When: Checking current limit
        let limit = tierSystemManager.getCurrentLimit()
        
        // Then: Should be $100
        XCTAssertEqual(limit, 100.0)
        XCTAssertEqual(tierSystemManager.currentTier, .custom)
    }
    
    func testClearCustomLimit() {
        // Given: Custom limit set
        tierSystemManager.setCustomLimit(100.0)
        XCTAssertEqual(tierSystemManager.currentTier, .custom)
        
        // When: Clearing custom limit
        tierSystemManager.clearCustomLimit()
        
        // Then: Should revert to tier-based limit
        XCTAssertNotEqual(tierSystemManager.currentTier, .custom)
    }
    
    // MARK: - Tier Information Tests
    
    func testGetNextTier() {
        // Given: Currently at Tier 1
        tierSystemManager.currentTier = .tier1
        
        // When: Getting next tier
        let nextTier = tierSystemManager.getNextTier()
        
        // Then: Should be Tier 2
        XCTAssertEqual(nextTier, .tier2)
    }
    
    func testGetNextTierFromTier4() {
        // Given: Currently at Tier 4
        tierSystemManager.currentTier = .tier4
        
        // When: Getting next tier
        let nextTier = tierSystemManager.getNextTier()
        
        // Then: Should be nil (no higher tier)
        XCTAssertNil(nextTier)
    }
    
    func testGetRequiredSpendForNextTier() {
        // Given: Tier 1 with $25 historical spend
        tierSystemManager.currentTier = .tier1
        tierSystemManager.historicalSpend = 25.0
        
        // When: Getting required spend for next tier
        let requiredSpend = tierSystemManager.getRequiredSpendForNextTier()
        
        // Then: Should be $25 (need $50 total, have $25)
        XCTAssertEqual(requiredSpend, 25.0)
    }
    
    func testGetRequiredDaysForNextTier() {
        // Given: Tier 1 with 3 days since first payment
        tierSystemManager.currentTier = .tier1
        tierSystemManager.firstPaymentDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        
        // When: Getting required days for next tier
        let requiredDays = tierSystemManager.getRequiredDaysForNextTier()
        
        // Then: Should be 4 (need 7 total, have 3)
        XCTAssertEqual(requiredDays, 4)
    }
    
    // MARK: - Data Validation Tests
    
    func testInvalidSpendingAmount() {
        // Given: Tier 1 with $0 monthly spend
        tierSystemManager.currentTier = .tier1
        tierSystemManager.currentMonthlySpend = 0.0
        
        // When: Adding negative spending
        tierSystemManager.addSpending(-10.0)
        
        // Then: Monthly spend should remain $0
        XCTAssertEqual(tierSystemManager.currentMonthlySpend, 0.0)
    }
    
    func testInvalidCustomLimit() {
        // Given: Tier 1
        tierSystemManager.currentTier = .tier1
        
        // When: Setting negative custom limit
        tierSystemManager.setCustomLimit(-50.0)
        
        // Then: Should remain at Tier 1
        XCTAssertEqual(tierSystemManager.currentTier, .tier1)
    }
    
    // MARK: - Edge Cases
    
    func testExactTierThreshold() {
        // Given: Exactly $50 historical spend and exactly 7 days
        tierSystemManager.historicalSpend = 50.0
        tierSystemManager.firstPaymentDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        
        // When: Determining tier
        tierSystemManager.updateCurrentTier()
        
        // Then: Should be Tier 2 (meets exact requirements)
        XCTAssertEqual(tierSystemManager.currentTier, .tier2)
    }
    
    func testLargeHistoricalSpend() {
        // Given: Very large historical spend
        tierSystemManager.historicalSpend = 100000.0
        tierSystemManager.firstPaymentDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        
        // When: Determining tier
        tierSystemManager.updateCurrentTier()
        
        // Then: Should be Tier 4 (highest tier)
        XCTAssertEqual(tierSystemManager.currentTier, .tier4)
    }
}
