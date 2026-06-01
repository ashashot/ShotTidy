//
//  ShotTidyWidgetBundle.swift
//  ShotTidyWidget
//

import WidgetKit
import SwiftUI

@main
struct ShotTidyWidgetBundle: WidgetBundle {
    var body: some Widget {
        CategoryListWidget()
        ChecklistWidget()
        ShoppingWidget()
        QuickImportWidget()
    }
}
