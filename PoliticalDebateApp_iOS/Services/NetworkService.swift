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
import RxSwiftExt

var appBaseURL: String {
    // TODO: Change URLs
    #if DEBUG
    // In our build phases we have a script that runs after ProcessInfoPlistFile & allows ATS HTTP for the Debug environment
    return "http://localhost:8000/api/v1/"
    #else
    return "https://server:8000/api/v1/"
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
