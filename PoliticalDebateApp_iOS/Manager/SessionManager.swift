//
//  SessionManager.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import Moya
import RxCocoa
import RxSwift

public class SessionManager {

    public static let shared = SessionManager()
    private init() {}

    // MARK: Constants
    private enum SessionConstants {
        static let accessTokenKey = "accessToken"
        static let refreshTokenKey = "refreshToken"
    }

    // MARK: Token properties
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

    public var publicAccessToken: String {
        // If token is nil we send invalid empty token
        return accessToken ?? ""
    }

    public let isActiveRelay = BehaviorRelay<Bool>(value: false)

    private var refreshToken: String? {
        didSet {
            if let refreshToken = refreshToken {
                saveTokenToKeychain(refreshToken, withKey: AuthConstants.refreshTokenKey)
            } else {
                deleteTokenFromKeychain(withKey: AuthConstants.refreshTokenKey)
            }
        }
    }

    // MARK: Keychain
    private let tokenEncoding: String.Encoding = .utf8

    public func resumeSession() {
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

    // MARK: API interface
    private let authAPI = NetworkService<AuthAPI>()

    public let refreshAccessTokenIfNeeded = { (error: Observable<Error>) -> Observable<Void> in
        error.enumerated().flatMap { (index, error) -> Observable<Void> in
            guard let moyaError = error as? MoyaError,
                moyaError.response?.statusCode == 401,
                // Make sure this is our first refresh attempt
                index == 0 else {
                    return .error(error) // Pass the error along
            }
            guard let refreshToken = SessionManager.shared.refreshToken else { // Make sure we have a refresh token
                SessionManager.shared.logout()
                throw error // cancel source request
            }
            return SessionManager.shared.authAPI.makeRequest(with: .tokenRefresh(refreshToken: refreshToken))
                .asObservable()
                .flatMap({ (response) -> Observable<Void> in
                    guard response.statusCode == 200,
                        let newAccessToken = try? JSONDecoder().decode(TokenPair.self, from: response.data) else {
                            SessionManager.shared.logout()
                            throw error // cancel source request
                    }
                    SessionManager.shared.accessToken = newAccessToken.accessTokenString
                    return .just(()) // retry source request
                })
        }
    }

    public func login(email: String, password: String) -> Single<Void> {
        return authAPI.makeRequest(with: .tokenObtain(email: email,
                                                                        password: password))
            .flatMap({ (response) -> Single<Void> in
                switch response.statusCode {
                case 200:
                    guard let newTokenPair = try? JSONDecoder().decode(TokenPair.self, from: response.data) else {
                        return .error(SessionError.couldNotLogin)
                    }
                    // Can capture self since it's a singleton, always in memory
                    self.refreshToken = newTokenPair.refreshTokenString
                    self.accessToken = newTokenPair.accessTokenString
                    return .just(())
                default:
                    return .error(SessionError.couldNotLogin)
                }
            })
    }

    public func logout() {
        accessToken = nil
        refreshToken = nil
    }
}

// MARK: Custom error
public enum SessionError {
    case couldNotLogin
}

extension SessionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .couldNotLogin:
            return "Could not login"
        }
    }
}
