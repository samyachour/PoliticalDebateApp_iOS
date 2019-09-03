//
//  SinglePointImageViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/1/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import AVFoundation
import UIKit

class SinglePointImageViewController: UIViewController {

    required init(viewModel: SinglePointImageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let viewModel: SinglePointImageViewModel

    // MARK: - VC Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        installViewConstraints()
        imageView.load(url: viewModel.pointImage.url) { [weak self] in
            self?.moveLabelUnderImage()
        }
    }

    // MARK: - View constriants

    private func installViewConstraints() {
        view.addSubview(imageView)
        view.addSubview(nameAndSourceLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameAndSourceLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topLayoutAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomLayoutAnchor).injectPriority(.required - 1).isActive = true

        nameAndSourceLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 2).isActive = true
        nameAndSourceLabelTopAnchor = nameAndSourceLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor,
                                                                              constant: SinglePointImageViewController.imageToLabelDistance)
        nameAndSourceLabelTopAnchor?.isActive = true
        nameAndSourceLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        nameAndSourceLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomLayoutAnchor).isActive = true
    }

    // MARK: - Helpers

    private func moveLabelUnderImage() {
        guard let imageSize = imageView.image?.size else { return }

        let imageAspectRect = AVMakeRect(aspectRatio: imageSize, insideRect: imageView.bounds)
        let imageBottomOffset = imageView.bounds.maxY - imageAspectRect.maxY
        nameAndSourceLabelTopAnchor?.constant = -imageBottomOffset + SinglePointImageViewController.imageToLabelDistance
    }

    // MARK: - UI Properties

    private static let imageToLabelDistance: CGFloat = 4.0
    private var nameAndSourceLabelTopAnchor: NSLayoutConstraint?

    // MARK: - UI Elements

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var nameAndSourceLabel: UILabel = {
        let nameAndSourceLabel = UILabel(frame: .zero)
        nameAndSourceLabel.numberOfLines = 0
        nameAndSourceLabel.font = UIFont.primaryMedium(12.0)
        nameAndSourceLabel.textColor = .customDarkGray2
        if let imageName = viewModel.pointImage.name {
            nameAndSourceLabel.text = "\(imageName) - \(viewModel.pointImage.source)"
        } else {
            nameAndSourceLabel.text = viewModel.pointImage.source
        }
        return nameAndSourceLabel
    }()
}

private extension UIImageView {
    func load(url: URL, completion: (() -> Void)?) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                        completion?()
                    }
                }
            }
        }
    }
}
