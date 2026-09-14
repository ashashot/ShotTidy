//
//  DemoContent+Turkish.swift
//  ShotTidy
//
//  Turkish demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let turkish = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Şaraplar", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Şarap", subtitleLabel: "Bölge", extra1Label: "Üzüm",
                extra2Label: "Rekolte", notesLabel: "Tadım Notları"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Hediye Fikirleri", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Hediye", subtitleLabel: "Kime", linkLabel: "Bağlantı", extra1Label: "Bütçe"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Seramik filtre kahve seti", subtitle: "1.490 TL",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "TRY"),
            .init(categoryKey: "shopping", title: "Merinos yün bere", subtitle: "990 TL",
                  extra1: "Northfold", extra2: "TRY"),
            .init(categoryKey: "shopping", title: "Keten battaniye", subtitle: "1.990 TL",
                  extra1: "Nordhem Home", extra2: "TRY"),
            .init(categoryKey: "shopping", title: "Patika koşu ayakkabısı", subtitle: "3.750 TL",
                  extra1: "Summit Gear", extra2: "TRY"),
            .init(categoryKey: "shopping", title: "Bambu kesme tahtası seti", subtitle: "1.190 TL",
                  extra1: "Hearth & Clay", extra2: "TRY"),
            .init(categoryKey: "shopping", title: "Deri kartlık", subtitle: "1.390 TL",
                  extra1: "Fieldnote Goods", extra2: "TRY"),
            .init(categoryKey: "shopping", title: "Kablosuz şarj pedi", subtitle: "899 TL",
                  extra1: "Voltline", extra2: "TRY", isCompleted: true),
            .init(categoryKey: "shopping", title: "Cam su şişesi", subtitle: "749 TL",
                  extra1: "Clearwell", extra2: "TRY", isCompleted: true),
            .init(categoryKey: "shopping", title: "Kanvas çanta", subtitle: "690 TL",
                  extra1: "Northfold", extra2: "TRY", isCompleted: true),

            .init(categoryKey: "places", title: "Galata Kulesi", subtitle: "Bereketzade, Galata Kulesi Sk.",
                  link: "https://maps.apple.com/?q=Galata+Kulesi", extra1: "İstanbul", extra2: "Türkiye",
                  notes: "18 Ekim saat 18:30'da gün batımı ziyareti. Biletler çevrim içi."),
            .init(categoryKey: "places", title: "Köşe Kahve Barı", subtitle: "Moda Cd. 12, Kadıköy",
                  extra1: "İstanbul", extra2: "Türkiye", notes: "Kadıköy'ün en iyi yulaf sütlü flat white'ı."),

            .init(categoryKey: "tasks", title: "Çekirdek kahve al", subtitle: "Bugün", extra1: "Yüksek"),
            .init(categoryKey: "tasks", title: "Diş hekimi randevusu al", subtitle: "3 Ekim", extra1: "Orta"),
            .init(categoryKey: "tasks", title: "Pasaportu yenile", subtitle: "20 Ekim", extra1: "Yüksek"),
            .init(categoryKey: "tasks", title: "Hafta sonu yürüyüşünü planla", subtitle: "Cumartesi",
                  extra1: "Düşük"),
            .init(categoryKey: "tasks", title: "Emma'ya faturayı gönder", subtitle: "Cuma", extra1: "Yüksek",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Elektrik faturasını öde", subtitle: "10 Eylül", extra1: "Orta",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Bitkileri sula", subtitle: "Dün", extra1: "Düşük",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Kahveli biftek",
                  subtitle: "Antrikot, çekilmiş kahve, füme paprika, esmer şeker",
                  extra1: "30 dk", extra2: "Amerikan"),
            .init(categoryKey: "books", title: "Kendime Düşünceler", subtitle: "Marcus Aurelius",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Felsefe", extra2: "MS 180 civarı"),
            .init(categoryKey: "health", title: "Daha iyi uyku için 14:00'ten sonra kahve yok",
                  subtitle: "Uyku", extra1: "Uyku koçu"),
            .init(categoryKey: "articles", title: "Kahve uykunuzu nasıl etkiler?",
                  subtitle: "Sağlık Haftalık", extra1: "Sağlık"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Yemekten sonra sofrada sohbetle geçen zaman", extra1: "İspanyolca"),
            .init(categoryKey: "prompts", title: "Bir seyahat planlayıcısı gibi davran ve Lizbon için 3 günlük bir rota hazırla",
                  subtitle: "Seyahat", extra1: "Yapay zekâ asistanı"),
            .init(categoryKey: "quotes", title: "İyi yapılmış, iyi söylenmişten iyidir.",
                  subtitle: "Benjamin Franklin"),
            .init(categoryKey: "movies", title: "Metropolis", subtitle: "Dijital platform", extra1: "Bilim kurgu",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Seriyle günlük alışkanlıklar edinin", extra1: "iOS", extra2: "Verimlilik"),
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+90 212 555 01 42",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Ürün tasarımcısı"),
            .init(categoryKey: winesKey, title: "Rioja Reserva", subtitle: "Rioja, İspanya",
                  extra1: "Tempranillo", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Yıldız haritası posteri", subtitle: "Alex", extra1: "1.200 TL"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "Kendime Düşünceler",
        placeTitle: "Galata Kulesi",
        searchQuery: "kahve",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Ceviz monitör standı",
                      subtitle: "2.890 TL", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Keten masa matı",
                      subtitle: "1.090 TL", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Pirinç masa lambası",
                      subtitle: "4.290 TL", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Walden",
                      subtitle: "Henry David Thoreau", extra1: "Doğa yazını"),
            DraftItem(categoryKey: "places", title: "Oakline Studio Showroom",
                      subtitle: "Serdar-ı Ekrem Sk. 18", extra1: "İstanbul"),
            DraftItem(categoryKey: "tasks", title: "İndirim bitmeden lambayı sipariş et",
                      subtitle: "Cuma", extra1: "Yüksek"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Deve tabanı (Monstera)",
                      subtitle: "Parlak, dolaylı ışık", extra1: "1.390 TL", suggestedCategoryName: "Bitkiler"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Keman yapraklı incir",
                      subtitle: "Haftada bir sula", extra1: "1.890 TL", suggestedCategoryName: "Bitkiler"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Paşa kılıcı",
                      subtitle: "Az ışığa dayanıklı", extra1: "790 TL", suggestedCategoryName: "Bitkiler"),
            DraftItem(categoryKey: giftsKey, title: "Mini sukulent teraryum",
                      subtitle: "Annem", extra1: "1.100 TL"),
            DraftItem(categoryKey: "shopping", title: "Toprak saksı seti",
                      subtitle: "890 TL", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Limonlu ve otlu somon",
                             subtitle: "Somon, limon, dereotu, sarımsak, zeytinyağı",
                             extra1: "25 dk", extra2: "Akdeniz"),
            PendingDraftItem(categoryKey: "shopping", title: "Döküm tava, 26 cm",
                             subtitle: "1.290 TL", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Taze dereotu ve limon al",
                             subtitle: "Yarın", extra1: "Orta"),
        ]
    )
}
#endif
