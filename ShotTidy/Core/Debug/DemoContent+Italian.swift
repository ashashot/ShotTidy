//
//  DemoContent+Italian.swift
//  ShotTidy
//
//  Italian demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let italian = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Vini", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Vino", subtitleLabel: "Regione", extra1Label: "Vitigno",
                extra2Label: "Annata", notesLabel: "Note di degustazione"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Idee regalo", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Regalo", subtitleLabel: "Per", linkLabel: "Link", extra1Label: "Budget"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Set per caffè filtro in ceramica", subtitle: "48,00 €",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Berretto in lana merino", subtitle: "32,00 €",
                  extra1: "Northfold", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Plaid in lino", subtitle: "64,00 €",
                  extra1: "Nordhem Home", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Scarpe da trail running", subtitle: "120,00 €",
                  extra1: "Summit Gear", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Taglieri in bambù", subtitle: "38,00 €",
                  extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Porta carte in pelle", subtitle: "45,00 €",
                  extra1: "Fieldnote Goods", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Caricatore wireless", subtitle: "29,99 €",
                  extra1: "Voltline", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Borraccia in vetro", subtitle: "24,00 €",
                  extra1: "Clearwell", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Borsa in tela", subtitle: "22,00 €",
                  extra1: "Northfold", extra2: "EUR", isCompleted: true),

            .init(categoryKey: "places", title: "Colosseo", subtitle: "Piazza del Colosseo, 1",
                  link: "https://maps.apple.com/?q=Colosseo", extra1: "Roma", extra2: "Italia",
                  notes: "Visita al tramonto il 18 ottobre alle 18:30. Biglietto già prenotato."),
            .init(categoryKey: "places", title: "Caffè dell'Angolo", subtitle: "Via del Governo Vecchio, 12",
                  extra1: "Roma", extra2: "Italia", notes: "Il miglior flat white d'avena del centro."),

            .init(categoryKey: "tasks", title: "Comprare caffè in grani", subtitle: "Oggi", extra1: "Alta"),
            .init(categoryKey: "tasks", title: "Prenotare il dentista", subtitle: "3 ott.", extra1: "Media"),
            .init(categoryKey: "tasks", title: "Rinnovare il passaporto", subtitle: "20 ott.", extra1: "Alta"),
            .init(categoryKey: "tasks", title: "Organizzare l'escursione del weekend", subtitle: "Sabato",
                  extra1: "Bassa"),
            .init(categoryKey: "tasks", title: "Inviare la fattura a Emma", subtitle: "Venerdì", extra1: "Alta",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Pagare la bolletta della luce", subtitle: "10 set.", extra1: "Media",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Annaffiare le piante", subtitle: "Ieri", extra1: "Bassa",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Bistecca in crosta di caffè",
                  subtitle: "Costata, caffè macinato, paprika affumicata, zucchero di canna",
                  extra1: "30 min", extra2: "Americana"),
            .init(categoryKey: "books", title: "A se stesso", subtitle: "Marco Aurelio",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Filosofia", extra2: "circa 180 d.C."),
            .init(categoryKey: "health", title: "Niente caffè dopo le 14 per dormire meglio",
                  subtitle: "Sonno", extra1: "Sleep coach"),
            .init(categoryKey: "articles", title: "Come il caffè influisce sul sonno",
                  subtitle: "Salute Settimanale", extra1: "Salute"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Il tempo passato a chiacchierare a tavola dopo il pasto", extra1: "Spagnolo"),
            .init(categoryKey: "prompts", title: "Agisci come travel planner e crea un itinerario di 3 giorni a Lisbona",
                  subtitle: "Viaggi", extra1: "Assistente IA"),
            .init(categoryKey: "quotes", title: "Ben fatto è meglio di ben detto.",
                  subtitle: "Benjamin Franklin"),
            .init(categoryKey: "movies", title: "Metropolis", subtitle: "Streaming", extra1: "Fantascienza",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Crea abitudini quotidiane con le serie", extra1: "iOS", extra2: "Produttività"),
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+39 06 5550 142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Product designer"),
            .init(categoryKey: winesKey, title: "Rioja Reserva", subtitle: "Rioja, Spagna",
                  extra1: "Tempranillo", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Poster mappa stellare", subtitle: "Alex", extra1: "49 €"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "A se stesso",
        placeTitle: "Colosseo",
        searchQuery: "caffè",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Supporto monitor in noce",
                      subtitle: "89,00 €", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Sottomano in lino",
                      subtitle: "34,00 €", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Lampada da scrivania in ottone",
                      subtitle: "129,00 €", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Walden",
                      subtitle: "Henry David Thoreau", extra1: "Letteratura di natura"),
            DraftItem(categoryKey: "places", title: "Showroom Oakline Studio",
                      subtitle: "Via Tortona, 18", extra1: "Milano"),
            DraftItem(categoryKey: "tasks", title: "Ordinare la lampada prima della fine dei saldi",
                      subtitle: "Venerdì", extra1: "Alta"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Monstera deliciosa",
                      subtitle: "Luce intensa e indiretta", extra1: "42,00 €", suggestedCategoryName: "Piante"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Ficus lyrata",
                      subtitle: "Annaffiare una volta a settimana", extra1: "58,00 €", suggestedCategoryName: "Piante"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Sansevieria",
                      subtitle: "Tollera la poca luce", extra1: "26,00 €", suggestedCategoryName: "Piante"),
            DraftItem(categoryKey: giftsKey, title: "Mini terrario di piante grasse",
                      subtitle: "Mamma", extra1: "35 €"),
            DraftItem(categoryKey: "shopping", title: "Set di vasi in terracotta",
                      subtitle: "28,00 €", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Salmone al limone ed erbe",
                             subtitle: "Salmone, limone, aneto, aglio, olio d'oliva",
                             extra1: "25 min", extra2: "Mediterranea"),
            PendingDraftItem(categoryKey: "shopping", title: "Padella in ghisa, 26 cm",
                             subtitle: "39,90 €", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Comprare aneto fresco e limoni",
                             subtitle: "Domani", extra1: "Media"),
        ]
    )
}
#endif
