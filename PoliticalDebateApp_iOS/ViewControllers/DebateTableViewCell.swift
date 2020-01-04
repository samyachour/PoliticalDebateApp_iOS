//
//  DebateTableViewCell.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/6/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class DebateTableViewCell: UITableViewCell {
    static let reuseIdentifier = "DebateTableViewCell"

    var viewModel: DebateTableViewCellViewModel? {
        didSet {
            UIView.animate(withDuration: GeneralConstants.standardAnimationDuration, animations: {
                self.debateTitleLabel.text = self.viewModel?.debate.title
                self.tagsLabel.text = self.viewModel?.formattedTags
                guard let viewModel = self.viewModel else { return }

                self.starredButton.tintColor = viewModel.starTintColor
                self.changeProgress(to: viewModel.completedPercentage)
            })
        }
    }

    private var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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

    private static let defaultBackgroundColor = UIColor.clear
    private static let horizontalInset = DebatesTableViewController.horizontalInset
    private static let verticalInset = DebatesTableViewController.verticalInset
    private var progressViewTopAnchor: NSLayoutConstraint?
    private var progressViewHeightAnchor: NSLayoutConstraint?

    // MARK: - UI Elements

    private lazy var starredButton: UIButton = {
        let starredButton = UIButton(frame: .zero)
        starredButton.setImage(UIImage.star, for: .normal)
        return starredButton
    }()

    private lazy var debateTitleLabel = BasicUIElementFactory.generateLabel(font: GeneralFonts.largeText)
    private lazy var tagsLabel = BasicUIElementFactory.generateLabel(font: GeneralFonts.smallText, color: GeneralColors.smallText)

    private lazy var debateProgressView = BasicUIElementFactory.generateProgressView()

    // MARK: - View constraints & Binding

    private func installConstraints() {
        selectionStyle = .none
        contentView.addSubview(debateTitleLabel)
        contentView.addSubview(tagsLabel)
        contentView.addSubview(starredButton)
        contentView.addSubview(debateProgressView)

        debateTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tagsLabel.translatesAutoresizingMaskIntoConstraints = false
        starredButton.translatesAutoresizingMaskIntoConstraints = false
        debateProgressView.translatesAutoresizingMaskIntoConstraints = false

        debateTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.horizontalInset).isActive = true
        debateTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.verticalInset).isActive = true
        debateTitleLabel.trailingAnchor.constraint(equalTo: starredButton.leadingAnchor, constant: -Self.horizontalInset).isActive = true

        tagsLabel.leadingAnchor.constraint(equalTo: debateTitleLabel.leadingAnchor).isActive = true
        tagsLabel.topAnchor.constraint(equalTo: debateTitleLabel.bottomAnchor, constant: Self.verticalInset / 3).isActive = true
        tagsLabel.trailingAnchor.constraint(equalTo: debateTitleLabel.trailingAnchor).isActive = true

        starredButton.centerYAnchor.constraint(equalTo: centerYAnchor).injectPriority(.required - 1).isActive = true
        starredButton.bottomAnchor.constraint(greaterThanOrEqualTo: debateProgressView.topAnchor, constant: -2.0).isActive = true
        starredButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.horizontalInset).isActive = true
        starredButton.setContentHuggingPriority(.required, for: .horizontal)
        starredButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        progressViewHeightAnchor = debateProgressView.heightAnchor.constraint(equalToConstant: GeneralConstants.progressViewHeight)
        progressViewHeightAnchor?.isActive = true
        debateProgressView.leadingAnchor.constraint(equalTo: debateTitleLabel.leadingAnchor).isActive = true
        progressViewTopAnchor = debateProgressView.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: Self.verticalInset)
        progressViewTopAnchor?.isActive = true
        debateProgressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.horizontalInset).isActive = true
        debateProgressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.verticalInset).isActive = true
    }

    private func changeProgress(to completedPercentage: Int) {
        if completedPercentage > 0 {
            progressViewHeightAnchor?.constant = GeneralConstants.progressViewHeight
            progressViewTopAnchor?.constant = Self.verticalInset
            debateProgressView.setProgress(Float(completedPercentage) / 100, animated: true)
        } else {
            progressViewHeightAnchor?.constant = 0
            progressViewTopAnchor?.constant = 0
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        UIView.animate(withDuration: GeneralConstants.quickAnimationDuration) {
            self.contentView.backgroundColor = highlighted ? GeneralColors.selectedDebate : Self.defaultBackgroundColor
        }
    }

    private func installViewBinds() {
        starredButton.addTarget(self, action: #selector(starredButtonTapped), for: .touchUpInside)
    }

    @objc private func starredButtonTapped() {
        viewModel?.starOrUnstarDebate().subscribe(onSuccess: { [weak self] _ in
            UIView.animate(withDuration: GeneralConstants.standardAnimationDuration, animations: {
                self?.starredButton.tintColor = self?.viewModel?.starTintColor
            })
        }, onError: { error in
            if let generalError = error as? GeneralError,
                generalError == .alreadyHandled {
                return
            }
            guard error as? MoyaError != nil else {
                ErrorHandlerService.showBasicRetryErrorBanner()
                return
            }

            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                            title: "Couldn't save starred debate to server."))
        }).disposed(by: disposeBag)
    }
}
