//
//  LoginOrRegisterViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxCocoa
import RxSwift

public enum LoginOrRegisterState: String {
    case login = "Login" // for labels
    case register = "Register"
}

public class LoginOrRegisterViewModel {

    public var loginOrRegisterState = LoginOrRegisterState.login
}
