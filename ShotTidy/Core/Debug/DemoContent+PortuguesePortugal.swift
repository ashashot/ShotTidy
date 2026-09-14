//
//  DemoContent+PortuguesePortugal.swift
//  ShotTidy
//
//  European Portuguese demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let portuguesePortugal = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Vinhos", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Vinho", subtitleLabel: "Região", extra1Label: "Casta",
                extra2Label: "Colheita", notesLabel: "Notas de prova"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Ideias de presentes", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Presente", subtitleLabel: "Para", linkLabel: "Ligação", extra1Label: "Orçamento"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Conjunto de café de filtro em cerâmica", subtitle: "48,00 €",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Gorro de lã merino", subtitle: "32,00 €",
                  extra1: "Northfold", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Manta de linho", subtitle: "64,00 €",
                  extra1: "Nordhem Home", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Sapatilhas de trail", subtitle: "120,00 €",
                  extra1: "Summit Gear", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Tábuas de corte de bambu", subtitle: "38,00 €",
                  extra1: "Hearth & Clay", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Porta-cartões em pele", subtitle: "45,00 €",
                  extra1: "Fieldnote Goods", extra2: "EUR"),
            .init(categoryKey: "shopping", title: "Carregador sem fios", subtitle: "29,99 €",
                  extra1: "Voltline", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Garrafa de vidro", subtitle: "24,00 €",
                  extra1: "Clearwell", extra2: "EUR", isCompleted: true),
            .init(categoryKey: "shopping", title: "Saco de lona", subtitle: "22,00 €",
                  extra1: "Northfold", extra2: "EUR", isCompleted: true),

            .init(categoryKey: "places", title: "Castelo de São Jorge", subtitle: "Rua de Santa Cruz do Castelo",
                  link: "https://maps.apple.com/?q=Castelo+de+Sao+Jorge", extra1: "Lisboa", extra2: "Portugal",
                  notes: "Visita ao pôr do sol a 18 de outubro às 18:30. Comprar bilhete online."),
            .init(categoryKey: "places", title: "Café da Esquina", subtitle: "Rua da Rosa, 12",
                  extra1: "Lisboa", extra2: "Portugal", notes: "O melhor flat white de aveia do Bairro Alto."),

            .init(categoryKey: "tasks", title: "Comprar café em grão", subtitle: "Hoje", extra1: "Alta"),
            .init(categoryKey: "tasks", title: "Marcar consulta no dentista", subtitle: "3 de out.", extra1: "Média"),
            .init(categoryKey: "tasks", title: "Renovar o passaporte", subtitle: "20 de out.", extra1: "Alta"),
            .init(categoryKey: "tasks", title: "Planear a caminhada do fim de semana", subtitle: "Sábado",
                  extra1: "Baixa"),
            .init(categoryKey: "tasks", title: "Enviar a fatura à Emma", subtitle: "Sexta", extra1: "Alta",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Pagar a conta da luz", subtitle: "10 de set.", extra1: "Média",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Regar as plantas", subtitle: "Ontem", extra1: "Baixa",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Bife com crosta de café",
                  subtitle: "Vazia, café moído, pimentão-doce fumado, açúcar amarelo",
                  extra1: "30 min", extra2: "Americana"),
            .init(categoryKey: "books", title: "Meditações", subtitle: "Marco Aurélio",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Filosofia", extra2: "c. 180 d.C."),
            .init(categoryKey: "health", title: "Nada de café depois das 14h para dormir melhor",
                  subtitle: "Sono", extra1: "Coach de sono"),
            .init(categoryKey: "articles", title: "Como o café afeta o sono",
                  subtitle: "Saúde Semanal", extra1: "Saúde"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Tempo de conversa à mesa depois da refeição", extra1: "Espanhol"),
            .init(categoryKey: "prompts", title: "Age como planeador de viagens e cria um roteiro de 3 dias em Madrid",
                  subtitle: "Viagens", extra1: "Assistente de IA"),
            .init(categoryKey: "quotes", title: "Bem feito é melhor do que bem dito.",
                  subtitle: "Benjamin Franklin"),
            .init(categoryKey: "movies", title: "Metrópolis", subtitle: "Streaming", extra1: "Ficção científica",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Cria hábitos diários com sequências", extra1: "iOS", extra2: "Produtividade"),
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+351 21 555 0142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Designer de produto"),
            .init(categoryKey: winesKey, title: "Rioja Reserva", subtitle: "Rioja, Espanha",
                  extra1: "Tempranillo", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Póster mapa das estrelas", subtitle: "Alex", extra1: "49 €"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "Meditações",
        placeTitle: "Castelo de São Jorge",
        searchQuery: "café",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Suporte de monitor em nogueira",
                      subtitle: "89,00 €", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Base de secretária em linho",
                      subtitle: "34,00 €", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Candeeiro de secretária em latão",
                      subtitle: "129,00 €", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Walden",
                      subtitle: "Henry David Thoreau", extra1: "Literatura de natureza"),
            DraftItem(categoryKey: "places", title: "Showroom Oakline Studio",
                      subtitle: "Rua do Alecrim, 18", extra1: "Lisboa"),
            DraftItem(categoryKey: "tasks", title: "Encomendar o candeeiro antes do fim dos saldos",
                      subtitle: "Sexta", extra1: "Alta"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Monstera deliciosa",
                      subtitle: "Luz intensa e indireta", extra1: "42,00 €", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Figueira-lira",
                      subtitle: "Regar uma vez por semana", extra1: "58,00 €", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Sansevieria",
                      subtitle: "Tolera pouca luz", extra1: "26,00 €", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: giftsKey, title: "Mini terrário de suculentas",
                      subtitle: "Mãe", extra1: "35 €"),
            DraftItem(categoryKey: "shopping", title: "Conjunto de vasos de terracota",
                      subtitle: "28,00 €", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Salmão com limão e ervas",
                             subtitle: "Salmão, limão, endro, alho, azeite",
                             extra1: "25 min", extra2: "Mediterrânica"),
            PendingDraftItem(categoryKey: "shopping", title: "Frigideira de ferro fundido, 26 cm",
                             subtitle: "39,90 €", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Comprar endro fresco e limões",
                             subtitle: "Amanhã", extra1: "Média"),
        ]
    )
}
#endif
