//
//  UINavigationBar+Extensions.swift
//  YPImagePicker
//
//  Created by Sebastiaan Seegers on 02/03/2020.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationBar {
    func setTitleFont(font: UIFont?) {
        guard let font = font else { return }
        titleTextAttributes = [NSAttributedString.Key.font: font]
    }
}
