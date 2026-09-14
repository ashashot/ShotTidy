//
//  DemoContent+Armenian.swift
//  ShotTidy
//
//  Armenian demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let armenian = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Գինիներ", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Գինի", subtitleLabel: "Տարածաշրջան", extra1Label: "Խաղողի տեսակ",
                extra2Label: "Բերքի տարի", notesLabel: "Համտեսի նշումներ"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Նվերի գաղափարներ", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Նվեր", subtitleLabel: "Ում համար", linkLabel: "Հղում", extra1Label: "Բյուջե"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Կերամիկական սուրճի ֆիլտրի հավաքածու", subtitle: "18 900 ֏",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "AMD"),
            .init(categoryKey: "shopping", title: "Մերինոսի բրդյա գլխարկ", subtitle: "12 500 ֏",
                  extra1: "Northfold", extra2: "AMD"),
            .init(categoryKey: "shopping", title: "Վուշե ծածկոց", subtitle: "24 900 ֏",
                  extra1: "Nordhem Home", extra2: "AMD"),
            .init(categoryKey: "shopping", title: "Տրեյլ վազքի կոշիկներ", subtitle: "46 000 ֏",
                  extra1: "Summit Gear", extra2: "AMD"),
            .init(categoryKey: "shopping", title: "Բամբուկե կտրատման տախտակներ", subtitle: "14 500 ֏",
                  extra1: "Hearth & Clay", extra2: "AMD"),
            .init(categoryKey: "shopping", title: "Կաշվե քարտապահ", subtitle: "17 500 ֏",
                  extra1: "Fieldnote Goods", extra2: "AMD"),
            .init(categoryKey: "shopping", title: "Անլար լիցքավորիչ", subtitle: "11 900 ֏",
                  extra1: "Voltline", extra2: "AMD", isCompleted: true),
            .init(categoryKey: "shopping", title: "Ապակե ջրի շիշ", subtitle: "9 500 ֏",
                  extra1: "Clearwell", extra2: "AMD", isCompleted: true),
            .init(categoryKey: "shopping", title: "Կտավե պայուսակ", subtitle: "8 500 ֏",
                  extra1: "Northfold", extra2: "AMD", isCompleted: true),

            // Apple's geocoder does not resolve Armenian-script addresses; Latin street,
            // city and country (as on local street signs) keep the map card working.
            .init(categoryKey: "places", title: "Կասկադ", subtitle: "Tamanyan St 10",
                  link: "https://maps.apple.com/?q=Cascade+Complex+Yerevan", extra1: "Yerevan", extra2: "Armenia",
                  notes: "Մայրամուտին զբոսանք՝ 18.10.2026, 18:30։ Հետո ընթրիք Աբովյան փողոցում։"),
            .init(categoryKey: "places", title: "Սուրճի անկյուն", subtitle: "Աբովյան 12",
                  extra1: "Երևան", extra2: "Հայաստան", notes: "Քաղաքի լավագույն վարսակի կաթով ֆլեթ ուայթը։"),

            .init(categoryKey: "tasks", title: "Սուրճի հատիկներ գնել", subtitle: "Այսօր", extra1: "Բարձր"),
            .init(categoryKey: "tasks", title: "Գրանցվել ատամնաբույժի մոտ", subtitle: "Հոկտ. 3", extra1: "Միջին"),
            .init(categoryKey: "tasks", title: "Թարմացնել անձնագիրը", subtitle: "Հոկտ. 20", extra1: "Բարձր"),
            .init(categoryKey: "tasks", title: "Պլանավորել շաբաթավերջի արշավը", subtitle: "Շաբաթ",
                  extra1: "Ցածր"),
            .init(categoryKey: "tasks", title: "Հաշիվն ուղարկել Էմմային", subtitle: "Ուրբաթ", extra1: "Բարձր",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Վճարել հոսանքի վարձը", subtitle: "Սեպտ. 10", extra1: "Միջին",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Ջրել բույսերը", subtitle: "Երեկ", extra1: "Ցածր",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Սուրճով պատված սթեյք",
                  subtitle: "Ռիբայ, աղացած սուրճ, ապխտած պապրիկա, շագանակագույն շաքար",
                  extra1: "30 րոպե", extra2: "Ամերիկյան"),
            .init(categoryKey: "books", title: "Խորհրդածություններ", subtitle: "Մարկոս Ավրելիոս",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Փիլիսոփայություն", extra2: "մ.թ. մոտ 180"),
            .init(categoryKey: "health", title: "Ժամը 14-ից հետո սուրճ չխմել՝ ավելի լավ քնելու համար",
                  subtitle: "Քուն", extra1: "Քնի մասնագետ"),
            .init(categoryKey: "articles", title: "Ինչպես է սուրճն ազդում քնի վրա",
                  subtitle: "Առողջություն շաբաթական", extra1: "Առողջություն"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Ճաշից հետո սեղանի շուրջ զրույցի ժամանակը", extra1: "Իսպաներեն"),
            .init(categoryKey: "prompts", title: "Որպես ճամփորդությունների պլանավորող՝ կազմիր Լիսաբոնի 3-օրյա երթուղի",
                  subtitle: "Ճամփորդություն", extra1: "ԱԲ օգնական"),
            .init(categoryKey: "quotes", title: "Լավ արվածն ավելի լավ է, քան լավ ասվածը։",
                  subtitle: "Բենջամին Ֆրանկլին"),
            .init(categoryKey: "movies", title: "Մետրոպոլիս", subtitle: "Սթրիմինգ", extra1: "Գիտաֆանտաստիկա",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Ամենօրյա սովորություններ՝ շարքերով", extra1: "iOS", extra2: "Արդյունավետություն"),
            .init(categoryKey: "contacts", title: "Էմմա Քարթեր", subtitle: "+374 10 555 142",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Պրոդուկտի դիզայներ"),
            .init(categoryKey: winesKey, title: "Արենի Ռեզերվ", subtitle: "Վայոց ձոր, Հայաստան",
                  extra1: "Արենի", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Աստղային քարտեզի պաստառ", subtitle: "Ալեքս", extra1: "20 000 ֏"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "Խորհրդածություններ",
        placeTitle: "Կասկադ",
        searchQuery: "սուրճ",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Ընկուզենու մոնիտորի տակդիր",
                      subtitle: "34 900 ֏", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Վուշե սեղանի գորգ",
                      subtitle: "12 900 ֏", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Արույրե սեղանի լամպ",
                      subtitle: "49 900 ֏", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Ուոլդեն",
                      subtitle: "Հենրի Դեյվիդ Թորո", extra1: "Բնության մասին գրականություն"),
            DraftItem(categoryKey: "places", title: "Oakline Studio ցուցասրահ",
                      subtitle: "Սայաթ-Նովայի 18", extra1: "Երևան"),
            DraftItem(categoryKey: "tasks", title: "Պատվիրել լամպը մինչ զեղչերի ավարտը",
                      subtitle: "Ուրբաթ", extra1: "Բարձր"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Մոնստերա",
                      subtitle: "Պայծառ, ցրված լույս", extra1: "16 900 ֏", suggestedCategoryName: "Բույսեր"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Ֆիկուս լիրատա",
                      subtitle: "Ջրել շաբաթը մեկ անգամ", extra1: "22 900 ֏", suggestedCategoryName: "Բույսեր"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Սանսևիերիա",
                      subtitle: "Հանդուրժում է քիչ լույսը", extra1: "9 900 ֏", suggestedCategoryName: "Բույսեր"),
            DraftItem(categoryKey: giftsKey, title: "Մինի սուկուլենտային տերարիում",
                      subtitle: "Մայրիկ", extra1: "14 000 ֏"),
            DraftItem(categoryKey: "shopping", title: "Կավե ծաղկամանների հավաքածու",
                      subtitle: "11 500 ֏", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Կիտրոնով և կանաչիով սաղմոն",
                             subtitle: "Սաղմոն, կիտրոն, սամիթ, սխտոր, ձիթապտղի յուղ",
                             extra1: "25 րոպե", extra2: "Միջերկրածովյան"),
            PendingDraftItem(categoryKey: "shopping", title: "Թուջե տապակ, 26 սմ",
                             subtitle: "15 900 ֏", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Գնել թարմ սամիթ և կիտրոն",
                             subtitle: "Վաղը", extra1: "Միջին"),
        ]
    )
}
#endif
