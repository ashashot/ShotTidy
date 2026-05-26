//
//  ShareEditView.swift
//  ShotTidyShare
//
//  Edit form for a PendingDraftItem inside the Share Extension.
//  Self-contained — mirrors ItemCategory.FieldSchema from the main app
//  without importing any main-app types.
//

import SwiftUI

// MARK: - Category options (picker list + display info)

struct ShareCategoryOption: Identifiable {
    var id: String { key }
    let key: String
    let name: String
    let icon: String

    static let all: [ShareCategoryOption] = [
        .init(key: "shopping",         name: "Shopping",          icon: "cart.fill"),
        .init(key: "places",           name: "Places",            icon: "mappin.circle.fill"),
        .init(key: "appsServices",     name: "Apps & Services",   icon: "app.fill"),
        .init(key: "languageLearning", name: "Language Learning", icon: "textformat.abc"),
        .init(key: "prompts",          name: "Prompts",           icon: "text.bubble.fill"),
        .init(key: "health",           name: "Health",            icon: "heart.fill"),
        .init(key: "recipes",          name: "Recipes",           icon: "fork.knife"),
        .init(key: "books",            name: "Books",             icon: "book.fill"),
        .init(key: "movies",           name: "Movies & TV Shows", icon: "play.rectangle.fill"),
        .init(key: "quotes",           name: "Quotes",            icon: "quote.bubble.fill"),
        .init(key: "articles",         name: "Articles",          icon: "newspaper.fill"),
        .init(key: "contacts",         name: "Contacts",          icon: "person.circle.fill"),
        .init(key: "tasks",            name: "Tasks",             icon: "checkmark.circle.fill"),
    ]

    // MARK: - Display info (name + icon + color) for the category row chip

    typealias DisplayInfo = (name: String, icon: String, color: Color)

    static func displayInfo(for key: String) -> DisplayInfo {
        switch key {
        case "shopping":         return ("Shopping",          "cart.fill",               .orange)
        case "places":           return ("Places",            "mappin.circle.fill",       Color(red: 0.88, green: 0.18, blue: 0.18))
        case "appsServices":     return ("Apps & Services",   "app.fill",                 .blue)
        case "languageLearning": return ("Language Learning", "textformat.abc",            Color(red: 0.18, green: 0.75, blue: 0.35))
        case "prompts":          return ("Prompts",           "text.bubble.fill",         .purple)
        case "health":           return ("Health",            "heart.fill",               .pink)
        case "recipes":          return ("Recipes",           "fork.knife",               Color(red: 0.92, green: 0.67, blue: 0.12))
        case "books":            return ("Books",             "book.fill",                Color(red: 0.6, green: 0.38, blue: 0.18))
        case "movies":           return ("Movies & TV",       "play.rectangle.fill",      .indigo)
        case "quotes":           return ("Quotes",            "quote.bubble.fill",        .teal)
        case "articles":         return ("Articles",          "newspaper.fill",           Color(red: 0.0, green: 0.65, blue: 0.85))
        case "contacts":         return ("Contacts",          "person.circle.fill",       Color(red: 0.12, green: 0.72, blue: 0.72))
        case "tasks":            return ("Tasks",             "checkmark.circle.fill",    Color(red: 0.48, green: 0.48, blue: 0.56))
        default:                 return (key,                 "tag.fill",                 .gray)
        }
    }
}

// MARK: - Field schema (mirrors ItemCategory.FieldSchema from the main app)

struct ShareFieldSchema {
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

    static func make(for key: String) -> ShareFieldSchema {
        switch key {
        case "shopping":
            return .init(
                titleLabel: "Product Name",    titlePlaceholder: "e.g. Nike Air Max 270",
                subtitleLabel: "Price",        subtitlePlaceholder: "e.g. 99.99",
                linkLabel: "Link",             linkPlaceholder: "https://...",
                extra1Label: "Store",          extra1Placeholder: "Amazon / eBay / Etsy",
                extra2Label: "Currency",       extra2Placeholder: "USD / EUR / GBP",
                notesLabel: "Notes",           notesPlaceholder: "Additional information"
            )
        case "places":
            return .init(
                titleLabel: "Place Name",      titlePlaceholder: "Café Paris / Louvre Museum",
                subtitleLabel: "Address",      subtitlePlaceholder: "123 Main St",
                linkLabel: "Link / Maps",      linkPlaceholder: "https://maps.apple.com/...",
                extra1Label: "City",           extra1Placeholder: "New York",
                extra2Label: "Country",        extra2Placeholder: "USA",
                notesLabel: "Notes",           notesPlaceholder: "Opening hours, description..."
            )
        case "appsServices":
            return .init(
                titleLabel: "Name",            titlePlaceholder: "Notion / Figma / Telegram",
                subtitleLabel: "Description",  subtitlePlaceholder: "Brief description",
                linkLabel: "Link",             linkPlaceholder: "https://...",
                extra1Label: "Platform",       extra1Placeholder: "iOS / Android / Web",
                extra2Label: "Category",       extra2Placeholder: "Productivity / Design",
                notesLabel: "Notes",           notesPlaceholder: "Why I need it"
            )
        case "languageLearning":
            return .init(
                titleLabel: "Word / Phrase",   titlePlaceholder: "Word or phrase to learn",
                subtitleLabel: "Translation",  subtitlePlaceholder: "Translation",
                linkLabel: nil,                linkPlaceholder: nil,
                extra1Label: "Language",       extra1Placeholder: "English / Spanish",
                extra2Label: "Example",        extra2Placeholder: "Example sentence",
                notesLabel: "Context",         notesPlaceholder: "Source, notes"
            )
        case "prompts":
            return .init(
                titleLabel: "Prompt Text",     titlePlaceholder: "Act as a professional...",
                subtitleLabel: "Purpose",      subtitlePlaceholder: "What it is used for",
                linkLabel: nil,                linkPlaceholder: nil,
                extra1Label: "AI Tool",        extra1Placeholder: "ChatGPT / Claude / Midjourney",
                extra2Label: nil,              extra2Placeholder: nil,
                notesLabel: "Notes",           notesPlaceholder: "Results, improvements"
            )
        case "health":
            return .init(
                titleLabel: "Tip / Info",      titlePlaceholder: "Health-related text",
                subtitleLabel: "Type",         subtitlePlaceholder: "Medication / Exercise / Diet",
                linkLabel: nil,                linkPlaceholder: nil,
                extra1Label: "Source",         extra1Placeholder: "Doctor / App / Article",
                extra2Label: nil,              extra2Placeholder: nil,
                notesLabel: "Additional",      notesPlaceholder: "Dosage, notes..."
            )
        case "recipes":
            return .init(
                titleLabel: "Dish Name",       titlePlaceholder: "Pasta Carbonara",
                subtitleLabel: "Ingredients",  subtitlePlaceholder: "List of ingredients",
                linkLabel: "Recipe Link",      linkPlaceholder: "https://...",
                extra1Label: "Cooking Time",   extra1Placeholder: "30 min",
                extra2Label: "Cuisine",        extra2Placeholder: "Italian / Mexican",
                notesLabel: "Steps",           notesPlaceholder: "1. Chop... 2. Fry..."
            )
        case "books":
            return .init(
                titleLabel: "Book Title",      titlePlaceholder: "The Great Gatsby",
                subtitleLabel: "Author",       subtitlePlaceholder: "F. Scott Fitzgerald",
                linkLabel: "Buy / Read",       linkPlaceholder: "https://...",
                extra1Label: "Genre",          extra1Placeholder: "Novel / Non-fiction",
                extra2Label: "Year",           extra2Placeholder: "2024",
                notesLabel: "Notes",           notesPlaceholder: "Impressions, quotes..."
            )
        case "movies":
            return .init(
                titleLabel: "Title",           titlePlaceholder: "Inception / Succession",
                subtitleLabel: "Platform",     subtitlePlaceholder: "Netflix / HBO / Apple TV+",
                linkLabel: "Watch",            linkPlaceholder: "https://...",
                extra1Label: "Genre",          extra1Placeholder: "Thriller / Comedy",
                extra2Label: "Year",           extra2Placeholder: "2024",
                notesLabel: "Notes",           notesPlaceholder: "Why I want to watch it..."
            )
        case "quotes":
            return .init(
                titleLabel: "Quote",           titlePlaceholder: "Quote text",
                subtitleLabel: "Author",       subtitlePlaceholder: "Author name",
                linkLabel: "Source",           linkPlaceholder: "Book / Article / URL",
                extra1Label: nil,              extra1Placeholder: nil,
                extra2Label: nil,              extra2Placeholder: nil,
                notesLabel: "Notes",           notesPlaceholder: "Why this matters"
            )
        case "articles":
            return .init(
                titleLabel: "Article Title",   titlePlaceholder: "Article headline",
                subtitleLabel: "Source",       subtitlePlaceholder: "Medium / TechCrunch",
                linkLabel: "Link",             linkPlaceholder: "https://...",
                extra1Label: "Topic",          extra1Placeholder: "Technology / Science",
                extra2Label: nil,              extra2Placeholder: nil,
                notesLabel: "Summary",         notesPlaceholder: "Key points"
            )
        case "contacts":
            return .init(
                titleLabel: "Name",            titlePlaceholder: "John Smith",
                subtitleLabel: "Phone",        subtitlePlaceholder: "+1 (555) 000-0000",
                linkLabel: "Email",            linkPlaceholder: "email@example.com",
                extra1Label: "Company",        extra1Placeholder: "Company name",
                extra2Label: "Position",       extra2Placeholder: "CEO / Designer",
                notesLabel: "Notes",           notesPlaceholder: "Where we met",
                isLinkEmail: true
            )
        case "tasks":
            return .init(
                titleLabel: "Task",            titlePlaceholder: "Task description",
                subtitleLabel: "Due Date",     subtitlePlaceholder: "May 25 / end of week",
                linkLabel: nil,                linkPlaceholder: nil,
                extra1Label: "Priority",       extra1Placeholder: "High / Medium / Low",
                extra2Label: nil,              extra2Placeholder: nil,
                notesLabel: "Details",         notesPlaceholder: "Additional details"
            )
        default:
            return .init(
                titleLabel: "Title",           titlePlaceholder: "Title",
                subtitleLabel: "Subtitle",     subtitlePlaceholder: nil,
                linkLabel: "Link",             linkPlaceholder: "https://...",
                extra1Label: "Extra 1",        extra1Placeholder: nil,
                extra2Label: "Extra 2",        extra2Placeholder: nil,
                notesLabel: "Notes",           notesPlaceholder: nil
            )
        }
    }
}

// MARK: - Edit View

struct ShareEditView: View {
    @Binding var item: PendingDraftItem
    @Environment(\.dismiss) private var dismiss

    private var schema: ShareFieldSchema {
        ShareFieldSchema.make(for: item.categoryKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Category
                Section("Category") {
                    Picker("Category", selection: $item.categoryKey) {
                        ForEach(ShareCategoryOption.all) { cat in
                            Label(cat.name, systemImage: cat.icon).tag(cat.key)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Title (always visible)
                Section(schema.titleLabel) {
                    TextField(schema.titlePlaceholder, text: $item.title, axis: .vertical)
                        .lineLimit(4, reservesSpace: false)
                }

                // Subtitle
                if let label = schema.subtitleLabel {
                    Section(label) {
                        TextField(
                            schema.subtitlePlaceholder ?? label,
                            text: $item.subtitle,
                            axis: .vertical
                        )
                        .lineLimit(3, reservesSpace: false)
                    }
                }

                // Link
                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? "https://...", text: $item.link)
                            .keyboardType(schema.isLinkEmail ? .emailAddress : .URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                // Extra 1
                if let label = schema.extra1Label {
                    Section(label) {
                        TextField(schema.extra1Placeholder ?? label, text: $item.extra1)
                    }
                }

                // Extra 2
                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? label, text: $item.extra2)
                    }
                }

                // Notes
                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(
                            schema.notesPlaceholder ?? label,
                            text: $item.notes,
                            axis: .vertical
                        )
                        .lineLimit(6, reservesSpace: false)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
