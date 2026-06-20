//
//  ItemCategory.swift
//  ShotTidyMac
//

import SwiftUI

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
        case .shopping:         return "Shopping"
        case .places:           return "Places"
        case .appsServices:     return "Apps & Services"
        case .languageLearning: return "Language Learning"
        case .prompts:          return "Prompts"
        case .health:           return "Health"
        case .recipes:          return "Recipes"
        case .books:            return "Books"
        case .movies:           return "Movies & TV Shows"
        case .quotes:           return "Quotes"
        case .articles:         return "Articles"
        case .contacts:         return "Contacts"
        case .tasks:            return "Tasks"
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
                titleLabel: "Product Name", titlePlaceholder: "e.g. Nike Air Max 270",
                subtitleLabel: "Price", subtitlePlaceholder: "e.g. 99.99",
                linkLabel: "Link", linkPlaceholder: "https://...",
                extra1Label: "Store", extra1Placeholder: "Amazon / eBay / Etsy",
                extra2Label: "Currency", extra2Placeholder: "USD / EUR / GBP",
                notesLabel: "Notes", notesPlaceholder: "Additional information"
            )
        case .places:
            return FieldSchema(
                titleLabel: "Place Name", titlePlaceholder: "Café Paris / Louvre Museum",
                subtitleLabel: "Address", subtitlePlaceholder: "123 Main St",
                linkLabel: "Link / Maps", linkPlaceholder: "https://maps.apple.com/...",
                extra1Label: "City", extra1Placeholder: "New York",
                extra2Label: "Country", extra2Placeholder: "USA",
                notesLabel: "Notes", notesPlaceholder: "Opening hours, description..."
            )
        case .appsServices:
            return FieldSchema(
                titleLabel: "Name", titlePlaceholder: "Notion / Figma / Telegram",
                subtitleLabel: "Description", subtitlePlaceholder: "Brief description of the service",
                linkLabel: "Link", linkPlaceholder: "https://...",
                extra1Label: "Platform", extra1Placeholder: "iOS / Android / Web / macOS",
                extra2Label: "Category", extra2Placeholder: "Productivity / Design",
                notesLabel: "Notes", notesPlaceholder: "What I liked / why I need it"
            )
        case .languageLearning:
            return FieldSchema(
                titleLabel: "Word / Phrase / Text", titlePlaceholder: "Word or phrase to learn",
                subtitleLabel: "Translation", subtitlePlaceholder: "Translation",
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: "Language", extra1Placeholder: "English / Spanish",
                extra2Label: "Usage Example", extra2Placeholder: "I need to leverage my skills",
                notesLabel: "Context", notesPlaceholder: "Source, additional examples"
            )
        case .prompts:
            return FieldSchema(
                titleLabel: "Prompt Text", titlePlaceholder: "Act as a professional...",
                subtitleLabel: "Purpose", subtitlePlaceholder: "What it is used for",
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: "AI Tool", extra1Placeholder: "ChatGPT / Claude / Midjourney",
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Notes", notesPlaceholder: "Results, improvements"
            )
        case .health:
            return FieldSchema(
                titleLabel: "Tip / Information", titlePlaceholder: "Health-related text",
                subtitleLabel: "Type", subtitlePlaceholder: "Medication / Exercise / Diet",
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: "Source", extra1Placeholder: "Doctor / App / Article",
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Additional", notesPlaceholder: "Dosage, contraindications..."
            )
        case .recipes:
            return FieldSchema(
                titleLabel: "Dish Name", titlePlaceholder: "Pasta Carbonara / Caesar Salad",
                subtitleLabel: "Ingredients", subtitlePlaceholder: "List of ingredients",
                linkLabel: "Recipe Link", linkPlaceholder: "https://...",
                extra1Label: "Cooking Time", extra1Placeholder: "30 min",
                extra2Label: "Cuisine", extra2Placeholder: "Italian / Mexican",
                notesLabel: "Steps", notesPlaceholder: "1. Chop... 2. Fry..."
            )
        case .books:
            return FieldSchema(
                titleLabel: "Book Title", titlePlaceholder: "The Great Gatsby",
                subtitleLabel: "Author", subtitlePlaceholder: "F. Scott Fitzgerald",
                linkLabel: "Buy / Read", linkPlaceholder: "https://...",
                extra1Label: "Genre", extra1Placeholder: "Novel / Non-fiction / Biography",
                extra2Label: "Year", extra2Placeholder: "2024",
                notesLabel: "Notes", notesPlaceholder: "Impressions, quotes..."
            )
        case .movies:
            return FieldSchema(
                titleLabel: "Title", titlePlaceholder: "Inception / Succession",
                subtitleLabel: "Platform", subtitlePlaceholder: "Netflix / HBO / Apple TV+",
                linkLabel: "Watch", linkPlaceholder: "https://...",
                extra1Label: "Genre", extra1Placeholder: "Thriller / Comedy / Documentary",
                extra2Label: "Year", extra2Placeholder: "2024",
                notesLabel: "Notes", notesPlaceholder: "Why I want to watch it..."
            )
        case .quotes:
            return FieldSchema(
                titleLabel: "Quote", titlePlaceholder: "Quote text",
                subtitleLabel: "Author", subtitlePlaceholder: "Author name",
                linkLabel: "Source", linkPlaceholder: "Book / Article / URL",
                extra1Label: nil, extra1Placeholder: nil,
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Notes", notesPlaceholder: "Why this quote matters"
            )
        case .articles:
            return FieldSchema(
                titleLabel: "Article Title", titlePlaceholder: "Article headline",
                subtitleLabel: "Source / Publication", subtitlePlaceholder: "Medium / TechCrunch / Wired",
                linkLabel: "Link", linkPlaceholder: "https://...",
                extra1Label: "Topic", extra1Placeholder: "Technology / Science / Business",
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Summary", notesPlaceholder: "Key points of the article"
            )
        case .contacts:
            return FieldSchema(
                titleLabel: "Name", titlePlaceholder: "John Smith",
                subtitleLabel: "Phone", subtitlePlaceholder: "+1 (555) 000-0000",
                linkLabel: "Email", linkPlaceholder: "email@example.com",
                extra1Label: "Company", extra1Placeholder: "Company name",
                extra2Label: "Position", extra2Placeholder: "CEO / Designer / Developer",
                notesLabel: "Notes", notesPlaceholder: "Where we met, what we discussed",
                isLinkEmail: true
            )
        case .tasks:
            return FieldSchema(
                titleLabel: "Task", titlePlaceholder: "Task description",
                subtitleLabel: "Due Date", subtitlePlaceholder: "May 25 / end of week",
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: "Priority", extra1Placeholder: "High / Medium / Low",
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Details", notesPlaceholder: "Additional task details"
            )
        }
    }
}
