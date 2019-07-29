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

struct NetworkService<T>: Networkable where T: TargetType {
    fileprivate let provider = MoyaProvider<T>(plugins: [
        NetworkLoggerPlugin(verbose: true),
        AccessTokenPlugin { SessionManager.shared.publicAccessToken }
        ])

    private let maxAttemptCount: UInt = 3

    func makeRequest(with appAPI: T) -> Single<Response> {
        #if TEST
        return makeTestRequest(with: appAPI)
        #else
        return provider.rx.request(appAPI)
            .filterSuccessfulStatusAndRedirectCodes()
            .do(onError: ErrorHandler.checkForThrottleError)
            .do(onError: ErrorHandler.checkForConnectivityError)
            .asObservable()
            .retryWhen(ErrorHandler.shouldRetryRequest)
            .retryWhen(SessionManager.shared.refreshAccessTokenIfNeeded)
            .asSingle()
        #endif
    }

    // For returning stubbed sample data for the given API
    fileprivate let stubbingProvider = MoyaProvider<T>(stubClosure: MoyaProvider.immediatelyStub)

    private func makeTestRequest(with appAPI: T) -> Single<Response> {
        return stubbingProvider.rx.request(appAPI)
    }
}
