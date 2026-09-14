//
//  DemoMode.swift
//  ShotTidy
//
//  Debug-only scenes for App Store marketing screenshots.
//
//  Launch the Debug build with `-demoScene <scene>` (and optionally
//  `-demoLanguage <code>`, e.g. `en`, `ja`, `pt-BR`) to open a specific screen
//  on top of an in-memory catalog seeded with localized demo content. Nothing
//  here touches the real SwiftData store, and the whole file is compiled out
//  of Release builds.
//
//  Side effects on the simulator's shared App Group: Pro status is set to
//  Yearly and the language override is set, so the Share Extension and the
//  widgets render the same state as the app.
//

#if DEBUG
import SwiftUI
import SwiftData

// MARK: - DemoScene

enum DemoScene: String, CaseIterable {
    /// Category grid with populated counters.
    case catalog
    /// Confirmation list with several items extracted from one screenshot.
    case confirmation
    /// Import sheet in the "analyzing" state with the on-device engine label.
    case analyzing
    /// Book detail right after "Find Missing Info" filled three fields.
    case enrichment
    /// Place detail with the map card and the calendar button.
    case place
    /// Global search tab with a query matching several categories.
    case search
    /// Confirmation list with an AI-suggested new category and a custom one.
    case newCategory
    /// Settings tab (Pro plan, on-device engine, iCloud sync, language).
    case settings
    /// Catalog only — prepares canned drafts for the Share Extension.
    case share
    /// Catalog only — writes the widget snapshot from demo data.
    case widgets
}

// MARK: - DemoMode

@MainActor
enum DemoMode {

    private static let sceneKey = "demoScene"
    private static let languageKey = "demoLanguage"

    /// Scene requested via the `-demoScene` launch argument, `nil` for a normal launch.
    nonisolated static var scene: DemoScene? {
        UserDefaults.standard.string(forKey: sceneKey).flatMap(DemoScene.init(rawValue:))
    }

    nonisolated static var isActive: Bool { scene != nil }

    /// Language code requested via `-demoLanguage`, defaulting to English.
    static var languageCode: String {
        UserDefaults.standard.string(forKey: languageKey) ?? "en"
    }

    static var content: DemoContentSet { DemoContent.set(for: languageCode) }

    /// Fields highlighted as "just filled" on the enrichment scene.
    static let enrichmentFilledKeys: Set<String> = ["link", "extra1", "extra2"]

    // MARK: - Shared state

    /// Writes the App Group state read by the managers, the Share Extension and
    /// the widgets. Call before any manager is created. On a normal Debug
    /// launch it only clears leftovers of a previous demo run.
    static func prepareSharedState() {
        guard let scene else {
            AppGroupManager.saveDemoShareDrafts(nil)
            return
        }
        AppGroupManager.saveIsProStatus(true)
        AppGroupManager.saveProPlan(.yearly)
        AppGroupManager.saveLanguageOverride(languageCode)
        // A fresh Yearly cycle: plan credits only, free credit already claimed.
        UsageStore.shared.set(true, forKey: "usage.hasClaimedFreeEnrichment")
        UsageStore.shared.set(0, forKey: "usage.purchasedCredits")
        UsageStore.shared.set(ProPlan.yearly.monthlyEnrichments, forKey: "usage.proCredits")
        AppGroupManager.saveDemoShareDrafts(scene == .share ? content.shareDrafts : nil)
    }

    // MARK: - Container

    /// In-memory container seeded with the demo catalog for the current language.
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Screenshot.self, CatalogItem.self, UserCategory.self])
        let configuration = ModelConfiguration(
            "ShotTidyDemo",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        guard let container = try? ModelContainer(for: schema, configurations: [configuration]) else {
            fatalError("Failed to create the demo ModelContainer")
        }
        seed(container.mainContext, with: content)
        return container
    }

    private static func seed(_ context: ModelContext, with content: DemoContentSet) {
        for (index, category) in content.customCategories.enumerated() {
            context.insert(UserCategory(
                key: category.key,
                name: category.name,
                iconName: category.iconName,
                colorHex: category.colorHex,
                sortOrder: index,
                titleLabel: category.titleLabel,
                subtitleLabel: category.subtitleLabel,
                linkLabel: category.linkLabel,
                extra1Label: category.extra1Label,
                extra2Label: category.extra2Label,
                notesLabel: category.notesLabel
            ))
        }

        let now = Date()
        let screenshotIds = seedScreenshots(into: context, now: now)

        var entriesByCategory: [String: [DemoCatalogEntry]] = [:]
        for (index, entry) in content.catalog.enumerated() {
            entriesByCategory[entry.categoryKey, default: []].append(entry)
            // Listed order = newest first, a few hours apart.
            let item = insert(entry, createdAt: now.addingTimeInterval(-Double(index) * 3 * 3600), into: context)
            // The enrichment scene shows the "Source screenshot" card below the fields.
            if entry.title == content.enrichmentTitle { item.sourceScreenshotId = screenshotIds.first }
        }

        // Older copies bring each category up to its displayed total. They never
        // match the search query, so the search scene only shows the real entries.
        // Categories whose only entries match the query get neutral placeholders —
        // no scene ever lists them, they only feed the counters.
        for (key, total) in content.categoryTotals {
            let matchesQuery = { (entry: DemoCatalogEntry) in
                [entry.title, entry.subtitle, entry.extra1, entry.extra2, entry.notes]
                    .compactMap { $0 }
                    .contains { $0.localizedCaseInsensitiveContains(content.searchQuery) }
            }
            var pool = (entriesByCategory[key] ?? []).filter { !matchesQuery($0) }
            if pool.isEmpty {
                pool = [DemoCatalogEntry(categoryKey: key, title: "#\(key)")]
            }
            let existing = entriesByCategory[key]?.count ?? 0
            for offset in 0..<max(0, total - existing) {
                var copy = pool[offset % pool.count]
                // Keep checklists (shopping, tasks) and their widgets focused on the real entries.
                if key == ItemCategory.shopping.rawValue || key == ItemCategory.tasks.rawValue {
                    copy.isCompleted = true
                }
                let age = TimeInterval(60 + offset) * 86400
                insert(copy, createdAt: now.addingTimeInterval(-age), into: context)
            }
        }

        try? context.save()
    }

    /// Saved source screenshots with simple drawn thumbnails. Returns their ids, newest first.
    private static func seedScreenshots(into context: ModelContext, now: Date) -> [UUID] {
        let tints: [UIColor] = [.systemBrown, .systemOrange, .systemTeal, .systemIndigo, .systemPink, .systemGreen]
        return (0..<48).map { index in
            let screenshot = Screenshot()
            screenshot.createdAt = now.addingTimeInterval(-Double(index) * 20 * 3600)
            screenshot.analyzedAt = screenshot.createdAt
            screenshot.analysisStatus = .done
            screenshot.extractedItemsCount = 1 + index % 4
            screenshot.thumbnailData = thumbnail(tint: tints[index % tints.count])
            context.insert(screenshot)
            return screenshot.id
        }
    }

    /// A tiny abstract "app screenshot": dark page, tinted hero card, two text lines.
    private static func thumbnail(tint: UIColor) -> Data? {
        let size = CGSize(width: 360, height: 780)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(white: 0.11, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            tint.setFill()
            UIBezierPath(roundedRect: CGRect(x: 32, y: 110, width: 296, height: 380), cornerRadius: 28).fill()
            UIColor(white: 0.9, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 32, y: 530, width: 230, height: 30), cornerRadius: 15).fill()
            UIColor(white: 0.45, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 32, y: 584, width: 170, height: 24), cornerRadius: 12).fill()
        }
        return image.jpegData(compressionQuality: 0.8)
    }

    @discardableResult
    private static func insert(_ entry: DemoCatalogEntry, createdAt: Date, into context: ModelContext) -> CatalogItem {
        let item = CatalogItem(
            categoryKey: entry.categoryKey,
            title: entry.title,
            subtitle: entry.subtitle,
            link: entry.link,
            extra1: entry.extra1,
            extra2: entry.extra2,
            notes: entry.notes
        )
        item.createdAt = createdAt
        item.isCompleted = entry.isCompleted
        context.insert(item)
        return item
    }

    // MARK: - Scene lookups

    /// Drafts shown by the confirmation-based scenes.
    static func drafts(for scene: DemoScene) -> [DraftItem] {
        scene == .newCategory ? content.newCategoryDrafts : content.confirmationDrafts
    }

    /// Catalog item opened by the detail-based scenes.
    static func catalogItem(for scene: DemoScene, in context: ModelContext) -> CatalogItem? {
        let title: String
        switch scene {
        case .enrichment: title = content.enrichmentTitle
        case .place:      title = content.placeTitle
        default:          return nil
        }
        let descriptor = FetchDescriptor<CatalogItem>(
            predicate: #Predicate { $0.title == title },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try? context.fetch(descriptor).first
    }
}
#endif
