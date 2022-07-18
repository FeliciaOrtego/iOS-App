//
//  GWSLocalizationHelper.swift
//  StoreLocator
//
//  Created by Jared Sullivan and Duy Bui on 12/4/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import Foundation

class GWSLocalizationHelper {
    static var isRTLLanguage: Bool {
        return NSLocale.characterDirection(forLanguage: NSLocale.current.languageCode ?? "") == .rightToLeft
    }
}

extension String {
    private func localize(in file: String) -> String {
        if let language = NSLocale.current.languageCode, language == "en" {
            return self
        } else {
            return NSLocalizedString(self, tableName: file, bundle: Bundle.main, value: "", comment: "")
        }
    }

    /// Localization Language (common)
    var localizedCore: String {
        return localize(in: "GWSLocalizableCommon")
    }

    /// Localization In App
    var localizedInApp: String {
        return localize(in: "Localizable")
    }

    // MARK: - Localization for each part

    var localizedReviews: String {
        return localize(in: "GWSLocalizableReviews")
    }

    var localizedChat: String {
        return localize(in: "GWSChatLocalizable")
    }

    var localizedComposer: String {
        return localize(in: "GWSComposerLocalizable")
    }

    var localizedModels: String {
        return localize(in: "GWSModelsLocalizable")
    }

    var localizedListing: String {
        return localize(in: "GWSListingLocalizable")
    }

    var localizedThirdParty: String {
        return localize(in: "GWSThirdPartyLocalizable")
    }

    var localizedEcommerce: String {
        return localize(in: "GWSEcommerceLocalizable")
    }

    var localizedFeed: String {
        return localize(in: "GWSFeedLocalizable")
    }

    var localizedSettings: String {
        return localize(in: "GWSSettingsLocalizable")
    }

    var localizedDriver: String {
        return localize(in: "GWSDriverLocalizable")
    }
}
