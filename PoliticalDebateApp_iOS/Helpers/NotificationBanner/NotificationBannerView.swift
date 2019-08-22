//
//  NotificationBannerView.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

class NotificationBannerView: UIView {

    required init(title: String,
                  subtitle: String? = nil,
                  button: UIButton? = nil,
                  image: UIImage? = nil,
                  viewModel: NotificationBannerViewModel? = nil) {

        self.button = button

        super.init(frame: .zero)

        titleLabel.textColor = viewModel?.foregroundColor
        subtitleLabel.textColor = viewModel?.foregroundColor

        leftImageView.image = image
        leftImageView.tintColor = viewModel?.foregroundColor ?? UIColor.clear

        setTitle(title: title, subtitle: subtitle)

        installViewConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View constraints
    // swiftlint:disable function_body_length
    private func installViewConstraints() {
        addSubview(titleSubtitleContainerView)
        titleSubtitleContainerView.addSubview(titleLabel)

        titleSubtitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleSubtitleContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
            .injectPriority(.required - 1).isActive = true
        titleSubtitleContainerView.topAnchor.constraint(equalTo: topLayoutAnchor, constant: 16).isActive = true
        titleSubtitleContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
            .injectPriority(.required - 1).isActive = true
        titleSubtitleContainerView.bottomAnchor.constraint(equalTo: bottomLayoutAnchor, constant: -16).isActive = true

        titleLabel.leadingAnchor.constraint(equalTo: titleSubtitleContainerView.leadingAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: titleSubtitleContainerView.topAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: titleSubtitleContainerView.trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: titleSubtitleContainerView.bottomAnchor).injectPriority(.required - 1).isActive = true

        if subtitleLabel.text != nil {
            titleSubtitleContainerView.addSubview(subtitleLabel)

            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

            subtitleLabel.leadingAnchor.constraint(equalTo: titleSubtitleContainerView.leadingAnchor).isActive = true
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
            subtitleLabel.trailingAnchor.constraint(equalTo: titleSubtitleContainerView.trailingAnchor).isActive = true
            subtitleLabel.bottomAnchor.constraint(equalTo: titleSubtitleContainerView.bottomAnchor).isActive = true

            subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        if leftImageView.image != nil {
            addSubview(leftImageView)

            leftImageView.translatesAutoresizingMaskIntoConstraints = false

            leftImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
            leftImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 16).isActive = true
            leftImageView.trailingAnchor.constraint(equalTo: titleSubtitleContainerView.leadingAnchor, constant: -8).isActive = true
            leftImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16).isActive = true

            leftImageView.centerYAnchor.constraint(equalTo: titleSubtitleContainerView.centerYAnchor).isActive = true

            // capping maximum size of the image
            leftImageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
            leftImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 48).isActive = true
            leftImageView.heightAnchor.constraint(equalTo: leftImageView.widthAnchor).isActive = true
            leftImageView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        }

        if let button = button {
            addSubview(button)

            button.translatesAutoresizingMaskIntoConstraints = false

            button.leadingAnchor.constraint(equalTo: titleSubtitleContainerView.trailingAnchor, constant: 16).isActive = true
            button.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8).isActive = true
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
            button.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8).isActive = true

            button.centerYAnchor.constraint(equalTo: titleSubtitleContainerView.centerYAnchor).isActive = true

            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }

    private func setTitle(title: String, subtitle: String? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    // MARK: - UI Properties

    private let button: UIButton?

    private let titleSubtitleContainerView = UIView()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()

        titleLabel.font = .primaryRegular(16)
        titleLabel.numberOfLines = 0

        return titleLabel
    }()

    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()

        subtitleLabel.font = .primaryLight(16)
        subtitleLabel.numberOfLines = 0

        return subtitleLabel
    }()

    private lazy var leftImageView = UIImageView(frame: .zero)
}
