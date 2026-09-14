//
//  DemoContent+Korean.swift
//  ShotTidy
//
//  Korean demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let korean = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "와인", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "와인", subtitleLabel: "산지", extra1Label: "품종",
                extra2Label: "빈티지", notesLabel: "테이스팅 노트"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "선물 아이디어", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "선물", subtitleLabel: "받는 사람", linkLabel: "링크", extra1Label: "예산"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "도자기 핸드드립 커피 세트", subtitle: "59,000원",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "KRW"),
            .init(categoryKey: "shopping", title: "메리노 울 비니", subtitle: "39,000원",
                  extra1: "Northfold", extra2: "KRW"),
            .init(categoryKey: "shopping", title: "린넨 블랭킷", subtitle: "79,000원",
                  extra1: "Nordhem Home", extra2: "KRW"),
            .init(categoryKey: "shopping", title: "트레일 러닝화", subtitle: "159,000원",
                  extra1: "Summit Gear", extra2: "KRW"),
            .init(categoryKey: "shopping", title: "대나무 도마 세트", subtitle: "45,000원",
                  extra1: "Hearth & Clay", extra2: "KRW"),
            .init(categoryKey: "shopping", title: "가죽 카드지갑", subtitle: "55,000원",
                  extra1: "Fieldnote Goods", extra2: "KRW"),
            .init(categoryKey: "shopping", title: "무선 충전 패드", subtitle: "35,000원",
                  extra1: "Voltline", extra2: "KRW", isCompleted: true),
            .init(categoryKey: "shopping", title: "유리 물병", subtitle: "29,000원",
                  extra1: "Clearwell", extra2: "KRW", isCompleted: true),
            .init(categoryKey: "shopping", title: "캔버스 토트백", subtitle: "25,000원",
                  extra1: "Northfold", extra2: "KRW", isCompleted: true),

            .init(categoryKey: "places", title: "경복궁", subtitle: "사직로 161",
                  link: "https://maps.apple.com/?q=Gyeongbokgung", extra1: "서울", extra2: "대한민국",
                  notes: "10월 18일 오후 6시 30분 야간 관람. 한복 대여 예약 완료."),
            .init(categoryKey: "places", title: "모퉁이 커피바", subtitle: "성수이로 12",
                  extra1: "서울", extra2: "대한민국", notes: "성수동 최고의 오트 플랫화이트."),

            .init(categoryKey: "tasks", title: "원두 커피 사기", subtitle: "오늘", extra1: "높음"),
            .init(categoryKey: "tasks", title: "치과 예약하기", subtitle: "10월 3일", extra1: "보통"),
            .init(categoryKey: "tasks", title: "여권 갱신하기", subtitle: "10월 20일", extra1: "높음"),
            .init(categoryKey: "tasks", title: "주말 등산 계획 세우기", subtitle: "토요일", extra1: "낮음"),
            .init(categoryKey: "tasks", title: "엠마에게 청구서 보내기", subtitle: "금요일", extra1: "높음",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "전기요금 내기", subtitle: "9월 10일", extra1: "보통",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "화분에 물 주기", subtitle: "어제", extra1: "낮음",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "커피 럽 스테이크",
                  subtitle: "립아이, 분쇄 커피, 훈제 파프리카, 황설탕",
                  extra1: "30분", extra2: "미국식"),
            .init(categoryKey: "books", title: "명상록", subtitle: "마르쿠스 아우렐리우스",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "철학", extra2: "180년경"),
            .init(categoryKey: "health", title: "숙면을 위해 오후 2시 이후 커피 금지",
                  subtitle: "수면", extra1: "수면 코치"),
            .init(categoryKey: "articles", title: "커피가 수면에 미치는 영향",
                  subtitle: "헬스 위클리", extra1: "건강"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "식사 후 식탁에서 나누는 대화의 시간", extra1: "스페인어"),
            .init(categoryKey: "prompts", title: "여행 플래너가 되어 리스본 3일 일정을 짜 줘",
                  subtitle: "여행 계획", extra1: "AI 어시스턴트"),
            .init(categoryKey: "quotes", title: "잘한 것이 잘 말한 것보다 낫다.",
                  subtitle: "벤저민 프랭클린"),
            .init(categoryKey: "movies", title: "메트로폴리스", subtitle: "스트리밍", extra1: "SF", extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "연속 기록으로 매일 습관 만들기", extra1: "iOS", extra2: "생산성"),
            .init(categoryKey: "contacts", title: "엠마 카터", subtitle: "02-555-0142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "프로덕트 디자이너"),
            .init(categoryKey: winesKey, title: "리오하 레세르바", subtitle: "스페인 리오하",
                  extra1: "템프라니요", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "별자리 지도 포스터", subtitle: "알렉스", extra1: "59,000원"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "명상록",
        placeTitle: "경복궁",
        searchQuery: "커피",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "월넛 모니터 받침대",
                      subtitle: "119,000원", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "린넨 데스크 매트",
                      subtitle: "45,000원", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "황동 데스크 램프",
                      subtitle: "169,000원", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "월든",
                      subtitle: "헨리 데이비드 소로", extra1: "자연 에세이"),
            DraftItem(categoryKey: "places", title: "Oakline Studio 쇼룸",
                      subtitle: "도산대로 18", extra1: "서울"),
            DraftItem(categoryKey: "tasks", title: "세일 끝나기 전에 램프 주문하기",
                      subtitle: "금요일", extra1: "높음"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "몬스테라",
                      subtitle: "밝은 간접광", extra1: "52,000원", suggestedCategoryName: "식물"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "떡갈잎고무나무",
                      subtitle: "일주일에 한 번 물 주기", extra1: "69,000원", suggestedCategoryName: "식물"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "산세베리아",
                      subtitle: "그늘에서도 잘 자람", extra1: "32,000원", suggestedCategoryName: "식물"),
            DraftItem(categoryKey: giftsKey, title: "미니 다육이 테라리움",
                      subtitle: "엄마", extra1: "40,000원"),
            DraftItem(categoryKey: "shopping", title: "테라코타 화분 세트",
                      subtitle: "35,000원", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "레몬 허브 연어구이",
                             subtitle: "연어, 레몬, 딜, 마늘, 올리브유",
                             extra1: "25분", extra2: "지중해식"),
            PendingDraftItem(categoryKey: "shopping", title: "무쇠 스킬렛 26cm",
                             subtitle: "49,000원", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "딜과 레몬 사기",
                             subtitle: "내일", extra1: "보통"),
        ]
    )
}
#endif
