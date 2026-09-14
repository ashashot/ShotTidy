//
//  DemoContent+ChineseSimplified.swift
//  ShotTidy
//
//  Simplified Chinese demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let chineseSimplified = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "葡萄酒", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "酒名", subtitleLabel: "产区", extra1Label: "葡萄品种",
                extra2Label: "年份", notesLabel: "品鉴笔记"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "礼物清单", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "礼物", subtitleLabel: "送给", linkLabel: "链接", extra1Label: "预算"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "陶瓷手冲咖啡套装", subtitle: "¥328",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "CNY"),
            .init(categoryKey: "shopping", title: "美利奴羊毛帽", subtitle: "¥219",
                  extra1: "Northfold", extra2: "CNY"),
            .init(categoryKey: "shopping", title: "亚麻盖毯", subtitle: "¥429",
                  extra1: "Nordhem Home", extra2: "CNY"),
            .init(categoryKey: "shopping", title: "越野跑鞋", subtitle: "¥899",
                  extra1: "Summit Gear", extra2: "CNY"),
            .init(categoryKey: "shopping", title: "竹制砧板套装", subtitle: "¥259",
                  extra1: "Hearth & Clay", extra2: "CNY"),
            .init(categoryKey: "shopping", title: "真皮卡包", subtitle: "¥299",
                  extra1: "Fieldnote Goods", extra2: "CNY"),
            .init(categoryKey: "shopping", title: "无线充电板", subtitle: "¥199",
                  extra1: "Voltline", extra2: "CNY", isCompleted: true),
            .init(categoryKey: "shopping", title: "玻璃水瓶", subtitle: "¥159",
                  extra1: "Clearwell", extra2: "CNY", isCompleted: true),
            .init(categoryKey: "shopping", title: "帆布托特包", subtitle: "¥129",
                  extra1: "Northfold", extra2: "CNY", isCompleted: true),

            .init(categoryKey: "places", title: "外滩", subtitle: "中山东一路",
                  link: "https://maps.apple.com/?q=The+Bund+Shanghai", extra1: "上海", extra2: "中国",
                  notes: "10月18日 18:30 去看夜景，之后在南京路吃晚饭。"),
            .init(categoryKey: "places", title: "街角咖啡馆", subtitle: "安福路 12 号",
                  extra1: "上海", extra2: "中国", notes: "燕麦拿铁是这一带最好喝的。"),

            .init(categoryKey: "tasks", title: "买咖啡豆", subtitle: "今天", extra1: "高"),
            .init(categoryKey: "tasks", title: "预约牙医", subtitle: "10月3日", extra1: "中"),
            .init(categoryKey: "tasks", title: "续签护照", subtitle: "10月20日", extra1: "高"),
            .init(categoryKey: "tasks", title: "计划周末徒步", subtitle: "周六", extra1: "低"),
            .init(categoryKey: "tasks", title: "给 Emma 发发票", subtitle: "周五", extra1: "高",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "交电费", subtitle: "9月10日", extra1: "中",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "给植物浇水", subtitle: "昨天", extra1: "低",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "咖啡香煎牛排",
                  subtitle: "肋眼牛排、咖啡粉、烟熏红椒粉、红糖",
                  extra1: "30 分钟", extra2: "美式"),
            .init(categoryKey: "books", title: "沉思录", subtitle: "马可·奥勒留",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "哲学", extra2: "约公元 180 年"),
            .init(categoryKey: "health", title: "下午两点后不喝咖啡，睡得更好",
                  subtitle: "睡眠", extra1: "睡眠教练"),
            .init(categoryKey: "articles", title: "咖啡如何影响你的睡眠",
                  subtitle: "健康周刊", extra1: "健康"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "饭后留在餐桌边聊天的时光", extra1: "西班牙语"),
            .init(categoryKey: "prompts", title: "你是一名旅行规划师，请制定里斯本 3 日行程",
                  subtitle: "旅行规划", extra1: "AI 助手"),
            .init(categoryKey: "quotes", title: "做得好比说得好更重要。",
                  subtitle: "本杰明·富兰克林"),
            .init(categoryKey: "movies", title: "大都会", subtitle: "流媒体", extra1: "科幻", extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "用连续打卡养成每日习惯", extra1: "iOS", extra2: "效率"),
            .init(categoryKey: "contacts", title: "Emma Carter", subtitle: "+86 21 5555 0142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "产品设计师"),
            .init(categoryKey: winesKey, title: "里奥哈珍藏", subtitle: "西班牙里奥哈",
                  extra1: "丹魄", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "星空地图海报", subtitle: "Alex", extra1: "¥299"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "沉思录",
        placeTitle: "外滩",
        searchQuery: "咖啡",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "胡桃木显示器增高架",
                      subtitle: "¥699", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "亚麻桌垫",
                      subtitle: "¥199", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "黄铜台灯",
                      subtitle: "¥899", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "瓦尔登湖",
                      subtitle: "亨利·戴维·梭罗", extra1: "自然文学"),
            DraftItem(categoryKey: "places", title: "Oakline Studio 展厅",
                      subtitle: "武康路 18 号", extra1: "上海"),
            DraftItem(categoryKey: "tasks", title: "促销结束前下单台灯",
                      subtitle: "周五", extra1: "高"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "龟背竹",
                      subtitle: "明亮散射光", extra1: "¥168", suggestedCategoryName: "绿植"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "琴叶榕",
                      subtitle: "每周浇水一次", extra1: "¥239", suggestedCategoryName: "绿植"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "虎尾兰",
                      subtitle: "耐阴好养", extra1: "¥89", suggestedCategoryName: "绿植"),
            DraftItem(categoryKey: giftsKey, title: "迷你多肉微景观",
                      subtitle: "妈妈", extra1: "¥159"),
            DraftItem(categoryKey: "shopping", title: "陶土花盆套装",
                      subtitle: "¥129", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "柠檬香草三文鱼",
                             subtitle: "三文鱼、柠檬、莳萝、大蒜、橄榄油",
                             extra1: "25 分钟", extra2: "地中海风味"),
            PendingDraftItem(categoryKey: "shopping", title: "铸铁煎锅 26cm",
                             subtitle: "¥289", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "买新鲜莳萝和柠檬",
                             subtitle: "明天", extra1: "中"),
        ]
    )
}
#endif
