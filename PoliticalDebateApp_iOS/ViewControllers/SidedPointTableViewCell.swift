//
//  SidedPointTableViewCell.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/24/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class SidedPointTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SidedPointTableViewCell"

    var viewModel: SidedPointTableViewCellViewModel? {
        didSet {
            containerView.backgroundColor = viewModel?.backgroundColor
            let description = (viewModel?.useFullDescription ?? false) ? viewModel?.point.description : viewModel?.point.shortDescription
            pointTextView.attributedText = MarkDownFormatter.format(description, with: [.font: GeneralFonts.text,
                                                                                                           .foregroundColor: GeneralColors.text],
                                                                    hyperlinks: viewModel?.point.hyperlinks)
            pointTextView.sizeToFit()
            UIView.animate(withDuration: Constants.standardAnimationDuration) {
                self.checkImageView.image = (self.viewModel?.hasCompletedPaths ?? false) ? UIImage.check : nil
            }
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

    private static let cornerRadius: CGFloat = 26.0
    private static let inset: CGFloat = 10.0

    // MARK: - UI Elements

    private lazy var containerView: UIView = {
        let containerView = UIView(frame: .zero)
        containerView.layer.cornerRadius = SidedPointTableViewCell.cornerRadius
        return containerView
    }()

    private lazy var pointTextView = BasicUIElementFactory.generateDescriptionTextView()

    private lazy var checkImageView: UIImageView = {
        let checkImageView = UIImageView(frame: .zero)
        checkImageView.tintColor = .customLightGreen2
        return checkImageView
    }()

    // MARK: - View constraints & Binding

    private func installConstraints() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(pointTextView)
        containerView.addSubview(checkImageView)

        contentView.autoresizingMask = .flexibleHeight
        containerView.translatesAutoresizingMaskIntoConstraints = false
        pointTextView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false

        let containerVerticalInset: CGFloat = 8.0
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: PointsTableViewController.elementSpacing).isActive = true
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: containerVerticalInset).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -PointsTableViewController.elementSpacing).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -containerVerticalInset).isActive = true

        pointTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: SidedPointTableViewCell.inset).isActive = true
        pointTextView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: SidedPointTableViewCell.inset).isActive = true
        pointTextView.trailingAnchor.constraint(lessThanOrEqualTo: checkImageView.leadingAnchor, constant: -2).isActive = true
        pointTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -SidedPointTableViewCell.inset).isActive = true

        checkImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -SidedPointTableViewCell.inset - 4).isActive = true
        checkImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func installViewBinds() {
        pointTextView.delegate = self
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        UIView.animate(withDuration: Constants.quickAnimationDuration) {
            self.containerView.backgroundColor = highlighted ? GeneralColors.selected : self.viewModel?.backgroundColor
        }
    }
}

// MARK: - UITextViewDelegate
extension SidedPointTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !DeepLinkService.willHandle(URL) else { return false }

        let webViewController = WKWebViewControllerFactory.generateWKWebViewController(with: URL)
        AppDelegate.shared?.mainNavigationController?.pushViewController(webViewController, animated: true)
        return false
    }
}
