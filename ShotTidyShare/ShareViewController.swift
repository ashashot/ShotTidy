//
//  ShareViewController.swift
//  ShotTidyShare
//
//  Entry point for the Share Extension.
//  Hosts ShareAnalysisView (SwiftUI) via UIHostingController.
//

import UIKit
import SwiftUI

final class ShareViewController: UIViewController {

    private var hostingController: UIHostingController<ShareAnalysisView>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground

        let inputItems = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []

        let analysisView = ShareAnalysisView(
            inputItems: inputItems,
            onComplete: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(
                    withError: NSError(
                        domain: "com.mbx.ShotTidy",
                        code: NSUserCancelledError,
                        userInfo: nil
                    )
                )
            }
        )

        let hc = UIHostingController(rootView: analysisView)
        addChild(hc)
        view.addSubview(hc.view)
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: view.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hc.didMove(toParent: self)
        hostingController = hc
    }
}
