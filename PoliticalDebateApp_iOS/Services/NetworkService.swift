//
//  NetworkService.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

var appBaseURL: String {
    #if DEBUG
    return "https://politicaldebateapp-debug.herokuapp.com/api/"
    #else
    return "https://politicaldebateapp-prod.herokuapp.com/api/"
    #endif
}

private protocol Networkable {
    associatedtype AppAPI: TargetType

    var provider: MoyaProvider<AppAPI> { get }
    func makeRequest(with appAPI: AppAPI) -> Single<Response>
}

struct NetworkService<T>: Networkable where T: CustomTargetType & AccessTokenAuthorizable {
    fileprivate let provider = MoyaProvider<T>(plugins: [
        NetworkLoggerPlugin(verbose: true),
        AccessTokenPlugin { SessionManager.shared.publicAccessToken }
        ])

    private let maxAttemptCount: UInt = 3

    func makeRequest(with appAPI: T) -> Single<Response> {
        #if TEST
        return makeTestRequest(with: appAPI)
        #else
        let request = provider.rx.request(appAPI)
            .filter(statusCode: appAPI.validSuccessCode)
            .do(onError: ErrorHandler.checkForThrottleError)
            .retryWhen(ErrorHandler.checkForConnectivityError)
            .retryWhen(ErrorHandler.shouldRetryRequest)

        switch appAPI.authorizationType {
        case .none:
            return request
        default: // If API requires authorization, handle 401's by getting new access token
            return request
                .retryWhen(SessionManager.shared.refreshAccessTokenIfNeeded)
        }
        #endif
    }

    // For returning stubbed sample data for the given API
    fileprivate let stubbingProvider = MoyaProvider<T>(stubClosure: MoyaProvider.immediatelyStub)

    private func makeTestRequest(with appAPI: T) -> Single<Response> {
        return stubbingProvider.rx.request(appAPI)
    }
}
