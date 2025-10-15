//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// トークン計算ビュー
struct TokenCalculatorView: View {
    @StateObject private var tokenCalculationService = TokenCalculationService.shared
    @State private var inputText = ""
    @State private var showingDetailedStats = false
    @State private var isAnimating = false
    @State private var currentStats: TokenStats?
    
    // Platform-specific colors
    private var controlBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(.systemGray6)
        #endif
    }
    
    private var windowBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ヘッダー
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("1CA485"), .accentColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "function")
                                .font(.title3)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Token Calculator")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Analyze text tokens and costs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            inputText = ""
                            currentStats = nil
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(controlBackgroundColor)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isAnimating ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isAnimating)
                }
                
                // テキスト入力エリア
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Text Input")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !inputText.isEmpty {
                            Text("\(inputText.count) chars")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(controlBackgroundColor)
                                .cornerRadius(6)
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(controlBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        inputText.isEmpty ? 
                                        LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                                        LinearGradient(
                                            colors: [Color("1CA485").opacity(0.3), .accentColor.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        
                        if inputText.isEmpty {
                            Text("Enter text to analyze tokens and costs...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                        }
                        
                        TextEditor(text: $inputText)
                            .frame(minHeight: 140)
                            .padding(12)
                            .background(Color.clear)
                            .onChange(of: inputText) { _ in
                                Task {
                                    await calculateTokens()
                                }
                            }
                    }
                }
                
                // 言語情報とモデル情報
                if !inputText.isEmpty && currentStats != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Language Detection")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "globe")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentStats?.detectedLanguage.rawValue ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 8) {
                                    Text("Confidence:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(format: "%.0f%%", (currentStats?.languageConfidence ?? 0.0) * 100))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Spacer()
                            
                            // 信頼度インジケーター
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(controlBackgroundColor, lineWidth: 3)
                                        .frame(width: 24, height: 24)
                                    
                                    Circle()
                                        .trim(from: 0, to: currentStats?.languageConfidence ?? 0.0)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.green, .mint],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                        )
                                        .frame(width: 24, height: 24)
                                        .rotationEffect(.degrees(-90))
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(controlBackgroundColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.green.opacity(0.2), .mint.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        
                        // 音声とモデル情報（音声データがある場合）
                        if (currentStats?.audioDuration ?? 0) > 0 {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "waveform")
                                        .foregroundColor(.blue)
                                    Text("Audio Duration:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1fs (%.2fm)", currentStats?.audioDuration ?? 0, (currentStats?.audioDuration ?? 0) / 60.0))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Image(systemName: "cpu")
                                        .foregroundColor(.accentColor)
                                    Text("Model:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(currentStats?.selectedModel ?? "Unknown")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(controlBackgroundColor.opacity(0.5))
                            )
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
                
                // 基本統計
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        StatItem(
                            title: "Tokens",
                            value: "\(currentStats?.tokenCount ?? 0)",
                            icon: "number.circle.fill",
                            gradient: [Color("1CA485"), .cyan]
                        )
                        
                        StatItem(
                            title: "Characters",
                            value: "\(currentStats?.characterCount ?? 0)",
                            icon: "textformat",
                            gradient: [.green, .mint]
                        )
                        
                        StatItem(
                            title: "Words",
                            value: "\(currentStats?.wordCount ?? 0)",
                            icon: "text.word.spacing",
                            gradient: [.orange, .yellow]
                        )
                        
                        StatItem(
                            title: "Est. Cost",
                            value: String(format: "$%.4f", currentStats?.estimatedCost ?? 0.0),
                            icon: "dollarsign.circle.fill",
                            gradient: [.red, .pink]
                        )
                    }
                }
                
                // 詳細統計ボタン
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingDetailedStats = true
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.accentColor, Color("1CA485")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Text("View Detailed Statistics")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.accentColor, Color("1CA485")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(isAnimating ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isAnimating)
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [
                    windowBackgroundColor,
                    controlBackgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showingDetailedStats) {
            if let stats = currentStats {
                DetailedStatsView(stats: stats)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateTokens() async {
        guard !inputText.isEmpty else {
            currentStats = nil
            return
        }
        
        await tokenCalculationService.calculateTokensForTranCription(
            finalText: inputText,
            duration: 0.0,
            model: "gpt-4o-transcribe",
            isTranslation: false
        )
        
        currentStats = tokenCalculationService.getLastResult()
    }
}

/// 統計アイテム
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    @State private var isAnimating = false
    
    // Platform-specific colors
    private var windowBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 2)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(windowBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double.random(in: 0...0.5))) {
                isAnimating = true
            }
        }
    }
}

/// 詳細統計ビュー
struct DetailedStatsView: View {
    let stats: TokenStats
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    
    // Platform-specific colors
    private var controlBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(.systemGray6)
        #endif
    }
    
    private var windowBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // ヘッダー
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.accentColor, Color("1CA485")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Detailed Statistics")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Comprehensive token analysis")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // 言語情報
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Language Detection", icon: "globe", gradient: [.green, .mint])
                        
                        VStack(spacing: 16) {
                            EnhancedDetailRow(
                                title: "Detected Language",
                                value: stats.detectedLanguage.rawValue,
                                icon: "textformat.abc",
                                gradient: [.green, .mint]
                            )
                            
                            EnhancedDetailRow(
                                title: "Confidence",
                                value: String(format: "%.1f%%", stats.languageConfidence * 100),
                                icon: "checkmark.circle",
                                gradient: [Color("1CA485"), .cyan]
                            )
                            
                            EnhancedDetailRow(
                                title: "Token Ratio",
                                value: String(format: "1:%.1f", stats.detectedLanguage.tokenRatio),
                                icon: "arrow.left.arrow.right",
                                gradient: [.orange, .yellow]
                            )
                        }
                    }
                    
                    // 基本統計
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Basic Statistics", icon: "number.circle", gradient: [Color("1CA485"), .accentColor])
                        
                        VStack(spacing: 16) {
                            EnhancedDetailRow(
                                title: "Total Tokens",
                                value: "\(stats.tokenCount)",
                                icon: "number.circle.fill",
                                gradient: [Color("1CA485"), .cyan]
                            )
                            
                            EnhancedDetailRow(
                                title: "Total Characters",
                                value: "\(stats.characterCount)",
                                icon: "textformat",
                                gradient: [.green, .mint]
                            )
                            
                            EnhancedDetailRow(
                                title: "Total Words",
                                value: "\(stats.wordCount)",
                                icon: "text.word.spacing",
                                gradient: [.orange, .yellow]
                            )
                            
                            EnhancedDetailRow(
                                title: "Estimated Cost",
                                value: String(format: "$%.4f", stats.estimatedCost),
                                icon: "dollarsign.circle.fill",
                                gradient: [.red, .pink]
                            )
                        }
                    }
                    
                    // 平均統計
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Average Statistics", icon: "chart.line.uptrend.xyaxis", gradient: [.accentColor, .pink])
                        
                        VStack(spacing: 16) {
                            EnhancedDetailRow(
                                title: "Tokens per Word",
                                value: String(format: "%.2f", stats.averageTokensPerWord),
                                icon: "divide.circle",
                                gradient: [.indigo, .accentColor]
                            )
                            
                            EnhancedDetailRow(
                                title: "Characters per Token",
                                value: String(format: "%.2f", stats.averageCharactersPerToken),
                                icon: "equal.circle",
                                gradient: [.teal, .cyan]
                            )
                        }
                    }
                    
                    // 料金情報
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Pricing Information", icon: "dollarsign.circle", gradient: [.red, .orange])
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.red, .orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Text(stats.audioDuration > 0 ? "Audio Transcription Pricing (2025)" : "Text Model Pricing (Reference)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                if stats.audioDuration > 0 {
                                    // 音声文字起こし料金
                                    PricingRow(label: "whisper-1", price: "$0.006", unit: "per minute", color: .blue)
                                    PricingRow(label: "gpt-4o-transcribe", price: "$0.006", unit: "per minute", color: Color("1CA485"))
                                    PricingRow(label: "gpt-4o-mini-transcribe", price: "$0.003", unit: "per minute", color: .green)
                                    
                                    if stats.audioDuration > 0 {
                                        Divider()
                                        HStack {
                                            Text("Current Calculation:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(String(format: "%.2f", stats.audioDuration / 60.0)) minutes × model rate")
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                } else {
                                    // テキストモデル料金（参考）
                                    PricingRow(label: "GPT-4o Input", price: "$0.0025", unit: "per 1K tokens", color: .green)
                                    PricingRow(label: "GPT-4o Output", price: "$0.010", unit: "per 1K tokens", color: Color("1CA485"))
                                    
                                    Text("Note: For accurate audio transcription costs, use with audio duration data.")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(controlBackgroundColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.red.opacity(0.2), .orange.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                }
                .padding(24)
            }
            .background(
                LinearGradient(
                    colors: [
                        windowBackgroundColor,
                        controlBackgroundColor.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

/// セクションヘッダー
struct SectionHeader: View {
    let title: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

/// 拡張詳細行
struct EnhancedDetailRow: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    @State private var isAnimating = false
    
    // Platform-specific colors
    private var windowBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 2, x: 0, y: 1)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(windowBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double.random(in: 0...0.3))) {
                isAnimating = true
            }
        }
    }
}

/// 料金行
struct PricingRow: View {
    let label: String
    let price: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(price)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    TokenCalculatorView()
        .padding()
}
