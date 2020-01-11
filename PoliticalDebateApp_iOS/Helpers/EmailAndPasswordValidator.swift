//
//  EmailAndPasswordValidator.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 7/31/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

struct EmailAndPasswordValidator {

    private init() {}

    static func isValidEmail(_ email: String) -> Bool {
        let handlePart = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
        let serverPart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
        let emailRegex = handlePart + "@" + serverPart + "[A-Za-z]{2,8}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= GeneralConstants.minimumPasswordLength
    }
}
