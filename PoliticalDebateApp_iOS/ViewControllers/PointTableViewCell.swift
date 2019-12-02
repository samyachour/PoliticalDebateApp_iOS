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
            let description = (viewModel?.useFullDescription ?? false) ? viewModel?.point.description : viewModel?.point.shortDescription
            pointTextView.attributedText = MarkDownFormatter.format(description, with: [.font: GeneralFonts.text,
                                                                                        .foregroundColor: GeneralColors.text],
                                                                    hyperlinks: viewModel?.point.hyperlinks)
            pointTextView.sizeToFit()
            reloadConstraints()
            subscribeToCheckImageUpdates()
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

    private var isContext: Bool { viewModel?.point.side?.isContext == true }
    private static let cornerRadius: CGFloat = 26.0
    private static let inset: CGFloat = 10.0
    private var horizontalInset: CGFloat { isContext ? 0 : Self.inset }
    private var verticalInset: CGFloat { isContext ? 0 : Self.inset }
    private var containerVerticalInset: CGFloat { isContext ? 0 : 8.0 }

    // MARK: Stored constraints

    private var containerViewTopAnchor: NSLayoutConstraint?
    private var containerViewBottomAnchor: NSLayoutConstraint?
    private var textViewLeadingAnchor: NSLayoutConstraint?
    private var textViewTopAnchor: NSLayoutConstraint?
    private var textViewBottomAnchor: NSLayoutConstraint?
    private var imageViewTrailingAnchor: NSLayoutConstraint?

    // MARK: - UI Elements

    private lazy var containerView: UIView = {
        let containerView = UIView(frame: .zero)
        containerView.layer.cornerRadius = Self.cornerRadius
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

        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: PointsTableViewController.elementSpacing).isActive = true
        containerViewTopAnchor = containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: containerVerticalInset)
        containerViewTopAnchor?.isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -PointsTableViewController.elementSpacing)
            // Necessary to avoid conflicting with UIView-Encapsulated-Layout-Width
            .injectPriority(.required - 1).isActive = true
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -containerVerticalInset)
        containerViewBottomAnchor?.isActive = true

        textViewLeadingAnchor = pointTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: horizontalInset)
        textViewLeadingAnchor?.isActive = true
        textViewTopAnchor = pointTextView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: verticalInset)
        textViewTopAnchor?.isActive = true
        pointTextView.trailingAnchor.constraint(lessThanOrEqualTo: checkImageView.leadingAnchor, constant: -2).isActive = true
        textViewBottomAnchor = pointTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -verticalInset)
        textViewBottomAnchor?.isActive = true

        checkImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        imageViewTrailingAnchor = checkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -horizontalInset - 4)
        imageViewTrailingAnchor?.isActive = true
        checkImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // Constraints for sided and context points are different so we need to reload them when the viewModel changes
    private func reloadConstraints() {
        containerViewTopAnchor?.constant = containerVerticalInset
        containerViewBottomAnchor?.constant = -containerVerticalInset
        textViewLeadingAnchor?.constant = horizontalInset
        textViewTopAnchor?.constant = verticalInset
        textViewBottomAnchor?.constant = -verticalInset
        imageViewTrailingAnchor?.constant = -horizontalInset
    }

    private func toggleCheckImage(_ on: Bool) {
        // Make sure we aren't adding a check image to a context point
        guard !(on && isContext) else { return }

        UIView.animate(withDuration: GeneralConstants.standardAnimationDuration) {
            self.checkImageView.image = on ? UIImage.check : nil
            self.checkImageView.layoutIfNeeded()
        }
    }

    private func installViewBinds() {
        pointTextView.delegate = self
    }

    private func subscribeToCheckImageUpdates() {
        toggleCheckImage(false) // reset
        viewModel?.shouldShowCheckImageDriver
            .drive(onNext: { [weak self] shouldShowCheckImage in
                self?.toggleCheckImage(shouldShowCheckImage)
            }).disposed(by: disposeBag)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        guard !isContext else { return }

        UIView.animate(withDuration: GeneralConstants.quickAnimationDuration) {
            self.containerView.backgroundColor = highlighted ? GeneralColors.selected : self.viewModel?.backgroundColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Sometimes the cell truncates the last line of the textView
        // If that's the case we force recompute the frame height
        let size = pointTextView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        guard pointTextView.frame.size.height != size.height else { return }

        pointTextView.frame.size.height = size.height
        contentView.layoutIfNeeded()
    }
}

// MARK: - UITextViewDelegate

extension PointTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !DeepLinkService.willHandle(URL) else { return false }

        let webViewController = WKWebViewControllerFactory.generateWKWebViewController(with: URL)
        AppDelegate.shared?.mainNavigationController?.pushViewController(webViewController, animated: true)
        return false
    }
}
