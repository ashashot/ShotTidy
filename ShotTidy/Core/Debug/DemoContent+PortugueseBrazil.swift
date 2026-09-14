//
//  DemoContent+PortugueseBrazil.swift
//  ShotTidy
//
//  Brazilian Portuguese demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let portugueseBrazil = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Vinhos", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Vinho", subtitleLabel: "Região", extra1Label: "Uva",
                extra2Label: "Safra", notesLabel: "Notas de degustação"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Ideias de presente", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Presente", subtitleLabel: "Para", linkLabel: "Link", extra1Label: "Orçamento"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Kit de café coado de cerâmica", subtitle: "R$ 189,90",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "BRL"),
            .init(categoryKey: "shopping", title: "Gorro de lã merino", subtitle: "R$ 129,90",
                  extra1: "Northfold", extra2: "BRL"),
            .init(categoryKey: "shopping", title: "Manta de linho", subtitle: "R$ 249,00",
                  extra1: "Nordhem Home", extra2: "BRL"),
            .init(categoryKey: "shopping", title: "Tênis de trail running", subtitle: "R$ 599,00",
                  extra1: "Summit Gear", extra2: "BRL"),
            .init(categoryKey: "shopping", title: "Tábuas de corte de bambu", subtitle: "R$ 149,90",
                  extra1: "Hearth & Clay", extra2: "BRL"),
            .init(categoryKey: "shopping", title: "Porta-cartões de couro", subtitle: "R$ 179,00",
                  extra1: "Fieldnote Goods", extra2: "BRL"),
            .init(categoryKey: "shopping", title: "Carregador sem fio", subtitle: "R$ 119,90",
                  extra1: "Voltline", extra2: "BRL", isCompleted: true),
            .init(categoryKey: "shopping", title: "Garrafa de vidro", subtitle: "R$ 89,90",
                  extra1: "Clearwell", extra2: "BRL", isCompleted: true),
            .init(categoryKey: "shopping", title: "Ecobag de lona", subtitle: "R$ 79,90",
                  extra1: "Northfold", extra2: "BRL", isCompleted: true),

            .init(categoryKey: "places", title: "MASP", subtitle: "Av. Paulista, 1578",
                  link: "https://maps.apple.com/?q=MASP+Sao+Paulo", extra1: "São Paulo", extra2: "Brasil",
                  notes: "Visita à exposição em 18 de outubro às 16h30. Ingressos já comprados."),
            .init(categoryKey: "places", title: "Café da Esquina", subtitle: "Rua Augusta, 1200",
                  extra1: "São Paulo", extra2: "Brasil", notes: "Melhor flat white com leite de aveia da Augusta."),

            .init(categoryKey: "tasks", title: "Comprar café em grãos", subtitle: "Hoje", extra1: "Alta"),
            .init(categoryKey: "tasks", title: "Marcar dentista", subtitle: "3 de out.", extra1: "Média"),
            .init(categoryKey: "tasks", title: "Renovar o passaporte", subtitle: "20 de out.", extra1: "Alta"),
            .init(categoryKey: "tasks", title: "Planejar a trilha do fim de semana", subtitle: "Sábado",
                  extra1: "Baixa"),
            .init(categoryKey: "tasks", title: "Enviar nota fiscal para Emma", subtitle: "Sexta", extra1: "Alta",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Pagar a conta de luz", subtitle: "10 de set.", extra1: "Média",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Regar as plantas", subtitle: "Ontem", extra1: "Baixa",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Bife com crosta de café",
                  subtitle: "Contrafilé, café moído, páprica defumada, açúcar mascavo",
                  extra1: "30 min", extra2: "Americana"),
            .init(categoryKey: "books", title: "Meditações", subtitle: "Marco Aurélio",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Filosofia", extra2: "c. 180 d.C."),
            .init(categoryKey: "health", title: "Nada de café depois das 14h para dormir melhor",
                  subtitle: "Sono", extra1: "Coach de sono"),
            .init(categoryKey: "articles", title: "Como o café afeta o seu sono",
                  subtitle: "Saúde em Dia", extra1: "Saúde"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Tempo de conversa à mesa depois da refeição", extra1: "Espanhol"),
            .init(categoryKey: "prompts", title: "Aja como planejador de viagens e monte um roteiro de 3 dias em Lisboa",
                  subtitle: "Viagens", extra1: "Assistente de IA"),
            .init(categoryKey: "quotes", title: "Bem feito é melhor do que bem dito.",
                  subtitle: "Benjamin Franklin"),
            .init(categoryKey: "movies", title: "Metrópolis", subtitle: "Streaming", extra1: "Ficção científica",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Crie hábitos diários com sequências", extra1: "iOS", extra2: "Produtividade"),
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+55 11 5550-0142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Designer de produto"),
            .init(categoryKey: winesKey, title: "Rioja Reserva", subtitle: "Rioja, Espanha",
                  extra1: "Tempranillo", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Pôster mapa das estrelas", subtitle: "Alex", extra1: "R$ 149"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "Meditações",
        placeTitle: "MASP",
        searchQuery: "café",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Suporte de monitor de nogueira",
                      subtitle: "R$ 349,00", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Deskpad de linho",
                      subtitle: "R$ 129,00", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Luminária de mesa de latão",
                      subtitle: "R$ 489,00", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Walden",
                      subtitle: "Henry David Thoreau", extra1: "Literatura de natureza"),
            DraftItem(categoryKey: "places", title: "Showroom Oakline Studio",
                      subtitle: "Rua Oscar Freire, 18", extra1: "São Paulo"),
            DraftItem(categoryKey: "tasks", title: "Comprar a luminária antes do fim da promoção",
                      subtitle: "Sexta", extra1: "Alta"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Costela-de-adão",
                      subtitle: "Luz clara e indireta", extra1: "R$ 159,00", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Figueira-lira",
                      subtitle: "Regar uma vez por semana", extra1: "R$ 219,00", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Espada-de-são-jorge",
                      subtitle: "Tolera pouca luz", extra1: "R$ 89,00", suggestedCategoryName: "Plantas"),
            DraftItem(categoryKey: giftsKey, title: "Mini terrário de suculentas",
                      subtitle: "Mãe", extra1: "R$ 120"),
            DraftItem(categoryKey: "shopping", title: "Kit de vasos de terracota",
                      subtitle: "R$ 99,90", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Salmão com limão e ervas",
                             subtitle: "Salmão, limão, endro, alho, azeite",
                             extra1: "25 min", extra2: "Mediterrânea"),
            PendingDraftItem(categoryKey: "shopping", title: "Frigideira de ferro fundido, 26 cm",
                             subtitle: "R$ 159,90", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Comprar endro fresco e limões",
                             subtitle: "Amanhã", extra1: "Média"),
        ]
    )
}
#endif
