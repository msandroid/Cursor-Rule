//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI

struct DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DashboardTab = .overview
    @State private var isSidebarVisible = false
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var analyticsManager = AnalyticsManager.shared
    
    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case models = "Models"
        case history = "History"
        case billing = "Billing"
        case spendingLimits = "Spending Limits"
        case documents = "Documents"
        
        var icon: String {
            switch self {
            case .overview:
                return "chart.bar.xaxis"
            case .models:
                return "square.stack.3d.up.fill"
            case .history:
                return "equal"
            case .billing:
                return "creditcard.circle"
            case .spendingLimits:
                return "dollarsign.circle"
            case .documents:
                return "doc.text.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                contentArea
                sidebarOverlay
                sidebar
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                    isSidebarVisible = true
                }
            }
        }
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        VStack(spacing: 0) {
            // Top Bar
            topBar
            
            // Tab Content
            tabContent
        }
        .background(themeManager.isDarkMode ? Color.black : Color.white)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSidebarVisible.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
            }
            
            Spacer()
            
            Text(LocalizedStringKey(selectedTab.rawValue))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeManager.isDarkMode ? Color.black : Color.white)
        .overlay(
            Rectangle()
                .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            OverviewTabView(analyticsManager: analyticsManager)
        case .models:
            ModelsTabView()
        case .history:
            HistoryTabView()
        case .billing:
            NavigationView {
                BillingView()
                    .environmentObject(themeManager)
                    .environmentObject(analyticsManager)
            }
        case .spendingLimits:
            // SpendingLimitsView()
            Text("Spending Limits - Coming Soon")
                .foregroundColor(.secondary)
        case .documents:
            DocumentsTabView()
        }
    }
    
    // MARK: - Sidebar
    private var sidebar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                // Sidebar Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: LocalizedStringResource("Dashboard", comment: "Dashboard view title")))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text(String(localized: LocalizedStringResource("Manage your Cription experience", comment: "Dashboard description")))
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Tab Buttons
                VStack(spacing: 8) {
                    ForEach(DashboardTab.allCases, id: \.self) { tab in
                        SidebarTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            onTap: {
                                selectedTab = tab
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSidebarVisible = false
                    }
                }
        )
    }
                }
                .padding(.horizontal, 12)
                
                Spacer()
            }
            .frame(width: 280)
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            .overlay(
                Rectangle()
                    .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    .frame(width: 1),
                alignment: .trailing
            )
            
            Spacer()
        }
        .offset(x: isSidebarVisible ? 0 : -280)
        .animation(.easeInOut(duration: 0.3), value: isSidebarVisible)
    }
    
    // MARK: - Sidebar Overlay
    private var sidebarOverlay: some View {
        Color.black.opacity(isSidebarVisible ? 0.3 : 0)
            .ignoresSafeArea()
            .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSidebarVisible = false
                    }
            }
            .animation(.easeInOut(duration: 0.3), value: isSidebarVisible)
    }
}

// MARK: - Sidebar Tab Button
struct SidebarTabButton: View {
    let tab: DashboardView.DashboardTab
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : (themeManager.isDarkMode ? .white : .black))
                    .frame(width: 20)
                
                Text(LocalizedStringKey(tab.rawValue))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : (themeManager.isDarkMode ? .white : .black))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.blue.opacity(0.2) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Documents Tab View
struct DocumentsTabView: View {
    var body: some View {
        VStack {
            Text(String(localized: LocalizedStringResource("Documents", comment: "Documents tab title")))
                .font(.title)
                .foregroundColor(.primary)
            
            Text(String(localized: LocalizedStringResource("Document management features coming soon", comment: "Coming soon message for document features")))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}




#Preview {
    DashboardView()
}
