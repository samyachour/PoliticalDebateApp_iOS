//
//  UIView+Fade.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/8/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

extension UIView {
    enum UIViewFadeStyle {
        case bottom
        case top
        case left
        case right
        case vertical
        case horizontal
    }
    func fadeView(style: UIViewFadeStyle = .bottom, percentage: Double = 0.07) {
        let gradient = CAGradientLayer()
        gradient.frame = bounds // needs to be applied in didLayoutSubviews
        gradient.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        let startLocation = percentage
        let endLocation = 1 - percentage
        switch style {
        case .bottom:
            gradient.startPoint = CGPoint(x: 0.5, y: endLocation)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
        case .top:
            gradient.startPoint = CGPoint(x: 0.5, y: startLocation)
            gradient.endPoint = CGPoint(x: 0.5, y: 0.0)
        case .vertical:
            gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
            gradient.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
            gradient.locations = [0.0, startLocation, endLocation, 1.0] as [NSNumber]
        case .left:
            gradient.startPoint = CGPoint(x: startLocation, y: 0.5)
            gradient.endPoint = CGPoint(x: 0.0, y: 0.5)
        case .right:
            gradient.startPoint = CGPoint(x: endLocation, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
        case .horizontal:
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
            gradient.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
            gradient.locations = [0.0, startLocation, endLocation, 1.0] as [NSNumber]
        }
        layer.mask = gradient
    }
}
