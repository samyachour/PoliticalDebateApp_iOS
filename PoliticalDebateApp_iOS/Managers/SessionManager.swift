//
//  SessionManager.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Alamofire
import Foundation
import Moya
import RxCocoa
import RxSwift

class SessionManager {

    static let shared = SessionManager()

    private init() {}

    // MARK: - Token properties

    // Private

    private var accessToken: String? {
        didSet {
            if let accessToken = accessToken {
                saveTokenToKeychain(accessToken, withKey: AuthAPI.Constants.accessTokenKey)
            } else {
                deleteTokenFromKeychain(withKey: AuthAPI.Constants.accessTokenKey)
            }
            // If we set the accessToken to/from nil
            if (oldValue == nil) != (accessToken == nil) {
                isActiveRelay.accept(accessToken != nil)
            }
        }
    }

    private var refreshToken: String? {
        didSet {
            if let refreshToken = refreshToken {
                saveTokenToKeychain(refreshToken, withKey: AuthAPI.Constants.refreshTokenKey)
            } else {
                deleteTokenFromKeychain(withKey: AuthAPI.Constants.refreshTokenKey)
            }
        }
    }

    private let isActiveRelay = BehaviorRelay<Bool>(value: false)

    // Internal

    var publicAccessToken: String {
        // If token is nil we send invalid empty token
        return accessToken ?? ""
    }

    lazy var isActiveDriver = isActiveRelay.asDriver().distinctUntilChanged()
    var isActive: Bool { return isActiveRelay.value }

    // MARK: - Keychain

    // Private

    private static let tokenEncoding: String.Encoding = .utf8

    // If the user is authenticated, save the token to the user's keychain
    private func saveTokenToKeychain(_ token: String, withKey key: String) {
        if let tokenData = token.data(using: Self.tokenEncoding) {
            KeychainService.save(key: key, data: tokenData)
        }
    }

    private func deleteTokenFromKeychain(withKey key: String) {
        KeychainService.delete(key: key)
    }

    // Internal

    func resumeSession() {
       guard let accessTokenData = KeychainService.load(key: AuthAPI.Constants.accessTokenKey),
           let refreshTokenData = KeychainService.load(key: AuthAPI.Constants.refreshTokenKey) else {
               return
       }
       accessToken = String(data: accessTokenData, encoding: Self.tokenEncoding)
       refreshToken = String(data: refreshTokenData, encoding: Self.tokenEncoding)
   }

    // MARK: - API interface

    // Private

    private lazy var authAPI = NetworkService<AuthAPI>()

    private func refreshTokenHasExpired() -> Observable<Void> {
        logout()
        NotificationBannerQueue.shared
            .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                              title: GeneralError.refreshTokenExpired.localizedDescription))
        return .error(GeneralError.alreadyHandled) // so consumer knows
    }

    private lazy var handleRefreshTokenError: (Error) -> Observable<Void> = { error -> Observable<Void> in
        if let generalError = error as? GeneralError,
            generalError == .alreadyHandled {
            return .error(error)
        }
        guard let moyaError = error as? MoyaError,
            let response = moyaError.response,
            // Only know the refresh token is expired if we explicitly are told so by the backend
            response.statusCode == GeneralConstants.unauthorizedErrorCode else {
                return .error(error)
        }

        return self.refreshTokenHasExpired()
    }

    // Internal

    lazy var refreshAccessTokenIfNeeded = { (error: Observable<Error>) -> Observable<Void> in
        error.enumerated().flatMap { (index, error) -> Observable<Void> in
            guard let moyaError = error as? MoyaError,
                moyaError.response?.statusCode == GeneralConstants.unauthorizedErrorCode,
                // Make sure this is our first refresh attempt
                index == 0 else {
                    return .error(error) // Pass the error along
            }

            guard let refreshToken = self.refreshToken else { return self.refreshTokenHasExpired() }

            return self.authAPI.makeRequest(with: .tokenRefresh(refreshToken: refreshToken))
                .map(TokenPair.self)
                .do(onSuccess: { self.accessToken = $0.accessTokenString })
                .asObservable()
                .map({ _ in }) // retry source request
                .catchError(self.handleRefreshTokenError)
        }
    }

    func login(email: String, password: String) -> Single<Void> {
        return authAPI.makeRequest(with: .tokenObtain(email: email,
                                                      password: password))
            .map(TokenPair.self)
            .do(onSuccess: { tokenPair in
                self.refreshToken = tokenPair.refreshTokenString
                self.accessToken = tokenPair.accessTokenString

                #if !TEST
                NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .success,
                                                                                                title: "Successfully logged in",
                                                                                                subtitle: "Syncing your local data to the cloud, please wait..."))
                UserDataManager.shared.syncUserDataToBackend()
                #endif
            })
            .map({ _ in }) // consumer shouldn't see the tokenPair
    }

    func logout() {
        accessToken = nil
        refreshToken = nil

        UserDataManager.shared.clearUserData()
        // Prepares our core data persistent container for reading/writing data
        UserDataManager.shared.loadUserData()
    }
}
