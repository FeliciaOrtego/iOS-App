//
//  GWSConfigurationProtocol.swift
//  SCore
//
//  Created by Jared Sullivan and Mayil Kannan on 04/03/21.
//

import UIKit

protocol GWSConfigurationProtocol {
    var mainThemeForegroundColor: UIColor { get set }
    var mainThemeWarnColor: UIColor { get set }
    var mainTextColor: UIColor { get set }
    var grey1: UIColor { get set }
    var grey3: UIColor { get set }
    var appIdentifier: String { get set }

    var isFirebaseAuthEnabled: Bool { get set }

    var walkthroughData: [GWSWalkthroughModel] { get set }
}
