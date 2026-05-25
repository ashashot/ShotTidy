//
//  ConfirmationView.swift
//  ShotTidy
//
//  Экран подтверждения перед сохранением извлечённых элементов.
//  Пользователь может отметить/снять, отредактировать или удалить каждый элемент.
//

import SwiftUI

/// Обёртка-идентификатор для индекса редактируемого черновика.
/// Нужна для .sheet(item:), чтобы SwiftUI передавал данные атомарно
/// и не выполнял closure контента раньше, чем индекс будет установлен.
private struct DraftEditContext: Identifiable {
    let id: Int  // глобальный индекс в viewModel.draftItems
}

struct ConfirmationView: View {
    // @Bindable нужен чтобы получать биндинги ($viewModel.draftItems[i])
    @Bindable var viewModel: ImportViewModel
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    /// Контекст редактирования: устанавливается → sheet открывается → сбрасывается при закрытии.
    /// Единый источник правды: .sheet(item:) гарантирует, что контент строится
    /// только когда editingContext != nil, исключая race condition.
    @State private var editingContext: DraftEditContext? = nil

    private var selectedCount: Int {
        viewModel.draftItems.filter { $0.isSelected && $0.isValid }.count
    }

    // Группировка: список (категория, [глобальные индексы в draftItems])
    private var groupedItems: [(ItemCategory, [Int])] {
        ItemCategory.allCases.compactMap { category in
            let indices = viewModel.draftItems.indices.filter { i in
                viewModel.draftItems[i].category == category
            }
            return indices.isEmpty ? nil : (category, indices)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.draftItems.isEmpty {
                    ContentUnavailableView(
                        "Нет данных",
                        systemImage: "tray",
                        description: Text("AI не смог извлечь структурированные данные из скриншотов")
                    )
                } else {
                    List {
                        // Пояснение
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Проверьте данные. Снимите галочку с лишнего или нажмите ✏️ для правки.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .listRowBackground(Color.blue.opacity(0.07))
                        }

                        // Предупреждения (пропущенные скриншоты)
                        if !viewModel.warnings.isEmpty {
                            Section {
                                ForEach(viewModel.warnings, id: \.self) { warning in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                            .font(.caption)
                                            .padding(.top, 2)
                                        Text(warning)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .listRowBackground(Color.orange.opacity(0.07))
                            } header: {
                                Text("Пропущено (\(viewModel.warnings.count))")
                                    .foregroundStyle(.orange)
                            }
                        }

                        // Группы по категориям
                        ForEach(groupedItems, id: \.0) { category, indices in
                            Section {
                                ForEach(indices, id: \.self) { index in
                                    DraftItemRow(
                                        item: $viewModel.draftItems[index],
                                        onEdit: {
                                            // Один шаг → sheet открывается только
                                            // когда item != nil, без race condition
                                            editingContext = DraftEditContext(id: index)
                                        }
                                    )
                                }
                                .onDelete { offsets in
                                    deleteItems(offsets: offsets, globalIndices: indices)
                                }
                            } header: {
                                categoryHeader(category, count: indices.count)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Подтверждение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.saveSelectedDrafts()
                        onSaved()
                    } label: {
                        Text("Сохранить (\(selectedCount))")
                            .fontWeight(.semibold)
                    }
                    .disabled(selectedCount == 0)
                }
            }
            // Sheet редактора.
            // .sheet(item:) гарантирует атомарность: SwiftUI строит DraftItemEditView
            // только когда editingContext != nil, и автоматически сбрасывает его в nil
            // при закрытии — без отдельного флага и без race condition.
            .sheet(item: $editingContext) { ctx in
                DraftItemEditView(item: $viewModel.draftItems[ctx.id])
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func categoryHeader(_ category: ItemCategory, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .foregroundStyle(category.color)
            Text(category.localizedName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(category.color)
        }
    }

    private func deleteItems(offsets: IndexSet, globalIndices: [Int]) {
        // Переводим локальные смещения в глобальные индексы, удаляем с конца
        let toRemove = offsets
            .map { localOffset in globalIndices[localOffset] }
            .sorted(by: >)
        for gi in toRemove {
            viewModel.draftItems.remove(at: gi)
        }
    }
}

// MARK: - DraftItemRow

struct DraftItemRow: View {
    @Binding var item: DraftItem
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Чекбокс
            Button {
                item.isSelected.toggle()
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isSelected ? .blue : Color(.systemFill))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            // Контент
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayTitle)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(item.isSelected ? .primary : .secondary)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !item.extra1.isEmpty {
                    Text(item.extra1)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Кнопка редактирования
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.systemFill))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .opacity(item.isSelected ? 1.0 : 0.45)
    }
}

// MARK: - DraftItemEditView

struct DraftItemEditView: View {
    @Binding var item: DraftItem
    @Environment(\.dismiss) private var dismiss

    private var schema: ItemCategory.FieldSchema { item.category.fieldSchema }

    var body: some View {
        NavigationStack {
            Form {
                // Смена категории
                Section("Категория") {
                    Picker("Категория", selection: $item.category) {
                        ForEach(ItemCategory.allCases, id: \.self) { cat in
                            Label(cat.localizedName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                // Основные поля
                Section(schema.titleLabel) {
                    TextField(schema.titlePlaceholder, text: $item.title, axis: .vertical)
                        .lineLimit(4, reservesSpace: false)
                }

                if let label = schema.subtitleLabel {
                    Section(label) {
                        TextField(schema.subtitlePlaceholder ?? "", text: $item.subtitle, axis: .vertical)
                            .lineLimit(3, reservesSpace: false)
                    }
                }

                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? "https://...", text: $item.link)
                            .keyboardType(schema.isLinkEmail ? .emailAddress : .URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                if let label = schema.extra1Label {
                    Section(label) {
                        TextField(schema.extra1Placeholder ?? "", text: $item.extra1)
                    }
                }

                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? "", text: $item.extra2)
                    }
                }

                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(schema.notesPlaceholder ?? label, text: $item.notes, axis: .vertical)
                            .lineLimit(6, reservesSpace: false)
                    }
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
