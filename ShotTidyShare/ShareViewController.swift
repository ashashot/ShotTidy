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

        // Frame-based layout — works in any context
        statusLabel.frame = CGRect(x: 20, y: 0, width: view.bounds.width - 40, height: view.bounds.height)
        statusLabel.text = "⏳ Saving screenshot…"
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
            complete(status: "❌ No data (inputItems is empty)")
            return
        }

        let providers = items.flatMap { $0.attachments ?? [] }
        guard !providers.isEmpty else {
            complete(status: "❌ No attachments")
            return
        }

        let group   = DispatchGroup()
        var saved   = 0
        var lastErr = "unknown error"

        for provider in providers {
            // Try all supported image formats
            let types = ["public.jpeg", "public.png", "public.heic",
                         "public.tiff", "public.image", "com.compuserve.gif"]

            guard let typeID = types.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) else {
                lastErr = "provider does not contain an image"
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

                // Convert to JPEG if needed
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
                let word = saved == 1 ? "screenshot saved" : "screenshots saved"
                self?.complete(status: "✅ \(saved) \(word)\nOpen ShotTidy to analyze")
            } else {
                self?.complete(status: "❌ Error: \(lastErr)")
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
