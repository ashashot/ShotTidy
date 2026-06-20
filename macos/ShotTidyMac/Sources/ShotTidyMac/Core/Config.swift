//
//  Config.swift
//  ShotTidyMac
//

import Foundation

enum Config {
    static let supabaseURL     = "https://qpxvnnkewwolzglynrgj.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFweHZubmtld3dvbHpnbHlucmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NDkzMzksImV4cCI6MjA5NTMyNTMzOX0.fYzLDOILNm3I2TU6QobG5HGQQxe8kJAfPCI9kSABpec"

    static let analyzeEndpoint = URL(string: "\(supabaseURL)/functions/v1/analyze-screenshot")!
    static let enrichEndpoint  = URL(string: "\(supabaseURL)/functions/v1/enrich-item")!

    static let privacyPolicyURL = URL(string: "https://m-bx.com/company/consent/")!
    static let termsOfUseURL    = URL(string: "https://m-bx.com/company/terms/")!

    static let feedbackEmail = "info@m-bx.com"
}
