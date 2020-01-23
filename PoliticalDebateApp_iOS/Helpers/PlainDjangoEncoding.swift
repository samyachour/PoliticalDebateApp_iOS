//
//  PlainDjangoEncoding.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Alamofire

/// Custom encoding that does not add unnecessary characters like '?=' to the URL parameters.
/// Needed because Django has very clean url parameter encoding, e.g. 'api/v1/debate/1'.
/// Alamofire custom URL encoding automatically assumes parameters need to be encoded further e.g. 'debate/?=1'.
struct PlainDjangoEncoding: ParameterEncoding {

    /// Encode data into a GET request URL without any extra formatting
    /// - Parameters:
    ///   - urlRequest: the request
    ///   - parameters: the parameters to encode in the URL
    /// - Returns: the formatted request
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()

        // Ensure parameters are included
        // Only supports single parameter GET requests
        guard let parameters = parameters,
            parameters.values.count == 1,
            urlRequest.httpMethod == "GET"
        else {
            throw AFError.parameterEncodingFailed(reason: .customEncodingFailed(error: PlainDjangoEncodingError.invalidParameterNumber))
        }

        guard let url = urlRequest.url else {
            throw AFError.parameterEncodingFailed(reason: .missingURL)
        }

        // Only supports String or Int parameters
        if let param = parameters.values.first as? String {
            urlRequest.url = URL.init(string: url.absoluteString + param)
        } else if let param = parameters.values.first as? Int {
            urlRequest.url = URL.init(string: url.absoluteString + String(param))
        } else {
            throw AFError.parameterEncodingFailed(reason: .customEncodingFailed(error: PlainDjangoEncodingError.invalidParameterType))
        }
        return urlRequest
    }
}

enum PlainDjangoEncodingError: Error {
    case invalidParameterNumber
    case invalidParameterType

    var localizedDescription: String {
        switch self {
        case .invalidParameterNumber:
            return NSLocalizedString("Must pass in 1 parameter in a GET request method", comment: "Invalid parameters")
        case .invalidParameterType:
            return NSLocalizedString("Must pass in either a String or an Int", comment: "Invalid parameter")
        }
    }
}
