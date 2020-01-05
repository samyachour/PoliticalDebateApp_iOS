//
//  BasicUIElementFactory.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/1/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

/// Several of our screens (e.g. Login/Register & Account ViewControllers) use the same boilerplate UI elements
struct BasicUIElementFactory {

    private init() {}

    // Need to be able to add target to UIButton but use UIBarButtonItem in nav bar
    static func generateBarButton(title: String? = nil, image: UIImage? = nil) -> (button: UIButton, barButton: UIBarButtonItem) {
        let basicBarButton = UIButton(frame: .zero)
        basicBarButton.setTitle(title, for: .normal)
        basicBarButton.setTitleColor(GeneralColors.navBarButton, for: .normal)
        basicBarButton.titleLabel?.font = .primaryRegular(16.0)
        basicBarButton.setImage(image, for: .normal)
        basicBarButton.tintColor = GeneralColors.navBarButton
        return (basicBarButton, UIBarButtonItem(customView: basicBarButton))
    }

    static func generateButton(title: String? = nil,
                               titleColor: UIColor = GeneralColors.hardButton,
                               font: UIFont = GeneralFonts.button) -> UIButton {
        let forgotPasswordButton = UIButton(frame: .zero)
        forgotPasswordButton.setTitle(title, for: .normal)
        forgotPasswordButton.setTitleColor(titleColor, for: .normal)
        forgotPasswordButton.titleLabel?.font = font
        return forgotPasswordButton
    }

    static func generateTextField(placeholder: String,
                                  secureTextEntry: Bool = false,
                                  keyboardType: UIKeyboardType = .default,
                                  returnKeyType: UIReturnKeyType = .default,
                                  delegate: UITextFieldDelegate? = nil) -> UITextField {
        let basicTextField = UITextField(frame: .zero)
        basicTextField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                  attributes: [
                                                                    .font : GeneralFonts.text,
                                                                    .foregroundColor: GeneralColors.softButton])
        basicTextField.font = GeneralFonts.text
        basicTextField.textColor = GeneralColors.hardButton
        basicTextField.borderStyle = .roundedRect
        basicTextField.isSecureTextEntry = secureTextEntry
        basicTextField.returnKeyType = returnKeyType
        basicTextField.delegate = delegate
        return basicTextField
    }

    static func generateLabel(text: String? = nil,
                              font: UIFont = GeneralFonts.text,
                              color: UIColor = GeneralColors.text,
                              textAlignment: NSTextAlignment = .natural) -> UILabel {
        let basicHeadingLabel = UILabel(frame: .zero)
        basicHeadingLabel.text = text
        basicHeadingLabel.textColor = color
        basicHeadingLabel.font = font
        basicHeadingLabel.textAlignment = textAlignment
        basicHeadingLabel.numberOfLines = 0
        return basicHeadingLabel
    }

    static func generateStackViewContainer(arrangedSubviews: [UIView],
                                           verticalSpacing: CGFloat = 32,
                                           horizontalSpacing: CGFloat = 8) -> UIStackView {
        let stackViewContainer = UIStackView(arrangedSubviews: arrangedSubviews)
        stackViewContainer.alignment = .center
        stackViewContainer.distribution = .fill
        stackViewContainer.axis = .vertical
        stackViewContainer.spacing = verticalSpacing
        stackViewContainer.isLayoutMarginsRelativeArrangement = true
        stackViewContainer.layoutMargins = UIEdgeInsets(top: verticalSpacing,
                                                        left: horizontalSpacing,
                                                        bottom: verticalSpacing,
                                                        right: horizontalSpacing)
        return stackViewContainer
    }

    static func generateEmptyStateLabel(text: String) -> UILabel {
        let emptyStateLabel = UILabel(frame: .zero)
        emptyStateLabel.text = text
        emptyStateLabel.textColor = GeneralColors.lightLabel
        emptyStateLabel.font = .primaryRegular(24.0)
        emptyStateLabel.textAlignment = NSTextAlignment.center
        emptyStateLabel.alpha = 0.0
        return emptyStateLabel
    }

    static func generateComplianceTextView(login: Bool) -> UITextView {
        let complianceTextView = UITextView(frame: .zero)
        complianceTextView.isEditable = false
        complianceTextView.dataDetectorTypes = .link
        complianceTextView.isUserInteractionEnabled = true
        complianceTextView.isScrollEnabled = false
        complianceTextView.backgroundColor = .clear

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.primaryRegular(14.0),
                                                         .foregroundColor: GeneralColors.lightLabel]
        let privacyPolicyString = "Privacy Policy"
        let termsAndConditionsString = "Terms and Conditions"
        let complianceString = login ? "By continuing, you agree to the Political Debate app's \(privacyPolicyString) and \(termsAndConditionsString)." :
        "\(privacyPolicyString) and \(termsAndConditionsString)"
        if let privacyPolicyUrl = URL(string: "https://samyachour.github.io/PoliticalDebateApp/PrivacyPolicy.html"),
            let termsAndConditionsUrl = URL(string: "https://samyachour.github.io/PoliticalDebateApp/TermsAndConditions.html") {
            let hyperlinks = [PointHyperlink(substring: privacyPolicyString, url: privacyPolicyUrl),
                              PointHyperlink(substring: termsAndConditionsString, url: termsAndConditionsUrl)]
            complianceTextView.attributedText = MarkDownFormatter.format(complianceString, with: attributes, hyperlinks: hyperlinks)

            complianceTextView.textAlignment = .center
            complianceTextView.sizeToFit()
        }
        return complianceTextView
    }

    static func generateVersionLabel() -> UILabel {
        let versionLabel = UILabel(frame: .zero)
        versionLabel.textAlignment = .center
        versionLabel.font = .primaryLight(16.0)
        versionLabel.textColor = GeneralColors.lightLabel
        if let infoDict = Bundle.main.infoDictionary,
            let version = infoDict["CFBundleShortVersionString"] as? String,
            let build = infoDict["CFBundleVersion"] as? String {
            versionLabel.text = "Version \(version) (\(build))"
        }
        return versionLabel
    }

    static func generateDescriptionTextView(_ attributedText: NSAttributedString? = nil) -> UITextView {
        let descriptionTextView = LinkResponsiveTextView(frame: .zero)
        descriptionTextView.isEditable = false
        descriptionTextView.dataDetectorTypes = .link
        descriptionTextView.isUserInteractionEnabled = true
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.attributedText = attributedText
        descriptionTextView.sizeToFit()
        return descriptionTextView
    }

    static func generateLoadingIndicator(style: UIActivityIndicatorView.Style = .whiteLarge) -> UIActivityIndicatorView {
        let loadingIndicator = UIActivityIndicatorView(style: style)
        loadingIndicator.color = GeneralColors.loadingIndicator
        loadingIndicator.hidesWhenStopped = true
        return loadingIndicator
    }

    static func generateTableView(contentInset: UIEdgeInsets = .zero,
                                  separatorStyle: UITableViewCell.SeparatorStyle = .none,
                                  rowHeight: CGFloat = UITableView.automaticDimension,
                                  estimatedRowHeight: CGFloat = 64) -> UITableView {
        let tableView = UITableView(frame: .zero)
        tableView.separatorStyle = separatorStyle
        tableView.backgroundColor = .clear
        tableView.rowHeight = rowHeight
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.contentInset = contentInset
        tableView.delaysContentTouches = false
        return tableView
    }

    static func generateProgressView() -> UIProgressView {
        let progressView = UIProgressView()
        progressView.progressTintColor = .customLightGreen2
        progressView.trackTintColor = .clear
        return progressView
    }

}
