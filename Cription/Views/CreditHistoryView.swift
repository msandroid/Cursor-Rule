//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import SwiftUI

struct CreditHistoryView: View {
    @StateObject private var creditManager = CreditManager.shared
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Past Week"
        case month = "Past Month"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return 365
            }
        }
    }
    
    var filteredTransactions: [CreditTransaction] {
        if selectedPeriod == .all {
            return creditManager.creditTransactions
        } else {
            return creditManager.getTransactionsForPeriod(days: selectedPeriod.days)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Period Selector
                Picker("Time Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Transactions List
                if filteredTransactions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Transactions")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your credit transactions will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredTransactions.reversed(), id: \.id) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Credit History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}

struct TransactionRow: View {
    let transaction: CreditTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Transaction Icon
            Image(systemName: transactionIcon)
                .font(.title2)
                .foregroundColor(transactionColor)
                .frame(width: 32, height: 32)
                .background(transactionColor.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transactionDescription)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(transaction.source.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amountText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(transactionColor)
                
                Text(transaction.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var transactionIcon: String {
        switch transaction.source {
        case .purchase:
            return "creditcard.fill"
        case .apiUsage:
            return "waveform"
        case .bonus:
            return "gift.fill"
        case .refund:
            return "arrow.uturn.backward.circle.fill"
        }
    }
    
    private var transactionColor: Color {
        switch transaction.type {
        case .credit:
            return .green
        case .debit:
            return .red
        }
    }
    
    private var transactionDescription: String {
        if !transaction.description.isEmpty {
            return transaction.description
        }
        
        switch transaction.source {
        case .purchase:
            return "Credit Purchase"
        case .apiUsage:
            return "API Usage"
        case .bonus:
            return "Bonus Credits"
        case .refund:
            return "Refund"
        }
    }
    
    private var amountText: String {
        let sign = transaction.type == .credit ? "+" : "-"
        return "\(sign)\(String(format: "%.1f", abs(transaction.amount)))"
    }
}

#Preview {
    CreditHistoryView()
}
