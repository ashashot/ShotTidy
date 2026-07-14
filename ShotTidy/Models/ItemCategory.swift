//
//  ItemCategory.swift
//  ShotTidy
//
//  Catalog categories with field descriptions for each one.
//

import SwiftUI

// MARK: - ItemCategory

enum ItemCategory: String, CaseIterable, Codable, Hashable {
    case shopping        = "shopping"
    case places          = "places"
    case appsServices    = "appsServices"
    case languageLearning = "languageLearning"
    case prompts         = "prompts"
    case health          = "health"
    case recipes         = "recipes"
    case books           = "books"
    case movies          = "movies"
    case quotes          = "quotes"
    case articles        = "articles"
    case contacts        = "contacts"
    case tasks           = "tasks"

    var localizedName: String {
        switch self {
        case .shopping:         return String(localized: "Shopping", bundle: AppLocale.bundle)
        case .places:           return String(localized: "Places", bundle: AppLocale.bundle)
        case .appsServices:     return String(localized: "Apps & Services", bundle: AppLocale.bundle)
        case .languageLearning: return String(localized: "Language Learning", bundle: AppLocale.bundle)
        case .prompts:          return String(localized: "Prompts", bundle: AppLocale.bundle)
        case .health:           return String(localized: "Health", bundle: AppLocale.bundle)
        case .recipes:          return String(localized: "Recipes", bundle: AppLocale.bundle)
        case .books:            return String(localized: "Books", bundle: AppLocale.bundle)
        case .movies:           return String(localized: "Movies & TV Shows", bundle: AppLocale.bundle)
        case .quotes:           return String(localized: "Quotes", bundle: AppLocale.bundle)
        case .articles:         return String(localized: "Articles", bundle: AppLocale.bundle)
        case .contacts:         return String(localized: "Contacts", bundle: AppLocale.bundle)
        case .tasks:            return String(localized: "Tasks", bundle: AppLocale.bundle)
        }
    }

    var icon: String {
        switch self {
        case .shopping:         return "cart.fill"
        case .places:           return "mappin.circle.fill"
        case .appsServices:     return "app.fill"
        case .languageLearning: return "textformat.abc"
        case .prompts:          return "text.bubble.fill"
        case .health:           return "heart.fill"
        case .recipes:          return "fork.knife"
        case .books:            return "book.fill"
        case .movies:           return "play.rectangle.fill"
        case .quotes:           return "quote.bubble.fill"
        case .articles:         return "newspaper.fill"
        case .contacts:         return "person.circle.fill"
        case .tasks:            return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .shopping:         return .orange
        case .places:           return Color(red: 0.88, green: 0.18, blue: 0.18)
        case .appsServices:     return .blue
        case .languageLearning: return Color(red: 0.18, green: 0.75, blue: 0.35)
        case .prompts:          return .purple
        case .health:           return .pink
        case .recipes:          return Color(red: 0.92, green: 0.67, blue: 0.12)
        case .books:            return Color(red: 0.6, green: 0.38, blue: 0.18)
        case .movies:           return .indigo
        case .quotes:           return .teal
        case .articles:         return Color(red: 0.0, green: 0.65, blue: 0.85)
        case .contacts:         return Color(red: 0.12, green: 0.72, blue: 0.72)
        case .tasks:            return Color(red: 0.48, green: 0.48, blue: 0.56)
        }
    }

    // MARK: - Field Schema

    struct FieldSchema {
        let titleLabel: String
        let titlePlaceholder: String
        let subtitleLabel: String?
        let subtitlePlaceholder: String?
        let linkLabel: String?
        let linkPlaceholder: String?
        let extra1Label: String?
        let extra1Placeholder: String?
        let extra2Label: String?
        let extra2Placeholder: String?
        let notesLabel: String?
        let notesPlaceholder: String?
        var isLinkEmail: Bool = false
    }

    var fieldSchema: FieldSchema {
        switch self {
        case .shopping:
            return FieldSchema(
                titleLabel: String(localized: "Product Name", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "e.g. Nike Air Max 270", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Price", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "e.g. 99.99", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Link", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "https://...", bundle: AppLocale.bundle),
                extra1Label: String(localized: "Store", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "Amazon / eBay / Etsy", bundle: AppLocale.bundle),
                extra2Label: String(localized: "Currency", bundle: AppLocale.bundle), extra2Placeholder: String(localized: "USD / EUR / GBP", bundle: AppLocale.bundle),
                notesLabel: String(localized: "Notes", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Additional information", bundle: AppLocale.bundle)
            )
        case .places:
            return FieldSchema(
                titleLabel: String(localized: "Place Name", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Café Paris / Louvre Museum", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Address", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "123 Main St", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Link / Maps", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "https://maps.apple.com/...", bundle: AppLocale.bundle),
                extra1Label: String(localized: "City", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "New York", bundle: AppLocale.bundle),
                extra2Label: String(localized: "Country", bundle: AppLocale.bundle), extra2Placeholder: String(localized: "USA", bundle: AppLocale.bundle),
                notesLabel: String(localized: "Notes", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Opening hours, description...", bundle: AppLocale.bundle)
            )
        case .appsServices:
            return FieldSchema(
                titleLabel: String(localized: "Name", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Notion / Figma / Telegram", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Description", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "Brief description of the service", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Link", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "https://...", bundle: AppLocale.bundle),
                extra1Label: String(localized: "Platform", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "iOS / Android / Web / macOS", bundle: AppLocale.bundle),
                extra2Label: String(localized: "Category", bundle: AppLocale.bundle), extra2Placeholder: String(localized: "Productivity / Design", bundle: AppLocale.bundle),
                notesLabel: String(localized: "Notes", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "What I liked / why I need it", bundle: AppLocale.bundle)
            )
        case .languageLearning:
            return FieldSchema(
                titleLabel: String(localized: "Word / Phrase / Text", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Word or phrase to learn", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Translation", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "Translation", bundle: AppLocale.bundle),
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: String(localized: "Language", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "English / Spanish", bundle: AppLocale.bundle),
                extra2Label: String(localized: "Usage Example", bundle: AppLocale.bundle), extra2Placeholder: String(localized: "I need to leverage my skills", bundle: AppLocale.bundle),
                notesLabel: String(localized: "Context", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Source, additional examples", bundle: AppLocale.bundle)
            )
        case .prompts:
            return FieldSchema(
                titleLabel: String(localized: "Prompt Text", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Act as a professional...", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Purpose", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "What it is used for", bundle: AppLocale.bundle),
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: String(localized: "AI Tool", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "ChatGPT / Claude / Midjourney", bundle: AppLocale.bundle),
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: String(localized: "Notes", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Results, improvements", bundle: AppLocale.bundle)
            )
        case .health:
            return FieldSchema(
                titleLabel: String(localized: "Tip / Information", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Health-related text", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Type", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "Medication / Exercise / Diet", bundle: AppLocale.bundle),
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: String(localized: "Source", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "Doctor / App / Article", bundle: AppLocale.bundle),
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: String(localized: "Additional", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Dosage, contraindications...", bundle: AppLocale.bundle)
            )
        case .recipes:
            return FieldSchema(
                titleLabel: String(localized: "Dish Name", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Pasta Carbonara / Caesar Salad", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Ingredients", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "List of ingredients", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Recipe Link", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "https://...", bundle: AppLocale.bundle),
                extra1Label: String(localized: "Cooking Time", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "30 min", bundle: AppLocale.bundle),
                extra2Label: String(localized: "Cuisine", bundle: AppLocale.bundle), extra2Placeholder: String(localized: "Italian / Mexican", bundle: AppLocale.bundle),
                notesLabel: String(localized: "Steps", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "1. Chop... 2. Fry...", bundle: AppLocale.bundle)
            )
        case .books:
            return FieldSchema(
                titleLabel: String(localized: "Book Title", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "The Great Gatsby", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Author", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "F. Scott Fitzgerald", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Buy / Read", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "https://...", bundle: AppLocale.bundle),
                extra1Label: String(localized: "Genre", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "Novel / Non-fiction / Biography", bundle: AppLocale.bundle),
                extra2Label: String(localized: "Year", bundle: AppLocale.bundle), extra2Placeholder: String(localized: "2024", bundle: AppLocale.bundle),
                notesLabel: String(localized: "Notes", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Impressions, quotes...", bundle: AppLocale.bundle)
            )
        case .movies:
            return FieldSchema(
                titleLabel: String(localized: "Title", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Inception / Succession", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Platform", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "Netflix / HBO / Apple TV+", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Watch", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "https://...", bundle: AppLocale.bundle),
                extra1Label: String(localized: "Genre", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "Thriller / Comedy / Documentary", bundle: AppLocale.bundle),
                extra2Label: String(localized: "Year", bundle: AppLocale.bundle), extra2Placeholder: String(localized: "2024", bundle: AppLocale.bundle),
                notesLabel: String(localized: "Notes", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Why I want to watch it...", bundle: AppLocale.bundle)
            )
        case .quotes:
            return FieldSchema(
                titleLabel: String(localized: "Quote", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Quote text", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Author", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "Author name", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Source", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "Book / Article / URL", bundle: AppLocale.bundle),
                extra1Label: nil, extra1Placeholder: nil,
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: String(localized: "Notes", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Why this quote matters", bundle: AppLocale.bundle)
            )
        case .articles:
            return FieldSchema(
                titleLabel: String(localized: "Article Title", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Article headline", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Source / Publication", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "Medium / TechCrunch / Wired", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Link", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "https://...", bundle: AppLocale.bundle),
                extra1Label: String(localized: "Topic", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "Technology / Science / Business", bundle: AppLocale.bundle),
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: String(localized: "Summary", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Key points of the article", bundle: AppLocale.bundle)
            )
        case .contacts:
            return FieldSchema(
                titleLabel: String(localized: "Name", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "John Smith", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Phone", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "+1 (555) 000-0000", bundle: AppLocale.bundle),
                linkLabel: String(localized: "Email", bundle: AppLocale.bundle), linkPlaceholder: String(localized: "email@example.com", bundle: AppLocale.bundle),
                extra1Label: String(localized: "Company", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "Company name", bundle: AppLocale.bundle),
                extra2Label: String(localized: "Position", bundle: AppLocale.bundle), extra2Placeholder: String(localized: "CEO / Designer / Developer", bundle: AppLocale.bundle),
                notesLabel: String(localized: "Notes", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Where we met, what we discussed", bundle: AppLocale.bundle),
                isLinkEmail: true
            )
        case .tasks:
            return FieldSchema(
                titleLabel: String(localized: "Task", bundle: AppLocale.bundle), titlePlaceholder: String(localized: "Task description", bundle: AppLocale.bundle),
                subtitleLabel: String(localized: "Due Date", bundle: AppLocale.bundle), subtitlePlaceholder: String(localized: "May 25 / end of week", bundle: AppLocale.bundle),
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: String(localized: "Priority", bundle: AppLocale.bundle), extra1Placeholder: String(localized: "High / Medium / Low", bundle: AppLocale.bundle),
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: String(localized: "Details", bundle: AppLocale.bundle), notesPlaceholder: String(localized: "Additional task details", bundle: AppLocale.bundle)
            )
        }
    }
}
