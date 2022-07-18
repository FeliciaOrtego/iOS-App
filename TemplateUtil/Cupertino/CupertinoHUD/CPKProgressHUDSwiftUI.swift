//
//  CPKProgressHUDSwiftUI.swift
//  ClassifiedsApp
//
//  Created by Jared Sullivan and Florian Marcu on 9/25/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import SwiftUI
import UIKit

struct CPKProgressHUDSwiftUI: UIViewRepresentable {
    func makeUIView(context _: UIViewRepresentableContext<CPKProgressHUDSwiftUI>) -> CPKProgressHUD {
        return CPKProgressHUD.progressHUD(style: .loading(text: nil))
    }

    func updateUIView(_ uiView: CPKProgressHUD, context _: UIViewRepresentableContext<CPKProgressHUDSwiftUI>) {
        uiView.indicator?.startAnimating()
        UIView.animate(withDuration: 0.3) {
            uiView.isHidden = false
            uiView.alpha = 1
        }
    }
}
