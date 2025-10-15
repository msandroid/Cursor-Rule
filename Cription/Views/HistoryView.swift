//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI


struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var historyItems: [HistoryItem] = []
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    @State private var selectedItems: Set<UUID> = []
    @State private var isEditing = false
    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedItem: HistoryItem? = nil
    @State private var showingDetailView = false
    @State private var editingItem: HistoryItem? = nil
    @State private var editedText: String = ""
    @State private var showingEditView = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }
    
    var filteredItems: [HistoryItem] {
        var items = historyItems
        
        // Apply time filter
        switch selectedFilter {
        case .all:
            break
        case .today:
            items = items.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .week:
            items = items.filter { Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear) }
        case .month:
            items = items.filter { Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .month) }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        
        return items.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                (themeManager.isDarkMode ? Color.black : Color.white).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !historyItems.isEmpty {
                        // Search Bar
                        if !searchText.isEmpty || isEditing {
                            HStack {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                                    
                                    TextField(String(localized: LocalizedStringResource("Search history...", comment: "Search history placeholder")), text: $searchText)
                                        .textFieldStyle(.plain)
                                        .foregroundStyle(themeManager.isDarkMode ? .white : .black)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background((themeManager.isDarkMode ? Color.white : Color.black).opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                                
                                if isEditing {
                                    Button(String(localized: LocalizedStringResource("Cancel", comment: "Cancel button"))) {
                                        isEditing = false
                                        selectedItems.removeAll()
                                    }
                                    .foregroundStyle(themeManager.isDarkMode ? .white : .black)
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                        
                        // Filter Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                                    Button(action: {
                                        selectedFilter = filter
                                    }) {
                                        Text(filter.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedFilter == filter ? Color("006337") : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 6)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 8)
                        
                        // Results Count
                        HStack {
                            Text(String(localized: LocalizedStringResource("\(filteredItems.count) items", comment: "Items count format")))
                                .font(.caption)
                                .foregroundStyle(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                
                    if filteredItems.isEmpty && (!searchText.isEmpty || selectedFilter != .all) {
                        // No search results or filtered results
                        VStack(spacing: 20) {
                            Image(systemName: searchText.isEmpty ? "calendar" : "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.7))
                            
                            VStack(spacing: 8) {
                                Text(searchText.isEmpty ? String(localized: LocalizedStringResource("No Items Found", comment: "No items found message")) : String(localized: LocalizedStringResource("No Results", comment: "No results message")))
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                
                                Text(searchText.isEmpty ? "No items found for this period" : "No items match your search")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if historyItems.isEmpty {
                        // Empty state
                        VStack(spacing: 24) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 80))
                                .foregroundStyle(.white.opacity(0.7))
                                .symbolEffect(.pulse, isActive: true)
                            
                            VStack(spacing: 12) {
                                Text(String(localized: LocalizedStringResource("No History", comment: "No history message")))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                
                                Text(String(localized: LocalizedStringResource("Voice recognition history will appear here", comment: "No history deCription")))
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // History list with performance optimizations
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredItems, id: \.id) { item in
                                    HistoryItemRow(
                                        item: item,
                                        isSelected: selectedItems.contains(item.id),
                                        isEditing: isEditing,
                                        onTap: {
                                            if isEditing {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    if selectedItems.contains(item.id) {
                                                        selectedItems.remove(item.id)
                                                    } else {
                                                        selectedItems.insert(item.id)
                                                    }
                                                }
                                            } else {
                                                selectedItem = item
                                                showingDetailView = true
                                            }
                                        },
                                        onEdit: {
                                            editingItem = item
                                            editedText = item.text
                                            showingEditView = true
                                        }
                                    )
                                    .id(item.id) // Ensure proper view identity
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationTitle(String(localized: LocalizedStringResource("History", comment: "History view title")))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .toolbar {
                if !historyItems.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 8) {
                            if isEditing {
                                Button(String(localized: LocalizedStringResource("Delete", comment: "Delete button"))) {
                                    deleteSelectedItems()
                                }
                                .foregroundStyle(.red)
                                .disabled(selectedItems.isEmpty)
                            } else {
                                Button(String(localized: LocalizedStringResource("Edit", comment: "Edit button"))) {
                                    isEditing = true
                                }
                                .foregroundStyle(.white)
                                .buttonStyle(.bordered)
                                
                                Button(String(localized: LocalizedStringResource("Delete All", comment: "Delete all button"))) {
                                    showingDeleteAlert = true
                                }
                                .foregroundStyle(.red)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
        }
        .alert(String(localized: LocalizedStringResource("Delete All", comment: "Delete all button")), isPresented: $showingDeleteAlert) {
            Button(String(localized: LocalizedStringResource("Cancel", comment: "Cancel button")), role: .cancel) { }
            Button(String(localized: LocalizedStringResource("Delete", comment: "Delete button")), role: .destructive) {
                deleteAllItems()
            }
        } message: {
            Text(String(localized: LocalizedStringResource("Are you sure you want to delete all history items?", comment: "Delete confirmation message")))
        }
        .onAppear {
            loadHistory()
        }
        .refreshable {
            loadHistory()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingDetailView) {
            if let item = selectedItem {
                HistoryDetailView(item: item)
            }
        }
        .sheet(isPresented: $showingEditView) {
            if let item = editingItem {
                HistoryEditView(
                    item: item,
                    editedText: $editedText,
                    onSave: { newText in
                        updateHistoryItem(item, with: newText)
                        showingEditView = false
                    },
                    onCancel: {
                        showingEditView = false
                    }
                )
            }
        }
    }
    
    private func loadHistory() {
        // Load actual history data from UserDefaults with performance optimization and error handling
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if let data = UserDefaults.standard.data(forKey: "HistoryItems") {
                    let items = try JSONDecoder().decode([HistoryItem].self, from: data)
                    DispatchQueue.main.async {
                        self.historyItems = items
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.historyItems = []
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load history: \(error.localizedDescription)"
                    self.historyItems = []
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveHistory() {
        // Save history data to UserDefaults with performance optimization and error handling
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try JSONEncoder().encode(self.historyItems)
                UserDefaults.standard.set(data, forKey: "HistoryItems")
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save history: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        historyItems.remove(atOffsets: offsets)
        saveHistory()
    }
    
    private func deleteAllItems() {
        historyItems.removeAll()
        saveHistory()
    }
    
    private func deleteSelectedItems() {
        historyItems.removeAll { selectedItems.contains($0.id) }
        selectedItems.removeAll()
        isEditing = false
        saveHistory()
    }
    
    private func updateHistoryItem(_ item: HistoryItem, with newText: String) {
        if let index = historyItems.firstIndex(where: { $0.id == item.id }) {
            let updatedItem = HistoryItem(
                id: item.id,
                text: newText,
                timestamp: item.timestamp,
                duration: item.duration,
                language: item.language,
                model: item.model,
                accuracy: item.accuracy
            )
            historyItems[index] = updatedItem
            saveHistory()
        }
    }
    
    // Public function to add new history items
    func addHistoryItem(text: String, duration: Double, language: String = "auto", model: String = "", accuracy: Double? = nil) {
        let newItem = HistoryItem(
            text: text,
            timestamp: Date(),
            duration: duration,
            language: language,
            model: model,
            accuracy: accuracy
        )
        historyItems.insert(newItem, at: 0) // Add to beginning of list
        saveHistory()
        
        // Update analytics
        let finalAccuracy = accuracy ?? 0.95 // Default accuracy if not provided
        analyticsManager.recordTranCription(duration: duration, language: language, accuracy: finalAccuracy, text: text, model: model)
    }
}

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let duration: Double
    let language: String
    let model: String
    let accuracy: Double?
    
    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), duration: Double, language: String = "auto", model: String = "", accuracy: Double? = nil) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.duration = duration
        self.language = language
        self.model = model
        self.accuracy = accuracy
    }
}

struct HistoryItemRow: View {
    let item: HistoryItem
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    @State private var isPressed = false
    @StateObject private var themeManager = ThemeManager.shared
    
    private var selectionForegroundColor: Color {
        if isSelected {
            return .primary
        } else {
            return themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7)
        }
    }
    
    private var itemIcon: String {
        // Determine icon based on content type or model
        if item.model.contains("whisper") || item.model.contains("transcription") {
            return "waveform"
        } else {
            return "music.note"
        }
    }
    
    private var iconBackgroundColor: Color {
        if item.model.contains("whisper") || item.model.contains("transcription") {
            return Color.blue.opacity(0.8)
        } else {
            return Color.green.opacity(0.8)
        }
    }
    
    private var formattedDuration: String {
        let minutes = Int(item.duration) / 60
        let seconds = Int(item.duration) % 60
        if minutes > 0 {
            return "\(minutes)m\(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if isEditing {
                Button(action: onTap) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(selectionForegroundColor)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .buttonStyle(.plain)
            }
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: itemIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Date and Time
                Text(item.timestamp, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                
                // Title or Duration
                Text(item.text.isEmpty ? formattedDuration : item.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(themeManager.isDarkMode ? .white : .black)
                    .lineLimit(2)
                
                // Metadata Row
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                        
                        Text(formattedDuration)
                            .font(.caption2)
                            .foregroundStyle(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // User profile icon
                    Image(systemName: "person.circle")
                        .font(.caption2)
                        .foregroundStyle(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                }
            }
            
            if !isEditing {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onTap) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color("006337") : (themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1)), lineWidth: isSelected ? 2 : 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            if !isEditing {
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action if needed
        }
    }
}

struct HistoryDetailView: View {
    let item: HistoryItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    tranCriptionSection
                    metadataSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(String(localized: LocalizedStringResource("History Detail", comment: "History detail view title")))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showingShareSheet) {
            shareSheet
        }
        #endif
    }
    
    private var tranCriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: LocalizedStringResource("TranCription", comment: "TranCription label")))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Text(item.text)
                .font(.body)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .textSelection(.enabled)
                .padding(16)
                .background(tranCriptionBackground)
        }
    }
    
    private var tranCriptionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(themeManager.isDarkMode ? Color.black : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: LocalizedStringResource("Details", comment: "Details label")))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            VStack(spacing: 12) {
                DetailRow(
                    icon: "clock",
                    title: "Date & Time",
                    value: item.timestamp.formatted(date: .abbreviated, time: .shortened)
                )
                
                DetailRow(
                    icon: "waveform",
                    title: "Duration",
                    value: "\(String(format: "%.1f", item.duration))s"
                )
                
                DetailRow(
                    icon: "cpu",
                    title: "Model",
                    value: item.model
                )
            }
            .padding(16)
            .background(metadataBackground)
        }
    }
    
    private var metadataBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(themeManager.isDarkMode ? Color.black : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: {
                    #if os(iOS)
                    UIPasteboard.general.string = item.text
                    #elseif os(macOS)
                    NSPasteboard.general.setString(item.text, forType: .string)
                    #endif
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text(String(localized: LocalizedStringResource("Copy", comment: "Copy button")))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(String(localized: LocalizedStringResource("Share", comment: "Share button")))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    #if os(iOS)
    private var shareSheet: some View {
        ShareSheet(items: [item.text])
    }
    #endif
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
        }
    }
}

struct HistoryEditView: View {
    let item: HistoryItem
    @Binding var editedText: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: LocalizedStringResource("Edit Text", comment: "Edit text title")))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    TextEditor(text: $editedText)
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.isDarkMode ? Color.black : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .focused($isTextFieldFocused)
                        .frame(minHeight: 200)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(String(localized: LocalizedStringResource("Edit History", comment: "Edit history title")))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: LocalizedStringResource("Cancel", comment: "Cancel button"))) {
                        onCancel()
                    }
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: LocalizedStringResource("Save", comment: "Save button"))) {
                        onSave(editedText)
                    }
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    HistoryView()
}

