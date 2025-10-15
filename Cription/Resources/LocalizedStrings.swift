//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import Foundation
import SwiftUI

/// Modern localization using SwiftUI's LocalizedStringResource
struct LocalizedStringsNew {
    
    // MARK: - Common
    struct Common {
        static let cancel = LocalizedStringResource("Cancel", comment: "Cancel button")
        static let delete = LocalizedStringResource("Delete", comment: "Delete button")
        static let done = LocalizedStringResource("Done", comment: "Done button")
        static let ok = LocalizedStringResource("OK", comment: "OK button")
        static let save = LocalizedStringResource("Save", comment: "Save button")
        static let loading = LocalizedStringResource("Loading...", comment: "Loading message")
    }
    
    // MARK: - History View
    struct History {
        static let title = LocalizedStringResource("History", comment: "History view title")
        static let noHistory = LocalizedStringResource("No History", comment: "No history message")
        static let noHistoryDeCription = LocalizedStringResource("Voice recognition history will appear here", comment: "No history deCription")
        static let close = LocalizedStringResource("Close", comment: "Close button")
        static let deleteAll = LocalizedStringResource("Delete All", comment: "Delete all button")
        static let seconds = LocalizedStringResource("sec", comment: "Seconds abbreviation")
        static let itemsCount = LocalizedStringResource("%d items", comment: "Items count format")
        static let deleteConfirmation = LocalizedStringResource("Are you sure you want to delete all history items?", comment: "Delete confirmation message")
        static let tranCription = LocalizedStringResource("TranCription", comment: "TranCription label")
        static let details = LocalizedStringResource("Details", comment: "Details label")
        static let copy = LocalizedStringResource("Copy", comment: "Copy button")
        static let share = LocalizedStringResource("Share", comment: "Share button")
    }
    
    // MARK: - Settings View
    struct Settings {
        static let title = LocalizedStringResource("Settings", comment: "Settings view title")
        static let done = LocalizedStringResource("Done", comment: "Done button")
        static let displayLanguage = LocalizedStringResource("Display Language", comment: "Display language setting")
        static let uiLanguage = LocalizedStringResource("UI Language", comment: "UI language setting")
        static let autoDetectSystemLanguage = LocalizedStringResource("Auto-detect system language", comment: "Auto-detect system language setting")
        static let currentModel = LocalizedStringResource("Current Model", comment: "Current model label")
        static let noModelSelected = LocalizedStringResource("No model selected", comment: "No model selected message")
        static let change = LocalizedStringResource("Change", comment: "Change button")
        static let delete = LocalizedStringResource("Delete", comment: "Delete button")
        static let repair = LocalizedStringResource("Repair", comment: "Repair button")
        static let openFolder = LocalizedStringResource("Open Folder", comment: "Open folder button")
        static let task = LocalizedStringResource("Task", comment: "Task setting")
        static let translateWarning = LocalizedStringResource("Warning: Translate mode will convert speech to English", comment: "Translate mode warning")
        static let tranCriptionDeCription = LocalizedStringResource("TranCription mode: Speech will be converted to text in the original language", comment: "TranCription mode deCription")
        static let autoDetectDeCription = LocalizedStringResource("Auto-detect mode: Language will be automatically detected from audio", comment: "Auto-detect mode deCription")
        static let sourceLanguage = LocalizedStringResource("Source Language", comment: "Source language setting")
        static let selectLanguageDeCription = LocalizedStringResource("Select the language for speech recognition", comment: "Select language deCription")
        static let textFontType = LocalizedStringResource("Text Font Type", comment: "Text font type setting")
        static let selectFontDeCription = LocalizedStringResource("Select the font family for speech-to-text display", comment: "Select font deCription")
        static let preview = LocalizedStringResource("Preview", comment: "Preview label")
        static let previewDeCription = LocalizedStringResource("This is how your output text will look", comment: "Preview deCription")
        static let sampleTextFont = LocalizedStringResource("Sample text in %@", comment: "Sample text format")
        
        // Model Settings
        static let modelSettings = LocalizedStringResource("Model Settings", comment: "Model settings section")
        static let loadModel = LocalizedStringResource("Load Model", comment: "Load model button")
        static let deleteModel = LocalizedStringResource("Delete Model", comment: "Delete model button")
        static let computeUnits = LocalizedStringResource("Compute Units", comment: "Compute units setting")
        static let audioEncoder = LocalizedStringResource("Audio Encoder", comment: "Audio encoder setting")
        static let textDecoder = LocalizedStringResource("Text Decoder", comment: "Text decoder setting")
        static let cpu = LocalizedStringResource("CPU", comment: "CPU option")
        static let gpu = LocalizedStringResource("GPU", comment: "GPU option")
        static let neuralEngine = LocalizedStringResource("Neural Engine", comment: "Neural Engine option")
        
        // Audio Settings
        static let audioSettings = LocalizedStringResource("Audio Settings", comment: "Audio settings section")
        
        // Advanced Settings
        static let advancedSettings = LocalizedStringResource("Advanced Settings", comment: "Advanced settings section")
        static let showTimestamps = LocalizedStringResource("Show Timestamps", comment: "Show timestamps setting")
        static let specialCharacters = LocalizedStringResource("Special Characters", comment: "Special characters setting")
        static let showDecoderPreview = LocalizedStringResource("Show Decoder Preview", comment: "Show decoder preview setting")
        static let promptPrefill = LocalizedStringResource("Prompt Prefill", comment: "Prompt prefill setting")
        static let cachePrefill = LocalizedStringResource("Cache Prefill", comment: "Cache prefill setting")
        static let chunkingStrategy = LocalizedStringResource("Chunking Strategy", comment: "Chunking strategy setting")
        static let workers = LocalizedStringResource("Workers", comment: "Workers setting")
        static let startingTemperature = LocalizedStringResource("Starting Temperature", comment: "Starting temperature setting")
        static let maxFallbackCount = LocalizedStringResource("Max Fallback Count", comment: "Max fallback count setting")
        static let compressionCheckTokens = LocalizedStringResource("Compression Check Tokens", comment: "Compression check tokens setting")
        static let maxTokensPerLoop = LocalizedStringResource("Max Tokens Per Loop", comment: "Max tokens per loop setting")
        static let silenceThreshold = LocalizedStringResource("Silence Threshold", comment: "Silence threshold setting")
        static let realtimeDelayInterval = LocalizedStringResource("Realtime Delay Interval", comment: "Realtime delay interval setting")
        
        // Experimental Settings
        static let experimentalSettings = LocalizedStringResource("Experimental Settings", comment: "Experimental settings section")
        static let eagerStreamingMode = LocalizedStringResource("Eager Streaming Mode", comment: "Eager streaming mode setting")
        static let tokenConfirmations = LocalizedStringResource("Token Confirmations", comment: "Token confirmations setting")
        
        // Chunking Strategy Options
        static let none = LocalizedStringResource("None", comment: "None option")
        static let vad = LocalizedStringResource("VAD", comment: "VAD option")
        
        // Model States
        static let loaded = LocalizedStringResource("Loaded", comment: "Loaded state")
        static let unloaded = LocalizedStringResource("Unloaded", comment: "Unloaded state")
        static let loading = LocalizedStringResource("Loading", comment: "Loading state")
        static let prewarming = LocalizedStringResource("Prewarming", comment: "Prewarming state")
        static let unloading = LocalizedStringResource("Unloading", comment: "Unloading state")
        static let prewarmed = LocalizedStringResource("Prewarmed", comment: "Prewarmed state")
        static let downloading = LocalizedStringResource("Downloading", comment: "Downloading state")
        static let downloaded = LocalizedStringResource("Downloaded", comment: "Downloaded state")
        static let selectLanguage = LocalizedStringResource("Select Language", comment: "Select language button")
        static let systemFont = LocalizedStringResource("System", comment: "System font option")
        static let textFontSize = LocalizedStringResource("Text Font Size", comment: "Text font size setting")
        static let fontSizeInfo = LocalizedStringResource("Adjust the font size for text display. Larger values make text easier to read.", comment: "Font size info")
    }
    
    // MARK: - Languages
    struct Language {
        static let english = LocalizedStringResource("English", comment: "English language")
        static let chinese = LocalizedStringResource("Chinese", comment: "Chinese language")
        static let german = LocalizedStringResource("German", comment: "German language")
        static let spanish = LocalizedStringResource("Spanish", comment: "Spanish language")
        static let russian = LocalizedStringResource("Russian", comment: "Russian language")
        static let korean = LocalizedStringResource("Korean", comment: "Korean language")
        static let french = LocalizedStringResource("French", comment: "French language")
        static let japanese = LocalizedStringResource("Japanese", comment: "Japanese language")
        static let portuguese = LocalizedStringResource("Portuguese", comment: "Portuguese language")
        static let turkish = LocalizedStringResource("Turkish", comment: "Turkish language")
        static let polish = LocalizedStringResource("Polish", comment: "Polish language")
        static let catalan = LocalizedStringResource("Catalan", comment: "Catalan language")
        static let dutch = LocalizedStringResource("Dutch", comment: "Dutch language")
        static let arabic = LocalizedStringResource("Arabic", comment: "Arabic language")
        static let swedish = LocalizedStringResource("Swedish", comment: "Swedish language")
        static let italian = LocalizedStringResource("Italian", comment: "Italian language")
        static let indonesian = LocalizedStringResource("Indonesian", comment: "Indonesian language")
        static let hindi = LocalizedStringResource("Hindi", comment: "Hindi language")
        static let finnish = LocalizedStringResource("Finnish", comment: "Finnish language")
        static let vietnamese = LocalizedStringResource("Vietnamese", comment: "Vietnamese language")
        static let hebrew = LocalizedStringResource("Hebrew", comment: "Hebrew language")
        static let ukrainian = LocalizedStringResource("Ukrainian", comment: "Ukrainian language")
        static let greek = LocalizedStringResource("Greek", comment: "Greek language")
        static let malay = LocalizedStringResource("Malay", comment: "Malay language")
        static let czech = LocalizedStringResource("Czech", comment: "Czech language")
        static let romanian = LocalizedStringResource("Romanian", comment: "Romanian language")
        static let danish = LocalizedStringResource("Danish", comment: "Danish language")
        static let hungarian = LocalizedStringResource("Hungarian", comment: "Hungarian language")
        static let tamil = LocalizedStringResource("Tamil", comment: "Tamil language")
        static let norwegian = LocalizedStringResource("Norwegian", comment: "Norwegian language")
        static let thai = LocalizedStringResource("Thai", comment: "Thai language")
        static let urdu = LocalizedStringResource("Urdu", comment: "Urdu language")
        static let croatian = LocalizedStringResource("Croatian", comment: "Croatian language")
        static let bulgarian = LocalizedStringResource("Bulgarian", comment: "Bulgarian language")
        static let lithuanian = LocalizedStringResource("Lithuanian", comment: "Lithuanian language")
        static let latin = LocalizedStringResource("Latin", comment: "Latin language")
        static let maori = LocalizedStringResource("Maori", comment: "Maori language")
        static let malayalam = LocalizedStringResource("Malayalam", comment: "Malayalam language")
        static let welsh = LocalizedStringResource("Welsh", comment: "Welsh language")
        static let slovak = LocalizedStringResource("Slovak", comment: "Slovak language")
        static let telugu = LocalizedStringResource("Telugu", comment: "Telugu language")
        static let persian = LocalizedStringResource("Persian", comment: "Persian language")
        static let latvian = LocalizedStringResource("Latvian", comment: "Latvian language")
        static let bengali = LocalizedStringResource("Bengali", comment: "Bengali language")
        static let serbian = LocalizedStringResource("Serbian", comment: "Serbian language")
        static let azerbaijani = LocalizedStringResource("Azerbaijani", comment: "Azerbaijani language")
        static let slovenian = LocalizedStringResource("Slovenian", comment: "Slovenian language")
        static let kannada = LocalizedStringResource("Kannada", comment: "Kannada language")
        static let estonian = LocalizedStringResource("Estonian", comment: "Estonian language")
        static let macedonian = LocalizedStringResource("Macedonian", comment: "Macedonian language")
        static let breton = LocalizedStringResource("Breton", comment: "Breton language")
        static let basque = LocalizedStringResource("Basque", comment: "Basque language")
        static let icelandic = LocalizedStringResource("Icelandic", comment: "Icelandic language")
        static let armenian = LocalizedStringResource("Armenian", comment: "Armenian language")
        static let nepali = LocalizedStringResource("Nepali", comment: "Nepali language")
        static let mongolian = LocalizedStringResource("Mongolian", comment: "Mongolian language")
        static let bosnian = LocalizedStringResource("Bosnian", comment: "Bosnian language")
        static let kazakh = LocalizedStringResource("Kazakh", comment: "Kazakh language")
        static let albanian = LocalizedStringResource("Albanian", comment: "Albanian language")
        static let swahili = LocalizedStringResource("Swahili", comment: "Swahili language")
        static let galician = LocalizedStringResource("Galician", comment: "Galician language")
        static let marathi = LocalizedStringResource("Marathi", comment: "Marathi language")
        static let punjabi = LocalizedStringResource("Punjabi", comment: "Punjabi language")
        static let sinhala = LocalizedStringResource("Sinhala", comment: "Sinhala language")
        static let khmer = LocalizedStringResource("Khmer", comment: "Khmer language")
        static let shona = LocalizedStringResource("Shona", comment: "Shona language")
        static let yoruba = LocalizedStringResource("Yoruba", comment: "Yoruba language")
        static let somali = LocalizedStringResource("Somali", comment: "Somali language")
        static let afrikaans = LocalizedStringResource("Afrikaans", comment: "Afrikaans language")
        static let occitan = LocalizedStringResource("Occitan", comment: "Occitan language")
        static let georgian = LocalizedStringResource("Georgian", comment: "Georgian language")
        static let belarusian = LocalizedStringResource("Belarusian", comment: "Belarusian language")
        static let tajik = LocalizedStringResource("Tajik", comment: "Tajik language")
        static let sindhi = LocalizedStringResource("Sindhi", comment: "Sindhi language")
        static let gujarati = LocalizedStringResource("Gujarati", comment: "Gujarati language")
        static let amharic = LocalizedStringResource("Amharic", comment: "Amharic language")
        static let yiddish = LocalizedStringResource("Yiddish", comment: "Yiddish language")
        static let lao = LocalizedStringResource("Lao", comment: "Lao language")
        static let uzbek = LocalizedStringResource("Uzbek", comment: "Uzbek language")
        static let faroese = LocalizedStringResource("Faroese", comment: "Faroese language")
        static let haitianCreole = LocalizedStringResource("Haitian Creole", comment: "Haitian Creole language")
        static let pashto = LocalizedStringResource("Pashto", comment: "Pashto language")
        static let turkmen = LocalizedStringResource("Turkmen", comment: "Turkmen language")
        static let nynorsk = LocalizedStringResource("Nynorsk", comment: "Nynorsk language")
        static let maltese = LocalizedStringResource("Maltese", comment: "Maltese language")
        static let sanskrit = LocalizedStringResource("Sanskrit", comment: "Sanskrit language")
        static let luxembourgish = LocalizedStringResource("Luxembourgish", comment: "Luxembourgish language")
        static let myanmar = LocalizedStringResource("Myanmar", comment: "Myanmar language")
        static let tibetan = LocalizedStringResource("Tibetan", comment: "Tibetan language")
        static let tagalog = LocalizedStringResource("Tagalog", comment: "Tagalog language")
        static let malagasy = LocalizedStringResource("Malagasy", comment: "Malagasy language")
        static let assamese = LocalizedStringResource("Assamese", comment: "Assamese language")
        static let tatar = LocalizedStringResource("Tatar", comment: "Tatar language")
        static let hawaiian = LocalizedStringResource("Hawaiian", comment: "Hawaiian language")
        static let lingala = LocalizedStringResource("Lingala", comment: "Lingala language")
        static let hausa = LocalizedStringResource("Hausa", comment: "Hausa language")
        static let bashkir = LocalizedStringResource("Bashkir", comment: "Bashkir language")
        static let javanese = LocalizedStringResource("Javanese", comment: "Javanese language")
        static let sundanese = LocalizedStringResource("Sundanese", comment: "Sundanese language")
        static let cantonese = LocalizedStringResource("Cantonese", comment: "Cantonese language")
    }
    
    // MARK: - Dashboard View
    struct Dashboard {
        static let Cription = LocalizedStringResource("Cription", comment: "Cription app name")
        static let yourAnalytics = LocalizedStringResource("Your Analytics", comment: "Your analytics title")
        static let trackTokenUsage = LocalizedStringResource("Track your token usage over time", comment: "Track token usage deCription")
        static let totalTokens = LocalizedStringResource("Total Tokens", comment: "Total tokens label")
        static let noDataAvailable = LocalizedStringResource("No data available yet", comment: "No data available message")
        static let generateSampleData = LocalizedStringResource("Generate Sample Data", comment: "Generate sample data button")
        static let availableModels = LocalizedStringResource("Available Models", comment: "Available models title")
        static let chooseBestModel = LocalizedStringResource("Choose the best model for your tranCription needs", comment: "Choose best model deCription")
        static let modelCategories = LocalizedStringResource("Model Categories", comment: "Model categories title")
        static let aboutTokensPricing = LocalizedStringResource("About Tokens & Pricing", comment: "About tokens pricing title")
        static let CriptionCoreDocumentation = LocalizedStringResource("Cription Core Documentation", comment: "Cription core documentation title")
        static let viewWhisperkitDocs = LocalizedStringResource("View WhisperKit documentation", comment: "View WhisperKit docs button")
        static let CriptionCoreFree = LocalizedStringResource("Cription Core - Free", comment: "Cription core free title")
        static let usageAnalytics = LocalizedStringResource("Usage Analytics", comment: "Usage analytics title")
        static let monitorUsage = LocalizedStringResource("Monitor your Cription Core usage and performance metrics", comment: "Monitor usage deCription")
        static let usageTrends = LocalizedStringResource("Usage Trends", comment: "Usage trends title")
        static let dailyTranCriptions = LocalizedStringResource("Daily TranCriptions", comment: "Daily tranCriptions title")
        static let lastPeriod = LocalizedStringResource("Last %@", comment: "Last period format")
        static let total = LocalizedStringResource("Total", comment: "Total label")
        static let detailedStatistics = LocalizedStringResource("Detailed Statistics", comment: "Detailed statistics title")
        static let noUsageData = LocalizedStringResource("No usage data available yet", comment: "No usage data message")
        static let billingSubCription = LocalizedStringResource("Billing & SubCription", comment: "Billing subCription title")
        static let betaFreePlan = LocalizedStringResource("Beta version - Free plan with unlimited access", comment: "Beta free plan deCription")
        static let beta = LocalizedStringResource("BETA", comment: "Beta badge")
        static let betaTestingPhase = LocalizedStringResource("Currently in beta testing phase", comment: "Beta testing phase deCription")
        static let freePlan = LocalizedStringResource("Free Plan", comment: "Free plan title")
        static let priceFree = LocalizedStringResource("$0/month", comment: "Free price")
        static let planStatus = LocalizedStringResource("Plan status:", comment: "Plan status label")
        static let active = LocalizedStringResource("Active", comment: "Active status")
        static let betaFeaturesIncluded = LocalizedStringResource("Beta Features Included:", comment: "Beta features included title")
        static let aboutBetaVersion = LocalizedStringResource("About Beta Version", comment: "About beta version title")
        static let aboutTokens = LocalizedStringResource("About Tokens", comment: "About tokens title")
        static let understandingTokens = LocalizedStringResource("Understanding tokens and their role in AI tranCription", comment: "Understanding tokens deCription")
        static let tokenInformation = LocalizedStringResource("Token Information", comment: "Token information title")
        static let documentation = LocalizedStringResource("Documentation", comment: "Documentation title")
        static let speechRecognitionFeatures = LocalizedStringResource("Speech recognition features and capabilities", comment: "Speech recognition features deCription")
        static let coreFeatures = LocalizedStringResource("Core Features", comment: "Core features title")
        static let technicalSpecifications = LocalizedStringResource("Technical Specifications", comment: "Technical specifications title")
        static let gettingStarted = LocalizedStringResource("Getting Started", comment: "Getting started title")
    }
    
    // MARK: - Confidence Levels
    struct Confidence {
        static let veryHigh = LocalizedStringResource("Very High", comment: "Very high confidence")
        static let high = LocalizedStringResource("High", comment: "High confidence")
        static let medium = LocalizedStringResource("Medium", comment: "Medium confidence")
        static let low = LocalizedStringResource("Low", comment: "Low confidence")
        static let veryLow = LocalizedStringResource("Very Low", comment: "Very low confidence")
    }
    
    // MARK: - Token Calculator
    struct TokenCalculator {
        static let title = LocalizedStringResource("Token Calculator", comment: "Token calculator title")
    }
    
    // MARK: - File Operations
    struct File {
        static let loading = LocalizedStringResource("Loading File...", comment: "Loading file message")
    }
    
    // MARK: - TranCription
    struct TranCription {
        static let processing = LocalizedStringResource("Transcribing...", comment: "Transcribing message")
    }
    
    // MARK: - Audio
    struct Audio {
        static let resampling = LocalizedStringResource("Resampling...", comment: "Resampling message")
    }
    
    // MARK: - Model Selection
    struct ModelSelection {
        static let all = LocalizedStringResource("All", comment: "All models option")
        static let title = LocalizedStringResource("Select Model", comment: "Select model title")
        static let searchPlaceholder = LocalizedStringResource("Search models...", comment: "Search models placeholder")
        static let showRecommendedOnly = LocalizedStringResource("Show Recommended Only", comment: "Show recommended only option")
        static let noModelsFound = LocalizedStringResource("No models found", comment: "No models found message")
        static let adjustSearch = LocalizedStringResource("Try adjusting your search or filters", comment: "Adjust search message")
    }
    
    // MARK: - Language Selection
    struct LanguageSelection {
        static let title = LocalizedStringResource("Select Language", comment: "Select language title")
        static let searchPlaceholder = LocalizedStringResource("Search languages...", comment: "Search languages placeholder")
    }
    
    // MARK: - Font Selection
    struct FontSelection {
        static let title = LocalizedStringResource("Select Font", comment: "Select font title")
        static let searchPlaceholder = LocalizedStringResource("Search fonts...", comment: "Search fonts placeholder")
    }
    
    // MARK: - UI Language Selection
    struct UILanguageSelection {
        static let title = LocalizedStringResource("Select UI Language", comment: "Select UI language title")
    }
    
    // MARK: - MCP Test
    struct MCPTest {
        static let title = LocalizedStringResource("MCP SDK Test", comment: "MCP SDK test title")
        static let successMessage = LocalizedStringResource("MCP SDK is successfully integrated!", comment: "MCP SDK success message")
    }
}