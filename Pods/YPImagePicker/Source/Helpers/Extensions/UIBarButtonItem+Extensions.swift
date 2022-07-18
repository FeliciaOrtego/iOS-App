//
//  UIBarButtonItem+Extensions.swift
//  YPImagePicker
//
//  Created by Sebastiaan Seegers on 02/03/2020.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import Foundation
import UIKit

extension UIBarButtonItem {
    func setFont(font: UIFont?, forState _: UIControl.State) {
        guard font != nil else { return }
        setTitleTextAttributes([NSAttributedString.Key.font: font!], for: .normal)
    }
}
