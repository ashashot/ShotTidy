//
//  DemoContent+Spanish.swift
//  ShotTidy
//
//  Spanish demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let spanish = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Vinos", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Vino", subtitleLabel: "Región", extra1Label: "Uva",
                extra2Label: "Añada", notesLabel: "Notas de cata"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Ideas de regalo", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Regalo", subtitleLabel: "Para", linkLabel: "Enlace", extra1Label: "Presupuesto"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Set de café de filtro de cerámica", subtitle: "48,00 €",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Gorro de lana merino", subtitle: "32,00 €",
                  extra1: "Northfold", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Manta de lino", subtitle: "64,00 €",
                  extra1: "Nordhem Home", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Zapatillas de trail running", subtitle: "120,00 €",
                  extra1: "Summit Gear", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Tablas de cortar de bambú", subtitle: "38,00 €",
                  extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Tarjetero de piel", subtitle: "45,00 €",
                  extra1: "Fieldnote Goods", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Cargador inalámbrico", subtitle: "29,99 €",
                  extra1: "Voltline", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Botella de vidrio", subtitle: "24,00 €",
                  extra1: "Clearwell", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Bolsa de lona", subtitle: "22,00 €",
                  extra1: "Northfold", extra2: "EUR", isCompleted: true),

            .init(categoryKey: "places", title: "Parque del Retiro", subtitle: "Plaza de la Independencia, 7",
                  link: "https://maps.apple.com/?q=Parque+del+Retiro", extra1: "Madrid", extra2: "España",
                  notes: "Paseo en barca el 18 de octubre a las 18:30. Entrada libre."),
            .init(categoryKey: "places", title: "Café La Esquina", subtitle: "Calle de Fuencarral, 45",
                  extra1: "Madrid", extra2: "España", notes: "El mejor flat white con avena de Malasaña."),

            .init(categoryKey: "tasks", title: "Comprar café en grano", subtitle: "Hoy", extra1: "Alta"),
            .init(categoryKey: "tasks", title: "Pedir cita con el dentista", subtitle: "3 oct.", extra1: "Media"),
            .init(categoryKey: "tasks", title: "Renovar el pasaporte", subtitle: "20 oct.", extra1: "Alta"),
            .init(categoryKey: "tasks", title: "Planear la ruta del finde", subtitle: "Sábado", extra1: "Baja"),
            .init(categoryKey: "tasks", title: "Enviar la factura a Emma", subtitle: "Viernes", extra1: "Alta",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Pagar la luz", subtitle: "10 sept.", extra1: "Media",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Regar las plantas", subtitle: "Ayer", extra1: "Baja",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Filete con costra de café",
                  subtitle: "Entrecot, café molido, pimentón ahumado, azúcar moreno",
                  extra1: "30 min", extra2: "Americana"),
            .init(categoryKey: "books", title: "Meditaciones", subtitle: "Marco Aurelio",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Filosofía", extra2: "c. 180 d. C."),
            .init(categoryKey: "health", title: "Nada de café después de las 14:00 para dormir mejor",
                  subtitle: "Sueño", extra1: "Coach del sueño"),
            .init(categoryKey: "articles", title: "Cómo afecta el café a tu sueño",
                  subtitle: "Salud Semanal", extra1: "Salud"),
            .init(categoryKey: "languageLearning", title: "Hygge",
                  subtitle: "Sensación de calidez, comodidad y bienestar", extra1: "Danés"),
            .init(categoryKey: "prompts", title: "Actúa como planificador de viajes y crea un itinerario de 3 días por Lisboa",
                  subtitle: "Viajes", extra1: "Asistente de IA"),
            .init(categoryKey: "quotes", title: "Bien hecho es mejor que bien dicho.",
                  subtitle: "Benjamin Franklin"),
            .init(categoryKey: "movies", title: "Metrópolis", subtitle: "Streaming", extra1: "Ciencia ficción",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Crea hábitos diarios con rachas", extra1: "iOS", extra2: "Productividad"),
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+34 915 55 01 42",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Diseñadora de producto"),
            .init(categoryKey: winesKey, title: "Rioja Reserva", subtitle: "Rioja, España",
                  extra1: "Tempranillo", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Póster de mapa estelar", subtitle: "Alex", extra1: "49 €"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "Meditaciones",
        placeTitle: "Parque del Retiro",
        searchQuery: "café",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Soporte de monitor de nogal",
                      subtitle: "89,00 €", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Alfombrilla de escritorio de lino",
                      subtitle: "34,00 €", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Lámpara de escritorio de latón",
                      subtitle: "129,00 €", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Walden",
                      subtitle: "Henry David Thoreau", extra1: "Literatura de naturaleza"),
            DraftItem(categoryKey: "places", title: "Showroom de Oakline Studio",
                      subtitle: "Calle del Pez, 18", extra1: "Madrid"),
            DraftItem(categoryKey: "tasks", title: "Pedir la lámpara antes de que acaben las rebajas",
                      subtitle: "Viernes", extra1: "Alta"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Monstera deliciosa",
                      subtitle: "Luz brillante e indirecta", extra1: "42,00 €", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Ficus lyrata",
                      subtitle: "Regar una vez por semana", extra1: "58,00 €", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Sansevieria",
                      subtitle: "Tolera poca luz", extra1: "26,00 €", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: giftsKey, title: "Mini terrario de suculentas",
                      subtitle: "Mamá", extra1: "35 €"),
            DraftItem(categoryKey: "shopping", title: "Set de macetas de terracota",
                      subtitle: "28,00 €", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Salmón al limón con hierbas",
                             subtitle: "Salmón, limón, eneldo, ajo, aceite de oliva",
                             extra1: "25 min", extra2: "Mediterránea"),
            PendingDraftItem(categoryKey: "shopping", title: "Sartén de hierro fundido, 26 cm",
                             subtitle: "39,90 €", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Comprar eneldo fresco y limones",
                             subtitle: "Mañana", extra1: "Media"),
        ]
    )
}
#endif
