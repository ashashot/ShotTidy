//
//  ItemCategory.swift
//  ShotTidy
//
//  Категории каталога с описанием полей для каждой из них.
//

import SwiftUI

// MARK: - ItemCategory

enum ItemCategory: String, CaseIterable, Codable, Hashable {
    case shopping        = "shopping"
    case places          = "places"
    case appsServices    = "appsServices"
    case languageLearning = "languageLearning"
    case prompts         = "prompts"
    case health          = "health"
    case recipes         = "recipes"
    case books           = "books"
    case movies          = "movies"
    case quotes          = "quotes"
    case articles        = "articles"
    case contacts        = "contacts"
    case tasks           = "tasks"

    var localizedName: String {
        switch self {
        case .shopping:         return "Покупки"
        case .places:           return "Места"
        case .appsServices:     return "Приложения и Сервисы"
        case .languageLearning: return "Изучение языков"
        case .prompts:          return "Промты"
        case .health:           return "Здоровье"
        case .recipes:          return "Рецепты"
        case .books:            return "Книги"
        case .movies:           return "Фильмы и Сериалы"
        case .quotes:           return "Цитаты"
        case .articles:         return "Статьи"
        case .contacts:         return "Контакты"
        case .tasks:            return "Задачи"
        }
    }

    var icon: String {
        switch self {
        case .shopping:         return "cart.fill"
        case .places:           return "mappin.circle.fill"
        case .appsServices:     return "app.fill"
        case .languageLearning: return "textformat.abc"
        case .prompts:          return "text.bubble.fill"
        case .health:           return "heart.fill"
        case .recipes:          return "fork.knife"
        case .books:            return "book.fill"
        case .movies:           return "play.rectangle.fill"
        case .quotes:           return "quote.bubble.fill"
        case .articles:         return "newspaper.fill"
        case .contacts:         return "person.circle.fill"
        case .tasks:            return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .shopping:         return .orange
        case .places:           return Color(red: 0.88, green: 0.18, blue: 0.18)
        case .appsServices:     return .blue
        case .languageLearning: return Color(red: 0.18, green: 0.75, blue: 0.35)
        case .prompts:          return .purple
        case .health:           return .pink
        case .recipes:          return Color(red: 0.92, green: 0.67, blue: 0.12)
        case .books:            return Color(red: 0.6, green: 0.38, blue: 0.18)
        case .movies:           return .indigo
        case .quotes:           return .teal
        case .articles:         return Color(red: 0.0, green: 0.65, blue: 0.85)
        case .contacts:         return Color(red: 0.12, green: 0.72, blue: 0.72)
        case .tasks:            return Color(red: 0.48, green: 0.48, blue: 0.56)
        }
    }

    // MARK: - Field Schema

    struct FieldSchema {
        let titleLabel: String
        let titlePlaceholder: String
        let subtitleLabel: String?
        let subtitlePlaceholder: String?
        let linkLabel: String?
        let linkPlaceholder: String?
        let extra1Label: String?
        let extra1Placeholder: String?
        let extra2Label: String?
        let extra2Placeholder: String?
        let notesLabel: String?
        let notesPlaceholder: String?
        var isLinkEmail: Bool = false
    }

    var fieldSchema: FieldSchema {
        switch self {
        case .shopping:
            return FieldSchema(
                titleLabel: "Название товара", titlePlaceholder: "Например: Nike Air Max 270",
                subtitleLabel: "Цена", subtitlePlaceholder: "Например: 12 990",
                linkLabel: "Ссылка", linkPlaceholder: "https://...",
                extra1Label: "Магазин", extra1Placeholder: "Wildberries / Ozon / Amazon",
                extra2Label: "Валюта", extra2Placeholder: "RUB / USD / EUR",
                notesLabel: "Заметки", notesPlaceholder: "Дополнительная информация"
            )
        case .places:
            return FieldSchema(
                titleLabel: "Название места", titlePlaceholder: "Кафе Пушкин / Музей Эрмитаж",
                subtitleLabel: "Адрес", subtitlePlaceholder: "Тверской бульвар, 26А",
                linkLabel: "Ссылка / Карты", linkPlaceholder: "https://maps.apple.com/...",
                extra1Label: "Город", extra1Placeholder: "Москва",
                extra2Label: "Страна", extra2Placeholder: "Россия",
                notesLabel: "Заметки", notesPlaceholder: "Режим работы, описание..."
            )
        case .appsServices:
            return FieldSchema(
                titleLabel: "Название", titlePlaceholder: "Notion / Figma / Telegram",
                subtitleLabel: "Описание", subtitlePlaceholder: "Краткое описание сервиса",
                linkLabel: "Ссылка", linkPlaceholder: "https://...",
                extra1Label: "Платформа", extra1Placeholder: "iOS / Android / Web / macOS",
                extra2Label: "Категория", extra2Placeholder: "Продуктивность / Дизайн",
                notesLabel: "Заметки", notesPlaceholder: "Что понравилось / зачем нужно"
            )
        case .languageLearning:
            return FieldSchema(
                titleLabel: "Слово / Фраза / Текст", titlePlaceholder: "Слово или выражение для изучения",
                subtitleLabel: "Перевод", subtitlePlaceholder: "Перевод на русский",
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: "Язык", extra1Placeholder: "Английский / Испанский",
                extra2Label: "Пример использования", extra2Placeholder: "I need to leverage my skills",
                notesLabel: "Контекст", notesPlaceholder: "Откуда взято, дополнительные примеры"
            )
        case .prompts:
            return FieldSchema(
                titleLabel: "Текст промта", titlePlaceholder: "Act as a professional...",
                subtitleLabel: "Назначение", subtitlePlaceholder: "Для чего используется",
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: "AI-инструмент", extra1Placeholder: "ChatGPT / Claude / Midjourney",
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Заметки", notesPlaceholder: "Результаты, улучшения"
            )
        case .health:
            return FieldSchema(
                titleLabel: "Рекомендация / Информация", titlePlaceholder: "Текст о здоровье",
                subtitleLabel: "Тип", subtitlePlaceholder: "Лекарство / Упражнение / Диета",
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: "Источник", extra1Placeholder: "Врач / Приложение / Статья",
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Дополнительно", notesPlaceholder: "Дозировка, противопоказания..."
            )
        case .recipes:
            return FieldSchema(
                titleLabel: "Название блюда", titlePlaceholder: "Борщ / Паста карбонара",
                subtitleLabel: "Ингредиенты", subtitlePlaceholder: "Список ингредиентов",
                linkLabel: "Ссылка на рецепт", linkPlaceholder: "https://...",
                extra1Label: "Время приготовления", extra1Placeholder: "30 минут",
                extra2Label: "Кухня", extra2Placeholder: "Русская / Итальянская",
                notesLabel: "Шаги приготовления", notesPlaceholder: "1. Нарезать... 2. Обжарить..."
            )
        case .books:
            return FieldSchema(
                titleLabel: "Название книги", titlePlaceholder: "Мастер и Маргарита",
                subtitleLabel: "Автор", subtitlePlaceholder: "Михаил Булгаков",
                linkLabel: "Купить / Читать", linkPlaceholder: "https://...",
                extra1Label: "Жанр", extra1Placeholder: "Роман / Нон-фикшн / Биография",
                extra2Label: "Год", extra2Placeholder: "2024",
                notesLabel: "Заметки", notesPlaceholder: "Впечатления, цитаты..."
            )
        case .movies:
            return FieldSchema(
                titleLabel: "Название", titlePlaceholder: "Начало / Succession",
                subtitleLabel: "Платформа", subtitlePlaceholder: "Netflix / Кинопоиск / IVI",
                linkLabel: "Смотреть", linkPlaceholder: "https://...",
                extra1Label: "Жанр", extra1Placeholder: "Триллер / Комедия / Документальный",
                extra2Label: "Год", extra2Placeholder: "2024",
                notesLabel: "Заметки", notesPlaceholder: "Почему хочу посмотреть..."
            )
        case .quotes:
            return FieldSchema(
                titleLabel: "Цитата", titlePlaceholder: "Текст цитаты",
                subtitleLabel: "Автор", subtitlePlaceholder: "Имя автора",
                linkLabel: "Источник", linkPlaceholder: "Книга / Статья / URL",
                extra1Label: nil, extra1Placeholder: nil,
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Заметки", notesPlaceholder: "Почему важна эта цитата"
            )
        case .articles:
            return FieldSchema(
                titleLabel: "Заголовок статьи", titlePlaceholder: "Название статьи",
                subtitleLabel: "Источник / Издание", subtitlePlaceholder: "Habr / Medium / TechCrunch",
                linkLabel: "Ссылка", linkPlaceholder: "https://...",
                extra1Label: "Тема", extra1Placeholder: "Технологии / Наука / Бизнес",
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Краткое содержание", notesPlaceholder: "Основные мысли статьи"
            )
        case .contacts:
            return FieldSchema(
                titleLabel: "Имя", titlePlaceholder: "Иван Петров",
                subtitleLabel: "Телефон", subtitlePlaceholder: "+7 900 000-00-00",
                linkLabel: "Email", linkPlaceholder: "email@example.com",
                extra1Label: "Компания", extra1Placeholder: "Название компании",
                extra2Label: "Должность", extra2Placeholder: "CEO / Дизайнер / Разработчик",
                notesLabel: "Заметки", notesPlaceholder: "Где познакомились, о чём говорили",
                isLinkEmail: true
            )
        case .tasks:
            return FieldSchema(
                titleLabel: "Задача", titlePlaceholder: "Описание задачи",
                subtitleLabel: "Срок", subtitlePlaceholder: "25 мая / до конца недели",
                linkLabel: nil, linkPlaceholder: nil,
                extra1Label: "Приоритет", extra1Placeholder: "Высокий / Средний / Низкий",
                extra2Label: nil, extra2Placeholder: nil,
                notesLabel: "Детали", notesPlaceholder: "Дополнительные детали задачи"
            )
        }
    }
}
