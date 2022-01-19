//
//  NetworkProvider.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/2/25.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Moya
import Alamofire

let timeoutInterval: TimeInterval = 15

public class NetworkProvider: MoyaProvider<MultiTarget> {
    
    public static let shared = NetworkProvider()
    let extraEndpointClosures: [ExtraEndpointClosure]
    public var failureMap: ((Error) -> Error) = { $0 }
    private init(plugins: [PluginType] = []) {
        var plugins = plugins
        plugins.append(contentsOf: NetworkPlugins.shared.values)
        extraEndpointClosures = NetworkPlugins.shared.extraEndpointClosures
        super.init(stubClosure: { target -> StubBehavior in
            guard let target = target.target as? RequestMockable else {
                return .never
            }
            return target.stubBehavior
        }, session: {
            let configuration = URLSessionConfiguration.default
            configuration.headers = .default
            configuration.httpShouldSetCookies = true
            return Session(configuration: configuration, startRequestsImmediately: false)
        }(), plugins: plugins)
    }
}

private class TimeoutPlugin: PluginType {
    func prepare(_ request: URLRequest, target _: TargetType) -> URLRequest {
        var request = request
        request.timeoutInterval = timeoutInterval
        return request
    }
}

public typealias AppendingClosure = (TargetType) -> NetworkMap?
public class AppendentParametersPlugin: PluginType {
    private let appendingClosure: AppendingClosure?
    public init(_ appendingClosure: AppendingClosure? = nil) {
        self.appendingClosure = appendingClosure
    }
    
    func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += URLEncoding.queryString.queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var target = target
        if let multiTarget = target as? MultiTarget {
            target = multiTarget.target
        }
        let appendentParametersType = target as? AppendentParametersType
        var parameters: NetworkMap
        let mode = appendentParametersType?.appendentParametersMode ?? .merge
        switch mode {
        case .merge:
            parameters = appendingClosure?(target) ?? [:]
            if let targetParameters = appendentParametersType?.appendentParameters {
                parameters.merge(targetParameters) {$1}
            }
        case .targetOnly:
            parameters = appendentParametersType?.appendentParameters ?? [:]
        }
        guard !parameters.isEmpty else {
            return request
        }
        guard let url = request.url else {
            return request
        }
        var request = request
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
            urlComponents.percentEncodedQuery = percentEncodedQuery
            request.url = urlComponents.url
        }
        return request
    }
}

public class DecryptionDataPlugin: PluginType {
    
    var decrypter: ((String, Data) throws -> Data)?
    public init(_ decrypter: ((String, Data) throws -> Data)?) {
        self.decrypter = decrypter
    }
    public func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        switch result {
        case .success(let response):
            guard !response.data.isEmpty, let encrypt = response.response?.headers["encrypt"], let decrypter = self.decrypter else {
                return result
            }
            do {
                let data = try decrypter(encrypt, response.data)
                return .success(Response(statusCode: response.statusCode, data: data, request: response.request, response: response.response))
            } catch let error {
                return .failure(MoyaError.underlying(error, response))
            }
        default:
            return result
        }
    }
}

public class CookiesPersistencePlugin: PluginType {
    public init() {}
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let url = request.url else {
            return request
        }
        guard let cookies = HTTPCookieStorage.shared.cookies(for: url), !cookies.isEmpty else {
            return request
        }
        var request = request
        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
        }
        return request
    }
}
