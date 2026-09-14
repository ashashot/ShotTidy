//
//  DemoContent.swift
//  ShotTidy
//
//  Localized demo catalog used by DemoMode for App Store screenshots.
//  One `DemoContentSet` per language; names are fictional or public domain.
//  Debug builds only.
//

#if DEBUG
import Foundation

// MARK: - Content types

struct DemoCatalogEntry {
    let categoryKey: String
    let title: String
    var subtitle: String? = nil
    var link: String? = nil
    var extra1: String? = nil
    var extra2: String? = nil
    var notes: String? = nil
    var isCompleted: Bool = false
}

struct DemoCustomCategory {
    let key: String
    let name: String
    let iconName: String
    let colorHex: String
    let titleLabel: String
    var subtitleLabel: String = ""
    var linkLabel: String = ""
    var extra1Label: String = ""
    var extra2Label: String = ""
    var notesLabel: String = ""
}

struct DemoContentSet {
    let customCategories: [DemoCustomCategory]
    /// Visible catalog entries, newest first.
    let catalog: [DemoCatalogEntry]
    /// Item count shown on each category card (older copies fill the gap).
    let categoryTotals: [String: Int]
    /// Book shown on the enrichment scene (link, genre and year "just filled").
    let enrichmentTitle: String
    /// Place shown on the map scene.
    let placeTitle: String
    let searchQuery: String
    let confirmationDrafts: [DraftItem]
    let newCategoryDrafts: [DraftItem]
    let shareDrafts: [PendingDraftItem]
}

enum DemoContent {
    static let winesKey = "custom_demo_wines"
    static let giftsKey = "custom_demo_gifts"

    /// Item count shown on each category card — identical in every language.
    static let defaultCategoryTotals: [String: Int] = [
        "shopping": 24, "places": 17, "appsServices": 9, "languageLearning": 32,
        "prompts": 14, "health": 8, "recipes": 21, "books": 12, "movies": 15,
        "quotes": 26, "articles": 11, "contacts": 6, "tasks": 10,
        winesKey: 7, giftsKey: 5,
    ]

    static func set(for languageCode: String) -> DemoContentSet {
        switch languageCode {
        case "zh-Hans": return chineseSimplified
        case "es":      return spanish
        case "pt-BR":   return portugueseBrazil
        case "pt-PT":   return portuguesePortugal
        case "tr":      return turkish
        case "ru":      return russian
        case "it":      return italian
        case "de":      return german
        case "fr":      return french
        case "ja":      return japanese
        case "ko":      return korean
        case "hy":      return armenian
        default:        return english
        }
    }
}

// MARK: - English

extension DemoContent {

    static let english = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Wines", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Wine", subtitleLabel: "Region", extra1Label: "Grape",
                extra2Label: "Vintage", notesLabel: "Tasting Notes"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Gift Ideas", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Gift", subtitleLabel: "For", linkLabel: "Link", extra1Label: "Budget"
            ),
        ],
        catalog: [
            // Shopping
            .init(categoryKey: "shopping", title: "Ceramic Pour-Over Coffee Set", subtitle: "$48.00",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "USD"),
            .init(categoryKey: "shopping", title: "Merino Wool Beanie", subtitle: "$32.00",
                  link: "https://northfold.co/beanie", extra1: "Northfold", extra2: "USD"),
            .init(categoryKey: "shopping", title: "Linen Throw Blanket", subtitle: "$64.00",
                  extra1: "Nordhem Home", extra2: "USD"),
            .init(categoryKey: "shopping", title: "Trail Running Shoes", subtitle: "$120.00",
                  extra1: "Summit Gear", extra2: "USD"),
            .init(categoryKey: "shopping", title: "Wireless Charging Pad", subtitle: "$29.99",
                  extra1: "Voltline", extra2: "USD", isCompleted: true),
            .init(categoryKey: "shopping", title: "Bamboo Cutting Board Set", subtitle: "$38.00",
                  extra1: "Hearth & Clay", extra2: "USD"),
            .init(categoryKey: "shopping", title: "Leather Card Wallet", subtitle: "$45.00",
                  extra1: "Fieldnote Goods", extra2: "USD"),
            // Unique purchased items so the widgets never show filler copies.
            .init(categoryKey: "shopping", title: "Glass Water Bottle", subtitle: "$24.00",
                  extra1: "Clearwell", extra2: "USD", isCompleted: true),
            .init(categoryKey: "shopping", title: "Canvas Tote Bag", subtitle: "$22.00",
                  extra1: "Northfold", extra2: "USD", isCompleted: true),

            // Places
            .init(categoryKey: "places", title: "Griffith Observatory", subtitle: "2800 E Observatory Rd",
                  link: "https://maps.apple.com/?q=Griffith+Observatory", extra1: "Los Angeles", extra2: "USA",
                  notes: "Sunset visit on Oct 18 at 6:30 PM. Free entry — arrive early for parking."),
            .init(categoryKey: "places", title: "Corner Bean Coffee Bar", subtitle: "412 Valencia St",
                  extra1: "San Francisco", extra2: "USA", notes: "Best oat flat white in the Mission."),
            .init(categoryKey: "places", title: "The High Line", subtitle: "820 Washington St",
                  extra1: "New York", extra2: "USA"),
            .init(categoryKey: "places", title: "Park Güell", subtitle: "Carrer d'Olot",
                  extra1: "Barcelona", extra2: "Spain"),

            // Tasks
            .init(categoryKey: "tasks", title: "Buy coffee beans", subtitle: "Today", extra1: "High"),
            .init(categoryKey: "tasks", title: "Book dentist appointment", subtitle: "Oct 3", extra1: "Medium"),
            .init(categoryKey: "tasks", title: "Renew passport", subtitle: "Oct 20", extra1: "High"),
            .init(categoryKey: "tasks", title: "Plan weekend hike", subtitle: "Saturday", extra1: "Low"),
            .init(categoryKey: "tasks", title: "Send invoice to Emma", subtitle: "Friday", extra1: "High",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Pay electricity bill", subtitle: "Sep 10", extra1: "Medium",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Water the plants", subtitle: "Yesterday", extra1: "Low",
                  isCompleted: true),

            // Recipes
            .init(categoryKey: "recipes", title: "Coffee-Rubbed Steak",
                  subtitle: "Ribeye, ground coffee, smoked paprika, brown sugar", extra1: "30 min", extra2: "American"),
            .init(categoryKey: "recipes", title: "Shakshuka",
                  subtitle: "Eggs, tomatoes, peppers, cumin, feta", extra1: "30 min", extra2: "Middle Eastern"),
            .init(categoryKey: "recipes", title: "Creamy Mushroom Risotto",
                  subtitle: "Arborio rice, mushrooms, parmesan, stock", extra1: "40 min", extra2: "Italian"),
            .init(categoryKey: "recipes", title: "Overnight Oats",
                  subtitle: "Oats, milk, chia seeds, berries, honey", extra1: "5 min", extra2: "Breakfast"),

            // Books
            .init(categoryKey: "books", title: "Meditations", subtitle: "Marcus Aurelius",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Philosophy", extra2: "180 AD"),
            .init(categoryKey: "books", title: "The Odyssey", subtitle: "Homer",
                  extra1: "Epic poetry", extra2: "8th century BC"),
            .init(categoryKey: "books", title: "Pride and Prejudice", subtitle: "Jane Austen",
                  extra1: "Novel", extra2: "1813"),

            // Health
            .init(categoryKey: "health", title: "No coffee after 2 PM for better sleep",
                  subtitle: "Sleep", extra1: "Sleep coach"),
            .init(categoryKey: "health", title: "A 10-minute walk after meals steadies blood sugar",
                  subtitle: "Exercise", extra1: "Health article"),

            // Articles
            .init(categoryKey: "articles", title: "How Coffee Affects Your Sleep",
                  subtitle: "Health Weekly", extra1: "Health"),
            .init(categoryKey: "articles", title: "The Science of Building Habits",
                  subtitle: "Mind & Method", extra1: "Psychology"),
            .init(categoryKey: "articles", title: "10 Hidden Gems in Lisbon",
                  subtitle: "Wander Journal", extra1: "Travel"),

            // Language learning
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Time spent talking at the table after a meal", extra1: "Spanish"),
            .init(categoryKey: "languageLearning", title: "Komorebi",
                  subtitle: "Sunlight filtering through the leaves", extra1: "Japanese"),
            .init(categoryKey: "languageLearning", title: "Gemütlichkeit",
                  subtitle: "Warmth, coziness and belonging", extra1: "German"),

            // Prompts
            .init(categoryKey: "prompts", title: "Act as a travel planner and build a 3-day itinerary for Lisbon",
                  subtitle: "Trip planning", extra1: "AI assistant"),
            .init(categoryKey: "prompts", title: "Rewrite this email to sound friendly but concise",
                  subtitle: "Email writing", extra1: "AI assistant"),

            // Quotes
            .init(categoryKey: "quotes", title: "Well done is better than well said.",
                  subtitle: "Benjamin Franklin"),
            .init(categoryKey: "quotes", title: "It does not matter how slowly you go as long as you do not stop.",
                  subtitle: "Confucius"),

            // Movies
            .init(categoryKey: "movies", title: "Metropolis", subtitle: "Streaming", extra1: "Sci-Fi", extra2: "1927"),
            .init(categoryKey: "movies", title: "Sherlock Jr.", subtitle: "Streaming", extra1: "Comedy", extra2: "1924"),

            // Apps & services
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Build daily habits with streaks", extra1: "iOS", extra2: "Productivity"),
            .init(categoryKey: "appsServices", title: "Pocket Budget",
                  subtitle: "Track spending in seconds", extra1: "iOS / Web", extra2: "Finance"),

            // Contacts
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+1 (415) 555-0142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Product Designer"),
            .init(categoryKey: "contacts", title: "Daniel Kim", subtitle: "+1 (212) 555-0187",
                  link: "daniel@kimarchitects.co", extra1: "Kim Architects", extra2: "Architect"),

            // Custom categories
            .init(categoryKey: winesKey, title: "Rioja Reserva", subtitle: "Rioja, Spain",
                  extra1: "Tempranillo", extra2: "2019"),
            .init(categoryKey: winesKey, title: "Sancerre Blanc", subtitle: "Loire Valley, France",
                  extra1: "Sauvignon Blanc", extra2: "2022"),
            .init(categoryKey: giftsKey, title: "Star Map Poster", subtitle: "Alex", extra1: "$49"),
        ],
        categoryTotals: [
            "shopping": 24, "places": 17, "appsServices": 9, "languageLearning": 32,
            "prompts": 14, "health": 8, "recipes": 21, "books": 12, "movies": 15,
            "quotes": 26, "articles": 11, "contacts": 6, "tasks": 10,
            winesKey: 7, giftsKey: 5,
        ],
        enrichmentTitle: "Meditations",
        placeTitle: "Griffith Observatory",
        searchQuery: "coffee",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Walnut Monitor Stand",
                      subtitle: "$89.00", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Linen Desk Mat",
                      subtitle: "$34.00", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Brass Desk Lamp",
                      subtitle: "$129.00", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Walden",
                      subtitle: "Henry David Thoreau", extra1: "Nature writing"),
            DraftItem(categoryKey: "places", title: "Oakline Studio Showroom",
                      subtitle: "18 Mercer St", extra1: "New York"),
            DraftItem(categoryKey: "tasks", title: "Order the desk lamp before the sale ends",
                      subtitle: "Friday", extra1: "High"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Monstera Deliciosa",
                      subtitle: "Bright, indirect light", extra1: "$42.00", suggestedCategoryName: "Plants"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Fiddle Leaf Fig",
                      subtitle: "Water once a week", extra1: "$58.00", suggestedCategoryName: "Plants"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Snake Plant",
                      subtitle: "Thrives in low light", extra1: "$26.00", suggestedCategoryName: "Plants"),
            DraftItem(categoryKey: giftsKey, title: "Mini Succulent Terrarium",
                      subtitle: "Mom", extra1: "$35"),
            DraftItem(categoryKey: "shopping", title: "Terracotta Pot Set",
                      subtitle: "$28.00", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Lemon Herb Salmon",
                             subtitle: "Salmon, lemon, dill, garlic, olive oil",
                             extra1: "25 min", extra2: "Mediterranean"),
            PendingDraftItem(categoryKey: "shopping", title: "Cast Iron Skillet, 10-inch",
                             subtitle: "$39.90", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Buy fresh dill and lemons",
                             subtitle: "Tomorrow", extra1: "Medium"),
        ]
    )
}
#endif
