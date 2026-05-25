//
//  CatalogItem.swift
//  ShotTidy
//
//  Универсальная SwiftData модель для всех категорий каталога.
//  Все поля Optional или имеют значение по умолчанию — требование CloudKit.
//

import Foundation
import SwiftData

@Model
final class CatalogItem {

    // MARK: - Идентификаторы
    var id: UUID = UUID()
    var categoryRaw: String = ""

    // MARK: - Основные поля (гибкая схема, семантика зависит от категории)
    var title: String = ""          // Главное поле: название, текст, имя
    var subtitle: String? = nil     // Второстепенное: цена, адрес, перевод, автор
    var link: String? = nil         // URL: ссылка, email, карты
    var extra1: String? = nil       // Доп. поле 1: магазин, город, платформа, язык
    var extra2: String? = nil       // Доп. поле 2: валюта, страна, жанр, год
    var notes: String? = nil        // Заметки, описание, шаги

    // MARK: - Метаданные
    var sourceScreenshotId: UUID? = nil   // Скриншот-источник
    var createdAt: Date = Date()
    var isCompleted: Bool = false         // Куплено / посещено / прочитано / выполнено

    // MARK: - Init (удобный)
    init(
        category: ItemCategory,
        title: String,
        subtitle: String? = nil,
        link: String? = nil,
        extra1: String? = nil,
        extra2: String? = nil,
        notes: String? = nil,
        sourceScreenshotId: UUID? = nil
    ) {
        self.id = UUID()
        self.categoryRaw = category.rawValue
        self.title = title
        self.subtitle = subtitle
        self.link = link
        self.extra1 = extra1
        self.extra2 = extra2
        self.notes = notes
        self.sourceScreenshotId = sourceScreenshotId
        self.createdAt = Date()
        self.isCompleted = false
    }

    // MARK: - Computed
    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .tasks }
        set { categoryRaw = newValue.rawValue }
    }
}
