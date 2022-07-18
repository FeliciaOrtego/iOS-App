//
//  CPKProgressHUD.swift
//  ClassifiedsApp
//
//  Created by Jared Sullivan and Florian Marcu on 9/25/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import SwiftUI
import UIKit

enum CPKProgressHUDStyle {
    case loading(text: String? = nil)
    case success
}

class CPKProgressHUD: UIVisualEffectView {
    private let dimension: CGFloat = 100.0

    var indicator: UIActivityIndicatorView?
    let textLabel: UILabel

    let style: CPKProgressHUDStyle

    private init(style: CPKProgressHUDStyle) {
        self.style = style

        textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        textLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        textLabel.textAlignment = .center

        super.init(effect: UIBlurEffect(style: .dark))

        isHidden = true
        alpha = 0
        layer.cornerRadius = 10
        clipsToBounds = true

        contentView.addSubview(textLabel)

        switch style {
        case let .loading(text: text):
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .white
            contentView.addSubview(indicator)
            self.indicator = indicator
            if let text = text {
                textLabel.text = text
            } else {
                textLabel.text = "Loading".localizedCore
            }
        case .success:
            break
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func progressHUD(style: CPKProgressHUDStyle) -> CPKProgressHUD {
        return CPKProgressHUD(style: style)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = self.bounds
        if let indicator = indicator {
            let w = indicator.frame.width
            let h = indicator.frame.height
            indicator.frame = CGRect(x: (bounds.width - w) / 2.0, y: 18.0, width: w, height: h)
            textLabel.sizeToFit()
            textLabel.frame = CGRect(x: 0,
                                     y: indicator.frame.maxY,
                                     width: bounds.width,
                                     height: bounds.height - 23.0 - indicator.frame.height)
        }
    }

    func show(in view: UIView) {
        removeFromSuperview()
        view.addSubview(self)
        view.bringSubviewToFront(self)

        indicator?.startAnimating()

        let bounds = view.bounds
        frame = CGRect(x: (bounds.maxX - bounds.minX - dimension) / 2.0,
                       y: (bounds.maxY - bounds.minY - dimension) / 2.0,
                       width: dimension,
                       height: dimension)
        setNeedsLayout()
        layoutIfNeeded()

        UIView.animate(withDuration: 0.3) {
            self.isHidden = false
            self.alpha = 1
        }
    }

    func dismiss(after delay: TimeInterval = 0.3) {
        UIView.animate(withDuration: delay, animations: {
            self.isHidden = true
            self.alpha = 0
            self.indicator?.stopAnimating()
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

struct CPKProgressHUDUI: UIViewRepresentable {
    func makeUIView(context _: UIViewRepresentableContext<CPKProgressHUDUI>) -> CPKProgressHUD {
        return CPKProgressHUD.progressHUD(style: .loading(text: nil))
    }

    func updateUIView(_: CPKProgressHUD, context _: UIViewRepresentableContext<CPKProgressHUDUI>) {}

    typealias UIViewType = CPKProgressHUD
}
