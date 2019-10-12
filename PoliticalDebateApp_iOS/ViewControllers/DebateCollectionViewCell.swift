//
//  DebateCollectionViewCell.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/6/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class DebateCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "DebateCollectionViewCell"

    var viewModel: DebateCollectionViewCellViewModel? {
        didSet {
            UIView.animate(withDuration: Constants.standardAnimationDuration, animations: { [weak self] in
                if let viewModel = self?.viewModel { self?.starredButton.tintColor = viewModel.starTintColor }
                self?.debateTitleLabel.text = self?.viewModel?.debate.title
                self?.debateProgressView.setProgress(Float(self?.viewModel?.completedPercentage ?? 0) / 100, animated: false)
            })
        }
    }

    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)

        installConstraints()
        installViewBinds()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        viewModel = nil
        disposeBag = DisposeBag()
    }

    // MARK: - UI Properties

    private static let cellColor = UIColor.customLightGreen1
    private static let cornerRadius: CGFloat = 16.0
    private static let defaultTintViewColor: UIColor = .clear

    // MARK: - UI Elements

    // Needed so we can have a gradient layer but still animate the cell color on hightlighted
    private lazy var tintView: UIView = {
        let tintView = UIView()
        tintView.backgroundColor = DebateCollectionViewCell.defaultTintViewColor
        return tintView
    }()

    private lazy var starredButton: UIButton = {
        let starredButton = UIButton(frame: .zero)
        starredButton.setImage(UIImage.star, for: .normal)
        return starredButton
    }()

    private lazy var debateTitleLabel: UILabel = {
        let debateTitleLabel = UILabel(frame: .zero)
        debateTitleLabel.textColor = GeneralColors.text
        debateTitleLabel.font = GeneralFonts.text
        debateTitleLabel.numberOfLines = 0
        debateTitleLabel.textAlignment = .center
        return debateTitleLabel
    }()

    private lazy var debateProgressView: UIProgressView = {
        let debateProgressView = UIProgressView()
        debateProgressView.progressTintColor = .customLightGreen2
        debateProgressView.trackTintColor = .clear
        return debateProgressView
    }()

    private let gradientLayer = CAGradientLayer(start: .topLeft, end: .bottomRight, colors: [.white, DebateCollectionViewCell.cellColor], type: .axial)

    // MARK: - View constraints & Binding

    private func installConstraints() {
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = DebateCollectionViewCell.cornerRadius
        contentView.backgroundColor = DebateCollectionViewCell.cellColor
        contentView.layer.addSublayer(gradientLayer)

        contentView.addSubview(tintView)
        contentView.addSubview(starredButton)
        contentView.addSubview(debateTitleLabel)
        contentView.addSubview(debateProgressView)

        tintView.translatesAutoresizingMaskIntoConstraints = false
        starredButton.translatesAutoresizingMaskIntoConstraints = false
        debateTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        debateProgressView.translatesAutoresizingMaskIntoConstraints = false

        tintView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        tintView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        tintView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        tintView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        starredButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        starredButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        starredButton.setContentHuggingPriority(.required, for: .vertical)

        debateTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2).isActive = true
        debateTitleLabel.topAnchor.constraint(equalTo: starredButton.bottomAnchor).isActive = true
        debateTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2).isActive = true
        debateTitleLabel.bottomAnchor.constraint(equalTo: debateProgressView.topAnchor).isActive = true

        debateProgressView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.15).isActive = true
        debateProgressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        debateProgressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        debateProgressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: Constants.quickAnimationDuration) { [weak self] in
                if self?.isHighlighted ?? false {
                    self?.tintView.backgroundColor = GeneralColors.selected
                } else {
                    self?.tintView.backgroundColor = DebateCollectionViewCell.defaultTintViewColor
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = contentView.bounds
        debateProgressView.fadeView(style: .top, percentage: 0.2)
    }

    private func installViewBinds() {
        starredButton.addTarget(self, action: #selector(starredButtonTapped), for: .touchUpInside)
    }

    @objc private func starredButtonTapped() {
        viewModel?.starOrUnstarDebate().subscribe(onSuccess: { [weak self] _ in
            UIView.animate(withDuration: Constants.standardAnimationDuration, animations: {
                self?.starredButton.tintColor = self?.viewModel?.starTintColor
            })
        }, onError: { error in
            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            guard error as? MoyaError != nil else {
                ErrorHandler.showBasicRetryErrorBanner()
                return
            }

            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                            title: "Couldn't save starred debate to server."))
        }).disposed(by: disposeBag)
    }
}
