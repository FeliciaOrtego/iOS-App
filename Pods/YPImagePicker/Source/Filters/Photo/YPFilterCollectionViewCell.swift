//
//  YPFilterCollectionViewCell.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import Stevia
import UIKit

final class YPFilterCollectionViewCell: UICollectionViewCell {
    let name = UILabel()
    let imageView = UIImageView()
    override var isHighlighted: Bool { didSet {
        UIView.animate(withDuration: 0.1) {
            self.contentView.transform = self.isHighlighted
                ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                : CGAffineTransform.identity
        }
    }
    }

    override var isSelected: Bool {
        didSet {
            name.textColor = isSelected
                ? UIColor.ypLabel
                : UIColor.ypSecondaryLabel
            name.font = isSelected
                ? YPConfig.fonts.filterSelectionSelectedFont
                : YPConfig.fonts.filterSelectionUnSelectedFont
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override init(frame: CGRect) {
        super.init(frame: frame)

        sv(
            name,
            imageView
        )

        |name|.top(0)
        |imageView|.bottom(0).heightEqualsWidth()

        name.font = YPConfig.fonts.filterNameFont
        name.textColor = UIColor.ypSecondaryLabel
        name.textAlignment = .center

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        clipsToBounds = false
        layer.shadowColor = UIColor.ypLabel.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 4, height: 7)
        layer.shadowRadius = 5
        layer.backgroundColor = UIColor.clear.cgColor
    }
}
