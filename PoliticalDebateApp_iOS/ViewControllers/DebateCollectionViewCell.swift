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
            guard let viewModel = viewModel else { return }
            UIView.animate(withDuration: Constants.standardAnimationDuration, animations: { [weak self] in
                self?.starredButton.tintColor = viewModel.starTintColor
                self?.debateTitleButton.setTitle(self?.viewModel?.debate.title ?? "",
                                                 for: .normal)
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

        starredButton.tintColor = .clear
        debateTitleButton.setTitle(nil, for: .normal)
        debateProgressView.setProgress(0.0, animated: false)
        disposeBag = DisposeBag()
    }

    // MARK: - UI Properties

    private static let cellColor = UIColor.customLightGreen1
    private static let cornerRadius: CGFloat = 16.0

    // MARK: - UI Elements

    private lazy var starredButton: UIButton = {
        let starredButton = UIButton(frame: .zero)
        starredButton.setImage(UIImage.star, for: .normal)
        return starredButton
    }()

    private lazy var debateTitleButton: UIButton = {
        let debateTitleButton = ButtonWithHighlightedBackgroundColor(frame: .zero)
        debateTitleButton.setTitleColor(GeneralColors.text, for: .normal)
        debateTitleButton.setBackgroundColorHighlightState(highlighted: GeneralColors.background, unhighlighted: .clear)
        debateTitleButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0)
        debateTitleButton.titleLabel?.font = GeneralFonts.button
        debateTitleButton.titleLabel?.textAlignment = .center
        debateTitleButton.titleLabel?.numberOfLines = 0 // multiline
        debateTitleButton.titleLabel?.lineBreakMode = .byWordWrapping
        return debateTitleButton
    }()

    private lazy var debateProgressView: UIProgressView = {
        let debateProgressView = UIProgressView()
        debateProgressView.progressTintColor = UIColor.customLightGreen2
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

        contentView.addSubview(debateTitleButton)
        contentView.addSubview(starredButton)
        contentView.addSubview(debateProgressView)

        debateTitleButton.translatesAutoresizingMaskIntoConstraints = false
        starredButton.translatesAutoresizingMaskIntoConstraints = false
        debateProgressView.translatesAutoresizingMaskIntoConstraints = false

        // Button takes up entire contentView but is beneath rest of UI elements
        debateTitleButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2).isActive = true
        debateTitleButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        debateTitleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2).isActive = true
        debateTitleButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        starredButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        starredButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        starredButton.setContentHuggingPriority(.required, for: .vertical)

        debateProgressView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.15).isActive = true
        debateProgressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        debateProgressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        debateProgressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = contentView.bounds
    }

    private func installViewBinds() {
        starredButton.addTarget(self, action: #selector(starredButtonTapped), for: .touchUpInside)
        debateTitleButton.addTarget(self, action: #selector(tappedToOpenDebate), for: .touchUpInside)
        let tappedProgress = UITapGestureRecognizer(target: self, action: #selector(tappedToOpenDebate))
        debateProgressView.addGestureRecognizer(tappedProgress)
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
                ErrorHandler.showBasicErrorBanner()
                return
            }

            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                            title: "Couldn't save starred debate to server."))
        }).disposed(by: disposeBag)
    }

    @objc private func tappedToOpenDebate() {
        // TODO: Push debate VC
    }
}
