import SwiftUI

struct SharedTextsView: View {
    @Binding var sharedTexts: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedText: String = ""
    @State private var showTextEditor: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if sharedTexts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("共有されたテキストがありません")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("他のアプリからScribeにテキストを共有してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(Array(sharedTexts.enumerated()), id: \.offset) { index, text in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(text)
                                    .font(.body)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                
                                HStack {
                                    Spacer()
                                    Text("\(index + 1)番目の共有テキスト")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .onTapGesture {
                                selectedText = text
                                showTextEditor = true
                            }
                        }
                        .onDelete(perform: deleteText)
                    }
                }
            }
            .navigationTitle("共有されたテキスト")
            #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                if !sharedTexts.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("すべて削除") {
                            clearAllTexts()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showTextEditor) {
            TextEditorView(
                text: $selectedText,
                onSave: { newText in
                    if let index = sharedTexts.firstIndex(of: selectedText) {
                        sharedTexts[index] = newText
                        saveSharedTexts()
                    }
                }
            )
        }
    }
    
    private func deleteText(at offsets: IndexSet) {
        sharedTexts.remove(atOffsets: offsets)
        saveSharedTexts()
    }
    
    private func clearAllTexts() {
        sharedTexts.removeAll()
        saveSharedTexts()
    }
    
    private func saveSharedTexts() {
        if let sharedDefaults = UserDefaults(suiteName: "group.scribe.ai") {
            sharedDefaults.set(sharedTexts, forKey: "sharedTexts")
        }
    }
}

struct TextEditorView: View {
    @Binding var text: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editedText: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $editedText)
                    .font(.body)
                    .padding()
            }
            .navigationTitle("テキスト編集")
            #if canImport(UIKit)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("保存") {
                        onSave(editedText)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            editedText = text
        }
    }
}
