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

class SessionManager {

    public static let shared = SessionManager()
    private init() {}

    // MARK: Constants
    private enum SessionConstants {
        static let accessTokenKey = "accessToken"
        static let refreshTokenKey = "refreshToken"
    }

    // MARK: Properties
    private var accessToken: String? {
        didSet {
            if let accessToken = accessToken {
                saveTokenToKeychain(accessToken, withKey: AuthConstants.accessTokenKey)
            }
        }
    }

    public var publicAccessToken: String {
        // If token is nil we send invalid empty token
        return accessToken ?? ""
    }

    public var isActive: Bool {
        return accessToken != nil
    }

    private var refreshToken: String? {
        didSet {
            if let refreshToken = refreshToken {
                saveTokenToKeychain(refreshToken, withKey: AuthConstants.refreshTokenKey)
            }
        }
    }

    // MARK: Keychain
    public func resumeSession() {
        accessToken = KeychainService.load(key: AuthConstants.accessTokenKey)?.to(type: type(of: accessToken))
        refreshToken = KeychainService.load(key: AuthConstants.refreshTokenKey)?.to(type: type(of: refreshToken))
    }

    // If the user is authenticated, save the token to the user's keychain
    private func saveTokenToKeychain(_ token: String, withKey key: String) {
        KeychainService.save(key: key, data: Data(from: token))
    }

    // MARK: API interface
    public let refreshAccessTokenIfNeeded = { (error: Observable<Error>) -> Observable<Void> in
        error.enumerated().flatMap { (index, error) -> Observable<Void> in
            guard let moyaError = error as? MoyaError,
                moyaError.response?.statusCode == 401,
                // Make sure this is our first refresh attempt
                index == 0 else {
                    return .error(error) // Pass the error along
            }
            guard let refreshToken = SessionManager.shared.refreshToken else { // Make sure we have a refresh token
                // TODO: Log the user out
                throw error // cancel source request
            }
            return NetworkService<AuthAPI>().makeRequest(with: .tokenRefresh(refreshToken: refreshToken))
                .asObservable()
                .flatMap({ (response) -> Observable<Void> in
                    guard response.statusCode == 200,
                        let newAccessToken = try? JSONDecoder().decode(AccessToken.self, from: response.data) else {
                            // TODO: Log the user out
                            throw error // cancel source request
                    }
                    SessionManager.shared.accessToken = newAccessToken.accessTokenString
                    return .just(()) // retry source request
                })
        }
    }

    public func login(email: String, password: String) -> Single<Void> {
        return NetworkService<AuthAPI>().makeRequest(with: .tokenObtain(email: email,
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
