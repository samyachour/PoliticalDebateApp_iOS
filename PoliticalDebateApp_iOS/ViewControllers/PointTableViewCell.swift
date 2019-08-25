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
            guard let viewModel = viewModel else { return }

            containerView.backgroundColor = viewModel.point.side == .pro ? .customLightBlue : .customLightRed
            pointLabel.text = viewModel.point.description
            checkImageView.image = viewModel.hasCompletedPaths ? UIImage.check : nil
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

        containerView.backgroundColor = nil
        pointLabel.text = nil
        checkImageView.image = nil
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
        pointLabel.textColor = GeneralColors.text
        pointLabel.font = GeneralFonts.text
        pointLabel.numberOfLines = 0
        return pointLabel
    }()

    private lazy var checkImageView: UIImageView = {
        let checkImageView = UIImageView(frame: .zero)
        checkImageView.contentMode = .center
        return checkImageView
    }()

    // MARK: - View constraints & Binding

    private func installConstraints() {
        contentView.backgroundColor = GeneralColors.background
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(pointLabel)
        containerView.addSubview(checkImageView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        pointLabel.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: PointTableViewCell.inset).isActive = true
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: PointTableViewCell.inset).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -PointTableViewCell.inset).isActive = true
        // Need to set priority below required so as to not conflict with the built-in height anchor UIView-Encapsulated-Layout-Height
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -PointTableViewCell.inset).injectPriority(.required - 1).isActive = true

        pointLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: PointTableViewCell.inset).isActive = true
        pointLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: PointTableViewCell.inset).isActive = true
        pointLabel.trailingAnchor.constraint(equalTo: checkImageView.leadingAnchor).isActive = true
        pointLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -PointTableViewCell.inset).isActive = true

        checkImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -PointTableViewCell.inset).isActive = true
    }

    private func installViewBinds() {}

    @objc private func tappedToOpenPoint() {
        // TODO: Push point VC
    }
}
