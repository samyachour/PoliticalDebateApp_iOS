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
    private var accessToken: String? {
        didSet {
            if let accessToken = accessToken {
                saveTokenToKeychain(accessToken, withKey: AuthConstants.accessTokenKey)
            } else {
                deleteTokenFromKeychain(withKey: AuthConstants.accessTokenKey)
            }
            // If we set the accessToken to/from nil
            if (oldValue == nil) != (accessToken == nil) {
                isActiveRelay.accept(accessToken != nil)
            }
        }
    }

    var publicAccessToken: String {
        // If token is nil we send invalid empty token
        return accessToken ?? ""
    }

    let isActiveRelay = BehaviorRelay<Bool>(value: false)

    private var refreshToken: String? {
        didSet {
            if let refreshToken = refreshToken {
                saveTokenToKeychain(refreshToken, withKey: AuthConstants.refreshTokenKey)
            } else {
                deleteTokenFromKeychain(withKey: AuthConstants.refreshTokenKey)
            }
        }
    }

    // MARK: - Keychain
    private let tokenEncoding: String.Encoding = .utf8

    func resumeSession() {
        guard let accessTokenData = KeychainService.load(key: AuthConstants.accessTokenKey),
            let refreshTokenData = KeychainService.load(key: AuthConstants.refreshTokenKey) else {
                return
        }
        accessToken = String(data: accessTokenData, encoding: tokenEncoding)
        refreshToken = String(data: refreshTokenData, encoding: tokenEncoding)
    }

    // If the user is authenticated, save the token to the user's keychain
    private func saveTokenToKeychain(_ token: String, withKey key: String) {
        if let tokenData = token.data(using: tokenEncoding) {
            KeychainService.save(key: key, data: tokenData)
        }
    }

    private func deleteTokenFromKeychain(withKey key: String) {
        KeychainService.delete(key: key)
    }

    // MARK: - API interface
    private let authAPI = NetworkService<AuthAPI>()
    static let unauthorizedStatusCode = 401

    let refreshAccessTokenIfNeeded = { (error: Observable<Error>) -> Observable<Void> in
        error.enumerated().flatMap { (index, error) -> Observable<Void> in
            guard (error as? MoyaError)?.response?.statusCode == SessionManager.unauthorizedStatusCode ||
                (error as? Alamofire.AFError)?.responseCode == SessionManager.unauthorizedStatusCode,
                // Make sure this is our first refresh attempt
                index == 0 else {
                    return .error(error) // Pass the error along
            }

            guard let refreshToken = SessionManager.shared.refreshToken else { // Make sure we have a refresh token
                SessionManager.shared.logout()
                NotificationBannerQueue.shared
                    .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                      title: GeneralError.refreshTokenExpired.localizedDescription))
                throw GeneralError.alreadyHandled // so consumer knows
            }

            return SessionManager.shared.authAPI.makeRequest(with: .tokenRefresh(refreshToken: refreshToken))
                .asObservable()
                .flatMap({ (response) -> Observable<Void> in
                    guard response.statusCode == 200,
                        let newAccessToken = try? JSONDecoder().decode(TokenPair.self, from: response.data) else {
                            SessionManager.shared.logout()
                            NotificationBannerQueue.shared.enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                                                            title: GeneralError.refreshTokenExpired.localizedDescription))
                            throw GeneralError.alreadyHandled // so consumer knows
                    }
                    SessionManager.shared.accessToken = newAccessToken.accessTokenString
                    return .just(()) // retry source request
                })
        }
    }

    func login(email: String, password: String) -> Single<Void> {
        return authAPI.makeRequest(with: .tokenObtain(email: email,
                                                      password: password))
            .map(TokenPair.self)
            .do(onSuccess: { (tokenPair) in
                // Can capture self since it's a singleton, always in memory
                self.refreshToken = tokenPair.refreshTokenString
                self.accessToken = tokenPair.accessTokenString

                #if !TEST
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
