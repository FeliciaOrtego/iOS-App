//
//  LawnNOrderConfiguration.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 04/03/21.
//

import SwiftUI
import UIKit

class LawnNOrderConfiguration: GWSConfigurationProtocol {
    var mainThemeForegroundColor: UIColor = .init(hexString: "#008000")
    var mainThemeWarnColor: UIColor = .init(hexString: "#FFBF00")
    var mainTextColor: UIColor = UIColor.darkModeColor(hexString: "#151723")
    var grey1: UIColor = UIColor.darkModeColor(hexString: "#F5F5F5")
    var grey3: UIColor = UIColor.darkModeColor(hexString: "#e6e6f2")
    var appIdentifier: String = "lawn-n-order"

    var isFirebaseAuthEnabled: Bool = true

    var walkthroughData = [
        GWSWalkthroughModel(title: "Schedule jobs for customers", subtitle: "Easily create a schedule for crews and assign jobs.", icon: "arrow-circle"),
        GWSWalkthroughModel(title: "Invoices", subtitle: "Import or create customers and easily generate and send invoices.", icon: "doc"),
        GWSWalkthroughModel(title: "Crew Messages", subtitle: "Communicate with your crews via private messages.", icon: "chat"),
        GWSWalkthroughModel(title: "Live Route Tracking", subtitle: "Live crew route tracking, and suggested optimized routes.", icon: "pin"),
        GWSWalkthroughModel(title: "Get Notified", subtitle: "Receive notifications when you get new messages and crew updates.", icon: "notification"),
    ]
}
