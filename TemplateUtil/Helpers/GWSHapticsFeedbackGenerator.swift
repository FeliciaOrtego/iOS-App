//
//  GWSHapticsFeedbackGenerator.swift
//  Shopertino
//
//  Created by Jared Sullivan and Duy Bui on 1/3/20.
//  Copyright © 2020 Lawn and Order. All rights reserved.
//

import Foundation
import UIKit

enum GWSHapticFeedbackType {
    case errorNotification
    case successNotification
    case warningNotification
    case lightImpact
    case mediumImpact
    case heavyImpact
    case selection
}

enum GWSHapticsFeedbackGenerator {
    static func generateHapticFeedback(_ type: GWSHapticFeedbackType) {
        switch type {
        case .errorNotification:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        case .successNotification:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case .warningNotification:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        case .lightImpact:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .mediumImpact:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        case .heavyImpact:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
}
