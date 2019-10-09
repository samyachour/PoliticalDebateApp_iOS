//
//  ButtonWithActionClosure.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import UIKit

class ButtonWithActionClosure: UIButton {

    required init(action: (() -> Void)? = nil) {
        self.action = action

        super.init(frame: .zero)

        self.addTarget(self, action: #selector(buttonClicked(_:)), for: .primaryActionTriggered)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func buttonClicked(_ sender: Any?) {
        self.action?()
    }

    private let action: (() -> Void)?
}
