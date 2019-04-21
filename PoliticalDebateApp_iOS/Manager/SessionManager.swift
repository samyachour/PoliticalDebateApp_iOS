//
//  SessionManager.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

// Shared instance of session
// Attach token to all authorized requests
// Save token in keychain
// If token is expired, refresh
// If token refresh is expired, log out user
// Create timer to refresh token using background qos

class SessionManager {

    public static let shared = SessionManager()

    private var token: String?
    public var publicToken: String? {
        return token
    }
    public var isActive: Bool {
        return token != nil
    }

    private let tokenKey = "accessToken"

    // If the user is authenticated, refresh their token
    public func refreshToken() {
        guard let token = token else {
            return
        }
        // Restart timer


    }

    // If user was authenticated and token was saved to keychain successfully, resume session by refreshing token
    public func resumeSession() {
        guard token == nil else {
            return
        }

        token = KeychainService.load(key: tokenKey)?.to(type: type(of: token))
        refreshToken()
    }

    // If the user is authenticated, save the token to the user's keychain
    public func saveTokenToKeychain() {
        guard let token = token else {
            return
        }

        KeychainService.save(key: tokenKey, data: Data(from: token))
    }
}
