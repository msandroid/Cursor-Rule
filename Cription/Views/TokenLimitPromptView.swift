//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import SwiftUI
import StoreKit

struct TokenLimitPromptView: View {
    @ObservedObject var subscriptionManager = SubCriptionManager.shared
    @ObservedObject var modelPurchaseManager = ModelPurchaseManager.shared
    @State private var showingSubscriptionSheet = false
    @State private var showingModelPurchaseSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            // アイコン
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            // タイトル
            Text("トークン制限に達しました")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // 説明文
            VStack(spacing: 8) {
                Text("今月のトークン使用量が上限に達しました。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Text("継続してご利用いただくには、以下のいずれかを選択してください：")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            
            // 使用量表示
            VStack(spacing: 4) {
                Text("使用量: \(subscriptionManager.currentTokenUsage) / \(subscriptionManager.tokenLimit) トークン")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: subscriptionManager.getUsagePercentage())
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
            }
            .padding(.horizontal)
            
            // オプションボタン
            VStack(spacing: 12) {
                // サブスクリプション購入ボタン
                if !subscriptionManager.isSubCriptiond {
                    Button(action: {
                        showingSubscriptionSheet = true
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("プレミアムプランにアップグレード")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                // モデル購入ボタン
                Button(action: {
                    showingModelPurchaseSheet = true
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("追加モデルを購入")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // キャンセルボタン
                Button(action: {
                    tokenLimitManager.dismissUpgradePrompt()
                }) {
                    Text("後で")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .sheet(isPresented: $showingSubscriptionSheet) {
            CriptionPlusView()
        }
        .sheet(isPresented: $showingModelPurchaseSheet) {
            ModelsTabView()
                .environmentObject(WhisperModelManager())
        }
    }
}

struct ModelPurchasePromptView: View {
    @ObservedObject var subscriptionManager = SubCriptionManager.shared
    @ObservedObject var modelPurchaseManager = ModelPurchaseManager.shared
    @State private var showingModelPurchaseSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            // アイコン
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            // タイトル
            Text("追加モデルで制限を解除")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // 説明文
            VStack(spacing: 8) {
                Text("プレミアムプランをご利用中ですが、")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Text("より多くのトークンを使用するには追加モデルの購入をお勧めします。")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            
            // 使用量表示
            VStack(spacing: 4) {
                Text("使用量: \(subscriptionManager.currentTokenUsage) / \(subscriptionManager.tokenLimit) トークン")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: subscriptionManager.getUsagePercentage())
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            .padding(.horizontal)
            
            // オプションボタン
            VStack(spacing: 12) {
                // モデル購入ボタン
                Button(action: {
                    showingModelPurchaseSheet = true
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("モデルを購入")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // キャンセルボタン
                Button(action: {
                    tokenLimitManager.dismissModelPurchasePrompt()
                }) {
                    Text("後で")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .sheet(isPresented: $showingModelPurchaseSheet) {
            ModelsTabView()
                .environmentObject(WhisperModelManager())
        }
    }
}

// プレビュー
struct TokenLimitPromptView_Previews: PreviewProvider {
    static var previews: some View {
        TokenLimitPromptView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

struct ModelPurchasePromptView_Previews: PreviewProvider {
    static var previews: some View {
        ModelPurchasePromptView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
