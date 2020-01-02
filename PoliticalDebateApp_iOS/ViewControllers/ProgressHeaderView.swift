//
//  ProgressHeaderView.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 1/1/20.
//  Copyright © 2020 PoliticalDebateApp. All rights reserved.
//

import UIKit

class ProgressHeaderView: UIView {

    init(showFractionLabel: Bool) {
        self.showFractionLabel = showFractionLabel

        super.init(frame: .zero)

        installViewConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Properties

    private let showFractionLabel: Bool
    private static let horizontalInset: CGFloat = 16.0
    private static let verticalInset: CGFloat = 12.0

    // MARK: - UI Elements

    private lazy var pointsFractionLabel = BasicUIElementFactory.generateLabel(textAlignment: .center)

    private lazy var debateProgressView = BasicUIElementFactory.generateProgressView()

    // MARK: - View constraints & Binding

    func installViewConstraints() {
        if showFractionLabel {
            addSubview(pointsFractionLabel)
            addSubview(debateProgressView)

            pointsFractionLabel.translatesAutoresizingMaskIntoConstraints = false
            debateProgressView.translatesAutoresizingMaskIntoConstraints = false

            pointsFractionLabel.topAnchor.constraint(equalTo: topLayoutAnchor, constant: 6.0).isActive = true
            pointsFractionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalInset).isActive = true
            pointsFractionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.horizontalInset)
                // Necessary to avoid conflicting with UITemporaryLayoutWidth
                .injectPriority(.required - 1).isActive = true

            debateProgressView.heightAnchor.constraint(equalToConstant: GeneralConstants.progressViewHeight).isActive = true
            debateProgressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalInset).isActive = true
            debateProgressView.topAnchor.constraint(equalTo: pointsFractionLabel.bottomAnchor, constant: Self.verticalInset).isActive = true
            debateProgressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.horizontalInset)
                // Necessary to avoid conflicting with UITemporaryLayoutWidth
                .injectPriority(.required - 1).isActive = true
            debateProgressView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.verticalInset)
                // Necessary to avoid conflicting with UITemporaryLayoutHeight
                .injectPriority(.required - 1).isActive = true
        } else {
            addSubview(debateProgressView)

            debateProgressView.translatesAutoresizingMaskIntoConstraints = false

            debateProgressView.heightAnchor.constraint(equalToConstant: GeneralConstants.progressViewHeight).isActive = true
            debateProgressView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            debateProgressView.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
            debateProgressView.trailingAnchor.constraint(equalTo: trailingAnchor)
                // Necessary to avoid conflicting with UITemporaryLayoutWidth
                .injectPriority(.required - 1).isActive = true
            debateProgressView.bottomAnchor.constraint(equalTo: bottomAnchor)
                // Necessary to avoid conflicting with UITemporaryLayoutHeight
                .injectPriority(.required - 1).isActive = true
        }
    }

    func setSeenPointsFraction(numerator: Int, denominator: Int) {
        UIView.animate(withDuration: GeneralConstants.standardAnimationDuration) {
            self.pointsFractionLabel.text = "\(numerator) / \(denominator) points seen"
        }
    }

    func setProgress(_ completedPercentage: Int) {
        UIView.animate(withDuration: GeneralConstants.standardAnimationDuration) {
            self.debateProgressView.setProgress(Float(completedPercentage) / 100, animated: true)
        }
    }
}
