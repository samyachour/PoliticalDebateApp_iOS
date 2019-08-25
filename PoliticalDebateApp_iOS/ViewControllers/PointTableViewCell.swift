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

            pointButton.setTitle(viewModel.point.description, for: .normal)
            contentView.backgroundColor = viewModel.point.side == .pro ? .blue : .red // TODO: Change
            gradientLayer = CAGradientLayer(start: .topCenter,
                                            end: .bottomCenter,
                                            colors: [UIColor.white, contentView.backgroundColor ?? .clear],
                                            type: .axial)
            checkImageView.isHidden = !viewModel.hasCompletedPaths
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

        pointButton.setTitle(nil, for: .normal)
        contentView.backgroundColor = nil
        gradientLayer = nil
        checkImageView.isHidden = true
        disposeBag = DisposeBag()
    }

    // MARK: - UI Properties

    private static let cornerRadius: CGFloat = 12.0

    // MARK: - UI Elements

    private lazy var pointButton: UIButton = {
        let debateTitleButton = ButtonWithHighlightedBackgroundColor(frame: .zero)
        debateTitleButton.setTitleColor(GeneralColors.text, for: .normal)
        debateTitleButton.setBackgroundColorHighlightState(highlighted: GeneralColors.background, unhighlighted: .clear)
        debateTitleButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0)
        debateTitleButton.titleLabel?.font = GeneralFonts.button
        debateTitleButton.titleLabel?.textAlignment = .left
        debateTitleButton.titleLabel?.numberOfLines = 0 // multiline
        debateTitleButton.titleLabel?.lineBreakMode = .byWordWrapping
        return debateTitleButton
    }()

    private lazy var checkImageView: UIImageView = {
        let checkImageView = UIImageView(frame: .zero)
        checkImageView.image = UIImage.check
        return checkImageView
    }()

    private var gradientLayer: CAGradientLayer?

    // MARK: - View constraints & Binding

    private func installConstraints() {
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = PointTableViewCell.cornerRadius
        if let gradientLayer = gradientLayer { contentView.layer.addSublayer(gradientLayer) }

        contentView.addSubview(pointButton)
        contentView.addSubview(checkImageView)

        pointButton.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false

        // Button takes up entire contentView but is beneath rest of UI elements
        pointButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        pointButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        pointButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        pointButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        checkImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        checkImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer?.frame = contentView.bounds
    }

    private func installViewBinds() {
        pointButton.addTarget(self, action: #selector(tappedToOpenPoint), for: .touchUpInside)
    }

    @objc private func tappedToOpenPoint() {
        // TODO: Push point VC
    }
}
