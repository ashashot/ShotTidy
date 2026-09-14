//
//  DemoContent+German.swift
//  ShotTidy
//
//  German demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let german = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Weine", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Wein", subtitleLabel: "Region", extra1Label: "Rebsorte",
                extra2Label: "Jahrgang", notesLabel: "Verkostungsnotizen"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Geschenkideen", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Geschenk", subtitleLabel: "Für", linkLabel: "Link", extra1Label: "Budget"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Keramik-Kaffeefilter-Set", subtitle: "48,00 €",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Mütze aus Merinowolle", subtitle: "32,00 €",
                  extra1: "Northfold", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Leinen-Wohndecke", subtitle: "64,00 €",
                  extra1: "Nordhem Home", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Trailrunning-Schuhe", subtitle: "120,00 €",
                  extra1: "Summit Gear", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Bambus-Schneidebretter", subtitle: "38,00 €",
                  extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Kartenetui aus Leder", subtitle: "45,00 €",
                  extra1: "Fieldnote Goods", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Kabelloses Ladepad", subtitle: "29,99 €",
                  extra1: "Voltline", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Glas-Trinkflasche", subtitle: "24,00 €",
                  extra1: "Clearwell", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Canvas-Tragetasche", subtitle: "22,00 €",
                  extra1: "Northfold", extra2: "EUR", isCompleted: true),

            .init(categoryKey: "places", title: "Brandenburger Tor", subtitle: "Pariser Platz",
                  link: "https://maps.apple.com/?q=Brandenburger+Tor", extra1: "Berlin", extra2: "Deutschland",
                  notes: "Abendspaziergang am 18. Oktober um 18:30 Uhr. Danach Essen in Mitte."),
            .init(categoryKey: "places", title: "Eckbohne Kaffeebar", subtitle: "Weinbergsweg 12",
                  extra1: "Berlin", extra2: "Deutschland", notes: "Bester Hafer-Flat-White in Mitte."),

            .init(categoryKey: "tasks", title: "Kaffeebohnen kaufen", subtitle: "Heute", extra1: "Hoch"),
            .init(categoryKey: "tasks", title: "Zahnarzttermin vereinbaren", subtitle: "3. Okt.", extra1: "Mittel"),
            .init(categoryKey: "tasks", title: "Reisepass verlängern", subtitle: "20. Okt.", extra1: "Hoch"),
            .init(categoryKey: "tasks", title: "Wochenendwanderung planen", subtitle: "Samstag", extra1: "Niedrig"),
            .init(categoryKey: "tasks", title: "Rechnung an Emma senden", subtitle: "Freitag", extra1: "Hoch",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Stromrechnung bezahlen", subtitle: "10. Sep.", extra1: "Mittel",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Pflanzen gießen", subtitle: "Gestern", extra1: "Niedrig",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Steak mit Kaffeekruste",
                  subtitle: "Rib-Eye, gemahlener Kaffee, Rauchpaprika, brauner Zucker",
                  extra1: "30 Min.", extra2: "Amerikanisch"),
            .init(categoryKey: "books", title: "Selbstbetrachtungen", subtitle: "Mark Aurel",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Philosophie", extra2: "um 180 n. Chr."),
            .init(categoryKey: "health", title: "Nach 14 Uhr kein Kaffee für besseren Schlaf",
                  subtitle: "Schlaf", extra1: "Schlafcoach"),
            .init(categoryKey: "articles", title: "Wie Kaffee deinen Schlaf beeinflusst",
                  subtitle: "Gesundheit Aktuell", extra1: "Gesundheit"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Zeit, die man nach dem Essen am Tisch plaudert", extra1: "Spanisch"),
            .init(categoryKey: "prompts", title: "Plane als Reiseberater eine 3-tägige Reise nach Lissabon",
                  subtitle: "Reiseplanung", extra1: "KI-Assistent"),
            .init(categoryKey: "quotes", title: "Gut gemacht ist besser als gut gesagt.",
                  subtitle: "Benjamin Franklin"),
            .init(categoryKey: "movies", title: "Metropolis", subtitle: "Streaming", extra1: "Science-Fiction",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Tägliche Gewohnheiten mit Serien aufbauen", extra1: "iOS", extra2: "Produktivität"),
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+49 30 5550142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Produktdesignerin"),
            .init(categoryKey: winesKey, title: "Rioja Reserva", subtitle: "Rioja, Spanien",
                  extra1: "Tempranillo", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Sternkarten-Poster", subtitle: "Alex", extra1: "49 €"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "Selbstbetrachtungen",
        placeTitle: "Brandenburger Tor",
        searchQuery: "Kaffee",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Monitorständer aus Walnuss",
                      subtitle: "89,00 €", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Schreibtischunterlage aus Leinen",
                      subtitle: "34,00 €", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Schreibtischlampe aus Messing",
                      subtitle: "129,00 €", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Walden",
                      subtitle: "Henry David Thoreau", extra1: "Naturliteratur"),
            DraftItem(categoryKey: "places", title: "Oakline Studio Showroom",
                      subtitle: "Torstraße 18", extra1: "Berlin"),
            DraftItem(categoryKey: "tasks", title: "Lampe vor Ende des Sales bestellen",
                      subtitle: "Freitag", extra1: "Hoch"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Monstera deliciosa",
                      subtitle: "Hell, ohne direkte Sonne", extra1: "42,00 €", suggestedCategoryName: "Pflanzen"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Geigenfeige",
                      subtitle: "Einmal pro Woche gießen", extra1: "58,00 €", suggestedCategoryName: "Pflanzen"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Bogenhanf",
                      subtitle: "Kommt mit wenig Licht aus", extra1: "26,00 €", suggestedCategoryName: "Pflanzen"),
            DraftItem(categoryKey: giftsKey, title: "Mini-Sukkulenten-Terrarium",
                      subtitle: "Mama", extra1: "35 €"),
            DraftItem(categoryKey: "shopping", title: "Terrakotta-Topf-Set",
                      subtitle: "28,00 €", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Zitronen-Kräuter-Lachs",
                             subtitle: "Lachs, Zitrone, Dill, Knoblauch, Olivenöl",
                             extra1: "25 Min.", extra2: "Mediterran"),
            PendingDraftItem(categoryKey: "shopping", title: "Gusseisenpfanne, 26 cm",
                             subtitle: "39,90 €", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Frischen Dill und Zitronen kaufen",
                             subtitle: "Morgen", extra1: "Mittel"),
        ]
    )
}
#endif
