//
//  ShareViewController.swift
//  ShotTidyShare
//

import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    private let statusLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Frame-based layout — работает в любом контексте
        statusLabel.frame = CGRect(x: 20, y: 0, width: view.bounds.width - 40, height: view.bounds.height)
        statusLabel.text = "⏳ Сохраняем скриншот…"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.textColor = UIColor.label
        statusLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        view.addSubview(statusLabel)

        processImages()
    }

    // MARK: - Process

    private func processImages() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem],
              !items.isEmpty else {
            complete(status: "❌ Нет данных (inputItems пуст)")
            return
        }

        let providers = items.flatMap { $0.attachments ?? [] }
        guard !providers.isEmpty else {
            complete(status: "❌ Нет attachments")
            return
        }

        let group   = DispatchGroup()
        var saved   = 0
        var lastErr = "неизвестная ошибка"

        for provider in providers {
            // Пробуем все возможные форматы изображений
            let types = ["public.jpeg", "public.png", "public.heic",
                         "public.tiff", "public.image", "com.compuserve.gif"]

            guard let typeID = types.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) else {
                lastErr = "провайдер не содержит изображение"
                continue
            }

            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: typeID) { data, error in
                defer { group.leave() }

                if let error {
                    lastErr = error.localizedDescription
                    return
                }
                guard let data else {
                    lastErr = "data == nil"
                    return
                }

                // Конвертируем в JPEG если нужно
                let jpegData: Data
                if let img = UIImage(data: data), let jpeg = img.jpegData(compressionQuality: 0.85) {
                    jpegData = jpeg
                } else {
                    jpegData = data
                }

                do {
                    try AppGroupManager.savePendingImage(jpegData)
                    saved += 1
                } catch {
                    lastErr = "AppGroup: \(error.localizedDescription)"
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            if saved > 0 {
                let word = saved == 1 ? "скриншот сохранён" : "скриншота сохранено"
                self?.complete(status: "✅ \(saved) \(word)\nОткройте ShotTidy для анализа")
            } else {
                self?.complete(status: "❌ Ошибка: \(lastErr)")
            }
        }
    }

    private func complete(status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = status
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
