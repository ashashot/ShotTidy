//
//  DemoContent+Japanese.swift
//  ShotTidy
//
//  Japanese demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let japanese = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "ワイン", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "ワイン名", subtitleLabel: "産地", extra1Label: "ブドウ品種",
                extra2Label: "ヴィンテージ", notesLabel: "テイスティングメモ"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "ギフトアイデア", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "ギフト", subtitleLabel: "贈る相手", linkLabel: "リンク", extra1Label: "予算"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "陶器のハンドドリップコーヒーセット", subtitle: "¥6,800",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "JPY"),
            .init(categoryKey: "shopping", title: "メリノウールのニット帽", subtitle: "¥4,400",
                  extra1: "Northfold", extra2: "JPY"),
            .init(categoryKey: "shopping", title: "リネンのブランケット", subtitle: "¥8,900",
                  extra1: "Nordhem Home", extra2: "JPY"),
            .init(categoryKey: "shopping", title: "トレイルランニングシューズ", subtitle: "¥16,500",
                  extra1: "Summit Gear", extra2: "JPY"),
            .init(categoryKey: "shopping", title: "竹のカッティングボードセット", subtitle: "¥5,200",
                  extra1: "Hearth & Clay", extra2: "JPY"),
            .init(categoryKey: "shopping", title: "レザーカードケース", subtitle: "¥6,200",
                  extra1: "Fieldnote Goods", extra2: "JPY"),
            .init(categoryKey: "shopping", title: "ワイヤレス充電パッド", subtitle: "¥3,980",
                  extra1: "Voltline", extra2: "JPY", isCompleted: true),
            .init(categoryKey: "shopping", title: "ガラスのウォーターボトル", subtitle: "¥3,300",
                  extra1: "Clearwell", extra2: "JPY", isCompleted: true),
            .init(categoryKey: "shopping", title: "キャンバストートバッグ", subtitle: "¥2,900",
                  extra1: "Northfold", extra2: "JPY", isCompleted: true),

            .init(categoryKey: "places", title: "東京タワー", subtitle: "芝公園4-2-8",
                  link: "https://maps.apple.com/?q=Tokyo+Tower", extra1: "東京", extra2: "日本",
                  notes: "10月18日 18:30 夜景を見に行く。展望デッキのチケットは購入済み。"),
            .init(categoryKey: "places", title: "角のコーヒースタンド", subtitle: "神宮前5-12-3",
                  extra1: "東京", extra2: "日本", notes: "オーツミルクのフラットホワイトが最高。"),

            .init(categoryKey: "tasks", title: "コーヒー豆を買う", subtitle: "今日", extra1: "高"),
            .init(categoryKey: "tasks", title: "歯医者を予約する", subtitle: "10月3日", extra1: "中"),
            .init(categoryKey: "tasks", title: "パスポートを更新する", subtitle: "10月20日", extra1: "高"),
            .init(categoryKey: "tasks", title: "週末のハイキングを計画する", subtitle: "土曜日", extra1: "低"),
            .init(categoryKey: "tasks", title: "エマに請求書を送る", subtitle: "金曜日", extra1: "高",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "電気代を払う", subtitle: "9月10日", extra1: "中",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "植物に水をやる", subtitle: "昨日", extra1: "低",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "コーヒー風味のステーキ",
                  subtitle: "リブロース、挽いたコーヒー、スモークパプリカ、ブラウンシュガー",
                  extra1: "30分", extra2: "アメリカ料理"),
            .init(categoryKey: "books", title: "自省録", subtitle: "マルクス・アウレリウス",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "哲学", extra2: "180年頃"),
            .init(categoryKey: "health", title: "よく眠るために14時以降はコーヒーを控える",
                  subtitle: "睡眠", extra1: "睡眠コーチ"),
            .init(categoryKey: "articles", title: "コーヒーが睡眠に与える影響",
                  subtitle: "ヘルスウィークリー", extra1: "健康"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "食後に食卓で会話を楽しむ時間", extra1: "スペイン語"),
            .init(categoryKey: "prompts", title: "旅行プランナーとしてリスボン3日間の旅程を作って",
                  subtitle: "旅行計画", extra1: "AIアシスタント"),
            .init(categoryKey: "quotes", title: "よくできたことは、よく言われたことに勝る。",
                  subtitle: "ベンジャミン・フランクリン"),
            .init(categoryKey: "movies", title: "メトロポリス", subtitle: "配信", extra1: "SF", extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "継続記録で毎日の習慣づくり", extra1: "iOS", extra2: "仕事効率化"),
            .init(categoryKey: "contacts", title: "エマ・カーター", subtitle: "03-5550-0142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "プロダクトデザイナー"),
            .init(categoryKey: winesKey, title: "リオハ レゼルバ", subtitle: "スペイン・リオハ",
                  extra1: "テンプラニーリョ", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "星座マップのポスター", subtitle: "アレックス", extra1: "¥6,000"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "自省録",
        placeTitle: "東京タワー",
        searchQuery: "コーヒー",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "ウォールナットのモニタースタンド",
                      subtitle: "¥12,800", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "リネンのデスクマット",
                      subtitle: "¥4,900", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "真鍮のデスクランプ",
                      subtitle: "¥18,700", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "森の生活（ウォールデン）",
                      subtitle: "ヘンリー・D・ソロー", extra1: "ネイチャーライティング"),
            DraftItem(categoryKey: "places", title: "Oakline Studio ショールーム",
                      subtitle: "代官山町18-1", extra1: "東京"),
            DraftItem(categoryKey: "tasks", title: "セールが終わる前にランプを注文する",
                      subtitle: "金曜日", extra1: "高"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "モンステラ",
                      subtitle: "明るい日陰で育てる", extra1: "¥5,800", suggestedCategoryName: "観葉植物"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "フィドルリーフフィグ",
                      subtitle: "週に1回水やり", extra1: "¥7,900", suggestedCategoryName: "観葉植物"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "サンスベリア",
                      subtitle: "日陰にも強い", extra1: "¥3,500", suggestedCategoryName: "観葉植物"),
            DraftItem(categoryKey: giftsKey, title: "ミニ多肉植物テラリウム",
                      subtitle: "母", extra1: "¥4,500"),
            DraftItem(categoryKey: "shopping", title: "テラコッタ鉢セット",
                      subtitle: "¥3,800", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "サーモンのレモンハーブ焼き",
                             subtitle: "サーモン、レモン、ディル、にんにく、オリーブオイル",
                             extra1: "25分", extra2: "地中海料理"),
            PendingDraftItem(categoryKey: "shopping", title: "鋳鉄スキレット 26cm",
                             subtitle: "¥5,400", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "ディルとレモンを買う",
                             subtitle: "明日", extra1: "中"),
        ]
    )
}
#endif
