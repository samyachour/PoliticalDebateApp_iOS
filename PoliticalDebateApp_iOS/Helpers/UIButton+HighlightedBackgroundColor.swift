//
//  UIButton+HighlightedBackgroundColor.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/14/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

class ButtonWithHighlightedBackgroundColor: UIButton {

    private var highlightedBackgroundColor: UIColor?
    private var unhighlightedBackgroundColor: UIColor?

    func setBackgroundColorHighlightState(highlighted: UIColor, unhighlighted: UIColor) {
        highlightedBackgroundColor = highlighted
        unhighlightedBackgroundColor = unhighlighted
    }

    override open var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }

        set {
            if let highlighted = highlightedBackgroundColor,
                let unhighlighted = unhighlightedBackgroundColor {
                UIView.animate(withDuration: Constants.standardAnimationDuration) {
                    super.backgroundColor = newValue ? highlighted : unhighlighted
                }
            }
            super.isHighlighted = newValue
        }
    }
}
