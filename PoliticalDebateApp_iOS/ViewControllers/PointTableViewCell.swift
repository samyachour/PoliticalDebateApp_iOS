//
//  PointTableViewCell.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/24/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift
import UIKit

class PointTableViewCell: UITableViewCell {
    static let reuseIdentifier = "PointTableViewCell"

    var viewModel: PointTableViewCellViewModel? {
        didSet {
            containerView.backgroundColor = viewModel?.backgroundColor
            pointTextView.attributedText = MarkDownFormatter.format(viewModel?.point.shortDescription, with: [.font: GeneralFonts.text,
                                                                                                           .foregroundColor: GeneralColors.text],
                                                                    hyperlinks: viewModel?.point.hyperlinks)
            pointTextView.sizeToFit()
            UIView.animate(withDuration: Constants.standardAnimationDuration) { [weak self] in
                self?.checkImageView.image = (self?.viewModel?.hasCompletedPaths ?? false) ? UIImage.check : nil
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
        containerView.layer.cornerRadius = PointTableViewCell.cornerRadius
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

        pointTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: PointTableViewCell.inset).isActive = true
        pointTextView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: PointTableViewCell.inset).isActive = true
        pointTextView.trailingAnchor.constraint(lessThanOrEqualTo: checkImageView.leadingAnchor, constant: -2).isActive = true
        pointTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -PointTableViewCell.inset).isActive = true

        checkImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -PointTableViewCell.inset - 4).isActive = true
        checkImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func installViewBinds() {
        pointTextView.delegate = self
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        UIView.animate(withDuration: Constants.quickAnimationDuration) { [weak self] in
            if highlighted {
                self?.containerView.backgroundColor = GeneralColors.selected
            } else {
                self?.containerView.backgroundColor = self?.viewModel?.backgroundColor
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension PointTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}
