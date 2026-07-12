//
//  Config.swift
//  ShotTidy
//
//  Supabase project credentials.
//  The anon key is a publishable key — safe to embed in the app.
//  The OpenAI key lives exclusively in Supabase Secrets (server-side).
//

import Foundation

enum Config {
    static let supabaseURL     = "https://qpxvnnkewwolzglynrgj.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFweHZubmtld3dvbHpnbHlucmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NDkzMzksImV4cCI6MjA5NTMyNTMzOX0.fYzLDOILNm3I2TU6QobG5HGQQxe8kJAfPCI9kSABpec"

    static let analyzeEndpoint = URL(string: "\(supabaseURL)/functions/v1/analyze-screenshot")!
    static let enrichEndpoint  = URL(string: "\(supabaseURL)/functions/v1/enrich-item")!
    static let suggestCategoryFieldsEndpoint = URL(string: "\(supabaseURL)/functions/v1/suggest-category-fields")!

    static let privacyPolicyURL = URL(string: "https://m-bx.com/company/consent/")!
    static let termsOfUseURL    = URL(string: "https://m-bx.com/company/terms/")!

    /// Address used for the "Send Feedback" action in Settings.
    static let feedbackEmail = "info@m-bx.com"

    // MARK: - Force Update

    /// Remote JSON that controls force-update behavior.
    /// Bucket "config" must be public in Supabase Storage.
    /// File content: { "force_update": false }
    static let appConfigURL = URL(
        string: "\(supabaseURL)/storage/v1/object/public/config/app-config.json"
    )

    /// App Store link — ShotTidier (Apple ID 6773235571).
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6773235571")
}
