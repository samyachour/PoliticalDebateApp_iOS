//
//  BasicUIElementFactory.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/1/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

// Several of our screens (e.g. Login/Register & Account ViewControllers) use the same boilerplate UI elements
class BasicUIElementFactory {

    // Need to be able to add target to UIButton but use UIBarButtonItem in nav bar
    static func generateBarButton(title: String) -> (button: UIButton, barButton: UIBarButtonItem) {
        let basicBarButton = UIButton(frame: .zero)
        basicBarButton.setTitle(title, for: .normal)
        basicBarButton.setTitleColor(GeneralColors.softButton, for: .normal)
        basicBarButton.titleLabel?.font = UIFont.primaryRegular(14.0)
        return (basicBarButton, UIBarButtonItem(customView: basicBarButton))
    }

    static func generateButton(title: String? = nil, titleColor: UIColor = GeneralColors.hardButton) -> UIButton {
        let forgotPasswordButton = UIButton(frame: .zero)
        forgotPasswordButton.setTitle(title, for: .normal)
        forgotPasswordButton.setTitleColor(titleColor, for: .normal)
        forgotPasswordButton.titleLabel?.font = GeneralFonts.button
        return forgotPasswordButton
    }

    static func generateTextField(placeholder: String, secureTextEntry: Bool = false) -> UITextField {
        let basicTextField = UITextField(frame: .zero)
        basicTextField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                  attributes: [
                                                                    .font : GeneralFonts.text as Any,
                                                                    .foregroundColor: GeneralColors.softButton as Any])
        basicTextField.font = GeneralFonts.text
        basicTextField.textColor = GeneralColors.hardButton
        basicTextField.borderStyle = .roundedRect
        basicTextField.isSecureTextEntry = secureTextEntry
        return basicTextField
    }

    static func generateHeadingLabel(text: String) -> UILabel {
        let basicHeadingLabel = UILabel(frame: .zero)
        basicHeadingLabel.text = text
        basicHeadingLabel.textColor = GeneralColors.text
        basicHeadingLabel.font = GeneralFonts.text
        basicHeadingLabel.textAlignment = NSTextAlignment.center
        return basicHeadingLabel
    }

    static func generateStackViewContainer(arrangedSubviews: [UIView], spacing: CGFloat = 32) -> UIStackView {
        let stackViewContainer = UIStackView(arrangedSubviews: arrangedSubviews)
        stackViewContainer.alignment = .center
        stackViewContainer.distribution = .fill
        stackViewContainer.axis = .vertical
        stackViewContainer.spacing = spacing
        stackViewContainer.isLayoutMarginsRelativeArrangement = true
        stackViewContainer.layoutMargins = UIEdgeInsets(top: spacing,
                                                        left: 0,
                                                        bottom: spacing,
                                                        right: 0)
        return stackViewContainer
    }

    static func generateEmptyStateLabel(text: String) -> UILabel {
        let emptyStateLabel = UILabel(frame: .zero)
        emptyStateLabel.text = text
        emptyStateLabel.textColor = UIColor.customDarkGray1
        emptyStateLabel.font = UIFont.primaryRegular(24.0)
        emptyStateLabel.textAlignment = NSTextAlignment.center
        emptyStateLabel.alpha = 0.0
        return emptyStateLabel
    }

}
