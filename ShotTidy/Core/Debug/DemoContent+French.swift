//
//  DemoContent+French.swift
//  ShotTidy
//
//  French demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let french = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Vins", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Vin", subtitleLabel: "Région", extra1Label: "Cépage",
                extra2Label: "Millésime", notesLabel: "Notes de dégustation"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Idées cadeaux", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Cadeau", subtitleLabel: "Pour", linkLabel: "Lien", extra1Label: "Budget"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Set café filtre en céramique", subtitle: "48,00 €",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Bonnet en laine mérinos", subtitle: "32,00 €",
                  extra1: "Northfold", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Plaid en lin", subtitle: "64,00 €",
                  extra1: "Nordhem Home", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Chaussures de trail", subtitle: "120,00 €",
                  extra1: "Summit Gear", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Planches à découper en bambou", subtitle: "38,00 €",
                  extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Porte-cartes en cuir", subtitle: "45,00 €",
                  extra1: "Fieldnote Goods", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Chargeur sans fil", subtitle: "29,99 €",
                  extra1: "Voltline", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Gourde en verre", subtitle: "24,00 €",
                  extra1: "Clearwell", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Tote bag en toile", subtitle: "22,00 €",
                  extra1: "Northfold", extra2: "EUR", isCompleted: true),

            .init(categoryKey: "places", title: "Musée d'Orsay", subtitle: "1 Rue de la Légion d'Honneur",
                  link: "https://maps.apple.com/?q=Musee+d+Orsay", extra1: "Paris", extra2: "France",
                  notes: "Visite le 18 octobre à 18h30. Nocturne jusqu'à 21h45."),
            .init(categoryKey: "places", title: "Café du Coin", subtitle: "12 Rue de Bretagne",
                  extra1: "Paris", extra2: "France", notes: "Le meilleur flat white à l'avoine du Marais."),

            .init(categoryKey: "tasks", title: "Acheter du café en grains", subtitle: "Aujourd'hui", extra1: "Haute"),
            .init(categoryKey: "tasks", title: "Prendre rendez-vous chez le dentiste", subtitle: "3 oct.",
                  extra1: "Moyenne"),
            .init(categoryKey: "tasks", title: "Renouveler le passeport", subtitle: "20 oct.", extra1: "Haute"),
            .init(categoryKey: "tasks", title: "Organiser la rando du week-end", subtitle: "Samedi", extra1: "Basse"),
            .init(categoryKey: "tasks", title: "Envoyer la facture à Emma", subtitle: "Vendredi", extra1: "Haute",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Payer la facture d'électricité", subtitle: "10 sept.",
                  extra1: "Moyenne", isCompleted: true),
            .init(categoryKey: "tasks", title: "Arroser les plantes", subtitle: "Hier", extra1: "Basse",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Steak en croûte de café",
                  subtitle: "Entrecôte, café moulu, paprika fumé, cassonade",
                  extra1: "30 min", extra2: "Américaine"),
            .init(categoryKey: "books", title: "Pensées pour moi-même", subtitle: "Marc Aurèle",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Philosophie", extra2: "vers 180 apr. J.-C."),
            .init(categoryKey: "health", title: "Pas de café après 14 h pour mieux dormir",
                  subtitle: "Sommeil", extra1: "Coach sommeil"),
            .init(categoryKey: "articles", title: "Comment le café affecte votre sommeil",
                  subtitle: "Santé Hebdo", extra1: "Santé"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Le temps passé à discuter à table après le repas", extra1: "Espagnol"),
            .init(categoryKey: "prompts", title: "Agis comme un planificateur de voyage et crée un itinéraire de 3 jours à Lisbonne",
                  subtitle: "Voyage", extra1: "Assistant IA"),
            .init(categoryKey: "quotes", title: "Bien faire vaut mieux que bien dire.",
                  subtitle: "Benjamin Franklin"),
            .init(categoryKey: "movies", title: "Metropolis", subtitle: "Streaming", extra1: "Science-fiction",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Créez des habitudes quotidiennes", extra1: "iOS", extra2: "Productivité"),
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+33 1 55 50 01 42",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Designer produit"),
            .init(categoryKey: winesKey, title: "Rioja Reserva", subtitle: "Rioja, Espagne",
                  extra1: "Tempranillo", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Affiche carte du ciel", subtitle: "Alex", extra1: "49 €"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "Pensées pour moi-même",
        placeTitle: "Musée d'Orsay",
        searchQuery: "café",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Support d'écran en noyer",
                      subtitle: "89,00 €", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Sous-main en lin",
                      subtitle: "34,00 €", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Lampe de bureau en laiton",
                      subtitle: "129,00 €", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Walden",
                      subtitle: "Henry David Thoreau", extra1: "Récit de nature"),
            DraftItem(categoryKey: "places", title: "Showroom Oakline Studio",
                      subtitle: "18 Rue Charlot", extra1: "Paris"),
            DraftItem(categoryKey: "tasks", title: "Commander la lampe avant la fin des soldes",
                      subtitle: "Vendredi", extra1: "Haute"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Monstera deliciosa",
                      subtitle: "Lumière vive, indirecte", extra1: "42,00 €", suggestedCategoryName: "Plantes"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Figuier lyre",
                      subtitle: "Arroser une fois par semaine", extra1: "58,00 €", suggestedCategoryName: "Plantes"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Sansevieria",
                      subtitle: "Supporte la faible lumière", extra1: "26,00 €", suggestedCategoryName: "Plantes"),
            DraftItem(categoryKey: giftsKey, title: "Mini terrarium de succulentes",
                      subtitle: "Maman", extra1: "35 €"),
            DraftItem(categoryKey: "shopping", title: "Lot de pots en terre cuite",
                      subtitle: "28,00 €", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Saumon citron et herbes",
                             subtitle: "Saumon, citron, aneth, ail, huile d'olive",
                             extra1: "25 min", extra2: "Méditerranéenne"),
            PendingDraftItem(categoryKey: "shopping", title: "Poêle en fonte, 26 cm",
                             subtitle: "39,90 €", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Acheter de l'aneth frais et des citrons",
                             subtitle: "Demain", extra1: "Moyenne"),
        ]
    )
}
#endif
