//
//  DebateCell.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/6/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

class DebateCell: UICollectionViewCell {
    static let reuseIdentifier = "DebateCollectionViewCell"

    var viewModel: DebateCellViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            starredImageView.tintColor = viewModel.starTintColor
            debateTitleButton.setTitle(viewModel.debate.title, for: .normal)
            debateProgressView.setProgress(viewModel.completedPercentage, animated: false)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        installConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        starredImageView.tintColor = .clear
        debateTitleButton.setTitle(nil, for: .normal)
        debateProgressView.setProgress(0.0, animated: false)
    }

    // MARK: - UI Properties

    private static let cellColor = UIColor.customLightGreen1
    private static let cornerRadius: CGFloat = 16.0

    // MARK: - UI Elements

    private lazy var starredImageView: UIImageView = {
        let starredImageView = UIImageView(frame: .zero)
        starredImageView.image = UIImage(named: "Star")
        return starredImageView
    }()

    private lazy var debateTitleButton: UIButton = {
        let debateTitleButton = UIButton(frame: .zero)
        debateTitleButton.setTitleColor(GeneralColors.text, for: .normal) // TODO: Fix
        debateTitleButton.titleLabel?.font = GeneralFonts.button
        debateTitleButton.titleLabel?.textAlignment = NSTextAlignment.center
        debateTitleButton.titleLabel?.numberOfLines = 0 // multiline
        debateTitleButton.titleLabel?.lineBreakMode = .byWordWrapping
        return debateTitleButton
    }()

    private lazy var debateProgressView: UIProgressView = {
        let debateProgressView = UIProgressView()
        debateProgressView.progressTintColor = .black // TODO: Fix
        debateProgressView.trackTintColor = .clear
        return debateProgressView
    }()

    private let gradientLayer = CAGradientLayer(start: .topLeft, end: .bottomRight, colors: [UIColor.white, DebateCell.cellColor], type: .axial)

    // MARK: - View constraints & Binding

    private func installConstraints() {
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = DebateCell.cellColor
        contentView.layer.cornerRadius = DebateCell.cornerRadius
        contentView.layer.addSublayer(gradientLayer)

        contentView.addSubview(starredImageView)
        contentView.addSubview(debateTitleButton)
        contentView.addSubview(debateProgressView)

        starredImageView.translatesAutoresizingMaskIntoConstraints = false
        debateTitleButton.translatesAutoresizingMaskIntoConstraints = false
        debateProgressView.translatesAutoresizingMaskIntoConstraints = false

        starredImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        starredImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        starredImageView.setContentHuggingPriority(.required, for: .vertical)

        debateTitleButton.topAnchor.constraint(equalTo: starredImageView.bottomAnchor).isActive = true
        debateTitleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2).isActive = true
        debateTitleButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2).isActive = true
        debateTitleButton.bottomAnchor.constraint(equalTo: debateProgressView.topAnchor).isActive = true

        debateProgressView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.15).isActive = true
        debateProgressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        debateProgressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        debateProgressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = contentView.bounds
    }

    private func installViewBinds() {
        debateTitleButton.addTarget(self, action: #selector(debateTitleButtonTapped), for: .touchUpInside)
    }

    @objc private func debateTitleButtonTapped() {
        // TODO: Push debate VC
    }
}
