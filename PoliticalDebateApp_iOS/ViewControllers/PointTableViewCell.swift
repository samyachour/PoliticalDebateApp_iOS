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
            if viewModel?.isRootPoint == true {
                bubbleContainerView.backgroundColor = viewModel?.bubbleColor
                bubbleLayer.fillColor = nil
            } else {
                bubbleLayer.fillColor = viewModel?.bubbleColor?.cgColor
                bubbleContainerView.backgroundColor = nil
            }
            descriptionTextView.attributedText = viewModel?.shouldFormatAsHeaderLabel == true ?
                NSAttributedString(string: viewModel?.description ?? "", attributes: [.font: GeneralFonts.largeText,
                                                                                      .foregroundColor: GeneralColors.text]) :
                MarkDownFormatter.format(viewModel?.description, with: [.font: GeneralFonts.text,
                                                                        .foregroundColor: GeneralColors.text],
                                         hyperlinks: viewModel?.point.hyperlinks)
            descriptionTextView.sizeToFit()
            separatorInset = viewModel?.shouldShowSeparator == true ? UIEdgeInsets(top: 0, left: Self.inset, bottom: 0, right: Self.inset) :
                UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
            toggleCheckImage(viewModel?.hasCompletedPaths == true)
            accessoryType = viewModel?.isRootPoint == true && viewModel?.point.side?.isContext == false ? .disclosureIndicator : .none
            reloadConstraints()
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
    private var isRootPoint: Bool { viewModel?.isRootPoint == true }
    private static let cornerRadius: CGFloat = 22.0
    private static let inset: CGFloat = 10.0
    private var horizontalInset: CGFloat { isContext ? 0 : Self.inset }
    private var verticalInset: CGFloat { isContext ? 0 : Self.inset }
    private var containerVerticalInset: CGFloat {
        if isContext {
            return 0
        } else if isRootPoint {
            return 12.0
        } else {
            return 8.0
        }
    }

    // MARK: Stored constraints

    private var containerViewTopAnchor: NSLayoutConstraint?
    private var containerViewBottomAnchor: NSLayoutConstraint?
    private var textViewLeadingAnchor: NSLayoutConstraint?
    private var textViewTopAnchor: NSLayoutConstraint?
    private var textViewBottomAnchor: NSLayoutConstraint?
    private var imageViewTrailingAnchor: NSLayoutConstraint?

    // MARK: - UI Elements

    private lazy var bubbleContainerView: UIView = {
        let containerView = UIView(frame: .zero)
        containerView.layer.cornerRadius = Self.cornerRadius
        return containerView
    }()

    private lazy var descriptionTextView = BasicUIElementFactory.generateDescriptionTextView()

    private lazy var checkImageView: UIImageView = {
        let checkImageView = UIImageView(frame: .zero)
        checkImageView.tintColor = .customLightGreen1
        return checkImageView
    }()

    private lazy var bubbleLayer = CAShapeLayer()

    // MARK: - View constraints & Binding

    private func installConstraints() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(bubbleContainerView)
        bubbleContainerView.addSubview(descriptionTextView)
        bubbleContainerView.addSubview(checkImageView)

        contentView.autoresizingMask = .flexibleHeight
        bubbleContainerView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false

        bubbleContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: PointsTableViewController.elementSpacing).isActive = true
        containerViewTopAnchor = bubbleContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: containerVerticalInset)
        containerViewTopAnchor?.isActive = true
        bubbleContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -PointsTableViewController.elementSpacing)
            // Necessary to avoid conflicting with UIView-Encapsulated-Layout-Width
            .injectPriority(.required - 1).isActive = true
        containerViewBottomAnchor = bubbleContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -containerVerticalInset)
            // Necessary to avoid conflicting with UIView-Encapsulated-Layout-Height
            .injectPriority(.required - 1)
        containerViewBottomAnchor?.isActive = true

        textViewLeadingAnchor = descriptionTextView.leadingAnchor.constraint(equalTo: bubbleContainerView.leadingAnchor, constant: horizontalInset)
        textViewLeadingAnchor?.isActive = true
        textViewTopAnchor = descriptionTextView.topAnchor.constraint(equalTo: bubbleContainerView.topAnchor, constant: verticalInset)
        textViewTopAnchor?.isActive = true
        descriptionTextView.trailingAnchor.constraint(equalTo: checkImageView.leadingAnchor, constant: -2).isActive = true
        textViewBottomAnchor = descriptionTextView.bottomAnchor.constraint(equalTo: bubbleContainerView.bottomAnchor, constant: -verticalInset)
        textViewBottomAnchor?.isActive = true

        checkImageView.centerYAnchor.constraint(equalTo: bubbleContainerView.centerYAnchor).isActive = true
        imageViewTrailingAnchor = checkImageView.trailingAnchor.constraint(equalTo: bubbleContainerView.trailingAnchor, constant: -horizontalInset - 4)
        imageViewTrailingAnchor?.isActive = true
        checkImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        checkImageView.setContentHuggingPriority(.required, for: .horizontal)
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
        // Ensure we're toggling it to a new state
        guard on && checkImageView.image == nil ||
            !on && checkImageView.image != nil else {
                return
        }

        // Make sure we aren't adding a check image to a context point
        guard !(on && isContext) else { return }

        UIView.animate(withDuration: GeneralConstants.standardAnimationDuration) {
            self.checkImageView.image = on ? UIImage.check : nil
            self.checkImageView.layoutIfNeeded()
        }
    }

    private func redrawBubbleWithTail(text: String, font: UIFont, bubbleTailSide: BubbleTailSide?) {
        let width = bubbleContainerView.frame.width
        let height = bubbleContainerView.frame.height

        let cornerControlPoint: CGFloat = 7.61
        let cornerWidth: CGFloat = 17.0
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: Self.cornerRadius, y: height))
        bezierPath.addLine(to: CGPoint(x: width - cornerWidth, y: height))
        bezierPath.addCurve(to: CGPoint(x: width, y: height - cornerWidth),
                            controlPoint1: CGPoint(x: width - cornerControlPoint, y: height),
                            controlPoint2: CGPoint(x: width, y: height - cornerControlPoint))
        bezierPath.addLine(to: CGPoint(x: width, y: cornerWidth))
        bezierPath.addCurve(to: CGPoint(x: width - cornerWidth, y: 0),
                            controlPoint1: CGPoint(x: width, y: cornerControlPoint),
                            controlPoint2: CGPoint(x: width - cornerControlPoint, y: 0))
        bezierPath.addLine(to: CGPoint(x: Self.cornerRadius, y: 0))
        bezierPath.addCurve(to: CGPoint(x: 4, y: 17),
                            controlPoint1: CGPoint(x: 11.61, y: 0),
                            controlPoint2: CGPoint(x: 4, y: cornerControlPoint))
        bezierPath.addLine(to: CGPoint(x: 4, y: height - 11))
        bezierPath.addCurve(to: CGPoint(x: 0, y: height),
                            controlPoint1: CGPoint(x: 4, y: height - 1),
                            controlPoint2: CGPoint(x: 0, y: height))
        bezierPath.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
        bezierPath.addCurve(to: CGPoint(x: 11.04, y: height - 4.04),
                            controlPoint1: CGPoint(x: 4.07, y: height + 0.43),
                            controlPoint2: CGPoint(x: 8.16, y: height - 1.06))
        bezierPath.addCurve(to: CGPoint(x: Self.cornerRadius, y: height),
                            controlPoint1: CGPoint(x: 16, y: height),
                            controlPoint2: CGPoint(x: 19, y: height))
        bezierPath.close()

        bubbleLayer.path = bezierPath.cgPath
        bubbleLayer.setAffineTransform(CGAffineTransform.identity) // reset
        switch bubbleTailSide {
        case .left,
             .none:
            bubbleLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
            bubbleLayer.frame = bubbleContainerView.frame.offsetBy(dx: 2, dy: 0)
        case .right:
            bubbleLayer.frame = bubbleContainerView.frame.offsetBy(dx: -2, dy: 0)
        }

        if bubbleLayer.superlayer == nil { contentView.layer.insertSublayer(bubbleLayer, below: bubbleContainerView.layer) }
    }

    private func installViewBinds() {
        descriptionTextView.delegate = self
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        guard !isContext, let viewModel = viewModel else { return }

        if viewModel.isRootPoint {
            UIView.animate(withDuration: GeneralConstants.quickAnimationDuration) {
                self.bubbleContainerView.backgroundColor = highlighted ? GeneralColors.selectedPoint : self.viewModel?.bubbleColor
            }
        } else {
            setBubbleLayerHighlighted(highlighted)
        }
    }

    private func setBubbleLayerHighlighted(_ on: Bool) {
        let endValue = on ? GeneralColors.selectedPoint.cgColor : viewModel?.bubbleColor?.cgColor
        let highlightAnimation = CABasicAnimation(keyPath: (\CAShapeLayer.fillColor)._kvcKeyPathString)
        highlightAnimation.fromValue = bubbleLayer.fillColor
        highlightAnimation.toValue = endValue
        highlightAnimation.duration = GeneralConstants.quickAnimationDuration
        bubbleLayer.add(highlightAnimation, forKey: "highlightAnimation")
        bubbleLayer.fillColor = endValue
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Sometimes the cell truncates the last line of the textView
        // If that's the case we force recompute the frame height
        let size = descriptionTextView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if descriptionTextView.frame.size.height != size.height {
            descriptionTextView.frame.size.height = size.height
            contentView.layoutIfNeeded()
        }

        if let viewModel = viewModel,
            !viewModel.isRootPoint {
            redrawBubbleWithTail(text: viewModel.description, font: GeneralFonts.text, bubbleTailSide: viewModel.bubbleTailSide)
        }
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
