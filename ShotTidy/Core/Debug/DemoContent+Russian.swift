//
//  DemoContent+Russian.swift
//  ShotTidy
//
//  Russian demo catalog for App Store screenshots. Debug builds only.
//

#if DEBUG
import Foundation

extension DemoContent {

    static let russian = DemoContentSet(
        customCategories: [
            DemoCustomCategory(
                key: winesKey, name: "Вина", iconName: "wineglass.fill", colorHex: "#B0305C",
                titleLabel: "Вино", subtitleLabel: "Регион", extra1Label: "Сорт винограда",
                extra2Label: "Урожай", notesLabel: "Дегустационные заметки"
            ),
            DemoCustomCategory(
                key: giftsKey, name: "Идеи подарков", iconName: "gift.fill", colorHex: "#E5484D",
                titleLabel: "Подарок", subtitleLabel: "Для кого", linkLabel: "Ссылка", extra1Label: "Бюджет"
            ),
        ],
        catalog: [
            .init(categoryKey: "shopping", title: "Керамический набор для кофе пуровер", subtitle: "3 900 ₽",
                  link: "https://hearthandclay.shop/pour-over", extra1: "Hearth & Clay", extra2: "RUB"),
            .init(categoryKey: "shopping", title: "Шапка из мериносовой шерсти", subtitle: "2 490 ₽",
                  extra1: "Northfold", extra2: "RUB"),
            .init(categoryKey: "shopping", title: "Льняной плед", subtitle: "5 200 ₽",
                  extra1: "Nordhem Home", extra2: "RUB"),
            .init(categoryKey: "shopping", title: "Кроссовки для трейлраннинга", subtitle: "9 900 ₽",
                  extra1: "Summit Gear", extra2: "RUB"),
            .init(categoryKey: "shopping", title: "Бамбуковые разделочные доски", subtitle: "2 900 ₽",
                  extra1: "Hearth & Clay", extra2: "RUB"),
            .init(categoryKey: "shopping", title: "Кожаная визитница", subtitle: "3 500 ₽",
                  extra1: "Fieldnote Goods", extra2: "RUB"),
            .init(categoryKey: "shopping", title: "Беспроводная зарядка", subtitle: "2 290 ₽",
                  extra1: "Voltline", extra2: "RUB", isCompleted: true),
            .init(categoryKey: "shopping", title: "Стеклянная бутылка", subtitle: "1 890 ₽",
                  extra1: "Clearwell", extra2: "RUB", isCompleted: true),
            .init(categoryKey: "shopping", title: "Холщовая сумка", subtitle: "1 590 ₽",
                  extra1: "Northfold", extra2: "RUB", isCompleted: true),

            .init(categoryKey: "places", title: "Парк Горького", subtitle: "ул. Крымский Вал, 9",
                  link: "https://maps.apple.com/?q=Gorky+Park+Moscow", extra1: "Москва", extra2: "Россия",
                  notes: "Прогулка на закате 18 октября в 18:30. Потом ужин на набережной."),
            .init(categoryKey: "places", title: "Кофейня «Уголок»", subtitle: "ул. Покровка, 12",
                  extra1: "Москва", extra2: "Россия", notes: "Лучший флэт уайт на овсяном в центре."),

            .init(categoryKey: "tasks", title: "Купить кофе в зёрнах", subtitle: "Сегодня", extra1: "Высокий"),
            .init(categoryKey: "tasks", title: "Записаться к стоматологу", subtitle: "3 окт.", extra1: "Средний"),
            .init(categoryKey: "tasks", title: "Продлить загранпаспорт", subtitle: "20 окт.", extra1: "Высокий"),
            .init(categoryKey: "tasks", title: "Спланировать поход на выходных", subtitle: "Суббота",
                  extra1: "Низкий"),
            .init(categoryKey: "tasks", title: "Отправить счёт Эмме", subtitle: "Пятница", extra1: "Высокий",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Оплатить электричество", subtitle: "10 сент.", extra1: "Средний",
                  isCompleted: true),
            .init(categoryKey: "tasks", title: "Полить цветы", subtitle: "Вчера", extra1: "Низкий",
                  isCompleted: true),

            .init(categoryKey: "recipes", title: "Стейк в кофейной корочке",
                  subtitle: "Рибай, молотый кофе, копчёная паприка, коричневый сахар",
                  extra1: "30 мин", extra2: "Американская"),
            .init(categoryKey: "books", title: "Размышления", subtitle: "Марк Аврелий",
                  link: "https://www.gutenberg.org/ebooks/2680", extra1: "Философия", extra2: "ок. 180 г. н. э."),
            .init(categoryKey: "health", title: "Не пить кофе после 14:00 для лучшего сна",
                  subtitle: "Сон", extra1: "Сомнолог"),
            .init(categoryKey: "articles", title: "Как кофе влияет на сон",
                  subtitle: "Журнал «Здоровье»", extra1: "Здоровье"),
            .init(categoryKey: "languageLearning", title: "Sobremesa",
                  subtitle: "Время, проведённое в беседе за столом после еды", extra1: "Испанский"),
            .init(categoryKey: "prompts", title: "Выступи в роли тревел-планировщика и составь маршрут на 3 дня по Лиссабону",
                  subtitle: "Путешествия", extra1: "ИИ-ассистент"),
            .init(categoryKey: "quotes", title: "Хорошо сделанное лучше хорошо сказанного.",
                  subtitle: "Бенджамин Франклин"),
            .init(categoryKey: "movies", title: "Метрополис", subtitle: "Стриминг", extra1: "Фантастика",
                  extra2: "1927"),
            .init(categoryKey: "appsServices", title: "Habit Garden",
                  subtitle: "Полезные привычки с сериями", extra1: "iOS", extra2: "Продуктивность"),
            .init(categoryKey: "contacts", title: "Эмма Картер", subtitle: "+7 495 555-01-42",
                  link: "emma@brightpixel.studio", extra1: "Bright Pixel Studio", extra2: "Продуктовый дизайнер"),
            .init(categoryKey: winesKey, title: "Риоха Резерва", subtitle: "Риоха, Испания",
                  extra1: "Темпранильо", extra2: "2019"),
            .init(categoryKey: giftsKey, title: "Постер звёздной карты", subtitle: "Алекс", extra1: "4 000 ₽"),
        ],
        categoryTotals: defaultCategoryTotals,
        enrichmentTitle: "Размышления",
        placeTitle: "Парк Горького",
        searchQuery: "кофе",
        confirmationDrafts: [
            DraftItem(categoryKey: "shopping", title: "Подставка для монитора из ореха",
                      subtitle: "7 900 ₽", link: "https://oakline.studio/stand", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Льняной коврик для стола",
                      subtitle: "2 900 ₽", link: "https://oakline.studio/desk-mat", extra1: "Oakline Studio"),
            DraftItem(categoryKey: "shopping", title: "Латунная настольная лампа",
                      subtitle: "11 500 ₽", extra1: "Lumen & Co."),
            DraftItem(categoryKey: "books", title: "Уолден, или Жизнь в лесу",
                      subtitle: "Генри Дэвид Торо", extra1: "Проза о природе"),
            DraftItem(categoryKey: "places", title: "Шоурум Oakline Studio",
                      subtitle: "ул. Большая Никитская, 18", extra1: "Москва"),
            DraftItem(categoryKey: "tasks", title: "Заказать лампу до конца распродажи",
                      subtitle: "Пятница", extra1: "Высокий"),
        ],
        newCategoryDrafts: [
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Монстера деликатесная",
                      subtitle: "Яркий рассеянный свет", extra1: "3 400 ₽", suggestedCategoryName: "Растения"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Фикус лировидный",
                      subtitle: "Поливать раз в неделю", extra1: "4 700 ₽", suggestedCategoryName: "Растения"),
            DraftItem(categoryKey: DraftItem.newCategoryKey, title: "Сансевиерия",
                      subtitle: "Хорошо переносит тень", extra1: "2 100 ₽", suggestedCategoryName: "Растения"),
            DraftItem(categoryKey: giftsKey, title: "Мини-террариум с суккулентами",
                      subtitle: "Маме", extra1: "3 000 ₽"),
            DraftItem(categoryKey: "shopping", title: "Набор терракотовых горшков",
                      subtitle: "2 300 ₽", extra1: "Greenhouse Market"),
        ],
        shareDrafts: [
            PendingDraftItem(categoryKey: "recipes", title: "Лосось с лимоном и травами",
                             subtitle: "Лосось, лимон, укроп, чеснок, оливковое масло",
                             extra1: "25 мин", extra2: "Средиземноморская"),
            PendingDraftItem(categoryKey: "shopping", title: "Чугунная сковорода, 26 см",
                             subtitle: "3 200 ₽", extra1: "Hearth & Clay"),
            PendingDraftItem(categoryKey: "tasks", title: "Купить свежий укроп и лимоны",
                             subtitle: "Завтра", extra1: "Средний"),
        ]
    )
}
#endif
