//
//  AccountViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

class AccountViewModel {
    // MARK: - Dependencies

    private let authNetworkService = NetworkService<AuthAPI>()

    // MARK: - API Requests

    func changeEmail(to newEmail: String) -> Single<Response> {
        return authNetworkService.makeRequest(with: .changeEmail(newEmail: newEmail))
    }

    // Backend uses 'old' vocabulary
    func changePassword(from oldPassword: String, to newPassword: String) -> Single<Response> {
        return authNetworkService.makeRequest(with: .changePassword(oldPassword: oldPassword, newPassword: newPassword))
    }

    func deleteAccount() -> Single<Response> {
        return authNetworkService.makeRequest(with: .delete)
    }

}
