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
            containerView.backgroundColor = viewModel?.point.side?.color
            pointLabel.attributedText = MarkDownFormatter.format(viewModel?.point.shortDescription, with: [.font: GeneralFonts.text,
                                                                                                           .foregroundColor: GeneralColors.text])
            checkImageView.image = (viewModel?.hasCompletedPaths ?? false) ? UIImage.check : nil
        }
    }

    private var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        installConstraints()
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
    private static let inset: CGFloat = 16.0

    // MARK: - UI Elements

    private lazy var containerView: UIView = {
        let containerView = UIView(frame: .zero)
        containerView.layer.cornerRadius = PointTableViewCell.cornerRadius
        return containerView
    }()

    private lazy var pointLabel: UILabel = {
        let pointLabel = UILabel(frame: .zero)
        pointLabel.numberOfLines = 0
        return pointLabel
    }()

    private lazy var checkImageView: UIImageView = {
        let checkImageView = UIImageView(frame: .zero)
        checkImageView.contentMode = .right
        checkImageView.tintColor = .customLightGreen2
        return checkImageView
    }()

    // MARK: - View constraints & Binding

    private func installConstraints() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(pointLabel)
        containerView.addSubview(checkImageView)

        contentView.autoresizingMask = .flexibleHeight
        containerView.translatesAutoresizingMaskIntoConstraints = false
        pointLabel.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: PointTableViewCell.inset).isActive = true
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: PointTableViewCell.inset).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -PointTableViewCell.inset).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -PointTableViewCell.inset).isActive = true

        pointLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: PointTableViewCell.inset).isActive = true
        pointLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: PointTableViewCell.inset).isActive = true
        pointLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkImageView.leadingAnchor).isActive = true
        pointLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -PointTableViewCell.inset).isActive = true

        checkImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -PointTableViewCell.inset).isActive = true
    }

}
