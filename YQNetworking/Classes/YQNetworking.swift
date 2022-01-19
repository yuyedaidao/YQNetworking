//
//  YQNetworking.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/2/25.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Alamofire
import Foundation
import Moya

public extension Notification.Name { // TODO: 这个的保留还是有一点耦合性，以后优化，完全可以去掉
    static let needLogin: Self = Notification.Name("com.yq.networking.needLogin")
}

public typealias NetworkMap = [String: Any]
public typealias NetworkArray = [NetworkMap]

public typealias NetworkSuccess = (Any?) -> Void
public typealias NetworkSuccessMap = (NetworkMap) -> Void
public typealias NetworkSuccessArray = (NetworkArray) -> Void
public typealias NetworkFailure = (Error) -> Void

public protocol NetworkProviderType {
    static var provider: NetworkProvider {get}
}

extension NetworkProviderType {
    public static var provider: NetworkProvider {
        NetworkProvider.shared
    }
}

public protocol RequestTarget: TargetType & ResponseValidatable & ResponseDecodable & RequestMockable & NetworkProviderType {}

public extension DispatchQueue {
    static let yqNetworking = DispatchQueue(label: "YQNetworkingCallBack")
}

public extension RequestTarget {
    
    /// 执行额外的终点闭包 对请求数据无影响
    private func performExtraEndpointClousersSuccess(_ traget: RequestTarget, response: Response, value: Any?) {
        for closure in Self.provider.extraEndpointClosures {
            closure.success?(traget, response, value)
        }
    }
    
    /// 执行额外的终点闭包 对请求数据无影响
    private func performExtraEndpointClousersFailure(_ traget: RequestTarget, error: Error) {
        for closure in Self.provider.extraEndpointClosures {
            closure.failure?(traget, error)
        }
    }
    
    @discardableResult
    // swiftlint:disable cyclomatic_complexity
    func request(callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, cachedResult: NetworkSuccess? = nil, success: NetworkSuccess?, failure: NetworkFailure?, ignoreCancel: Bool = false) -> Cancellable {
        // swiftlint:enable cyclomatic_complexity
        if let cachedResult = cachedResult, let cacheable = self as? ResponseCacheable {
            if let data = cacheable.fetchData(), case let .success(_value) = validateResponse(Response(statusCode: 200, data: data), dataOnly: true), let value = _value.validValue {
                let queue = callbackQueue ?? DispatchQueue.main
                queue.async {
                    cachedResult(value)
                }
            }
        }
        return Self.provider.request(MultiTarget(self), callbackQueue: .yqNetworking, progress: progress, completion: { (_ result: Result<Moya.Response, MoyaError>) -> Void in
            let callbackQueue = callbackQueue ?? DispatchQueue.main
            callbackQueue.async {
                switch result {
                case let .success(response):
                    switch self.validateResponse(response, dataOnly: false) {
                    case .success(let value):
                        if let cacheable = self as? ResponseCacheable {
                            cacheable.storeData(response.data)
                        }
                        success?(value.validValue)
                        DispatchQueue.main.async {
                            performExtraEndpointClousersSuccess(self, response: response, value: value.originalValue)
                        }
                    case .failure(let error):
                        print(error)
                        if case let MoyaError.underlying(err, _) = error {
                            failure?(err.providerMap())
                            DispatchQueue.main.async {
                                performExtraEndpointClousersFailure(self, error: err)
                            }
                        } else {
                            failure?(error.providerMap())
                            DispatchQueue.main.async {
                                performExtraEndpointClousersFailure(self, error: error)
                            }
                        }
                    }
                case let .failure(error):
                    print(error)
                    if case let MoyaError.underlying(err, _) = error {
                        guard let afError = err.asAFError else {
                            failure?(err.providerMap())
                            DispatchQueue.main.async {
                                performExtraEndpointClousersFailure(self, error: err)
                            }
                            return
                        }
                        switch afError {
                        case .explicitlyCancelled:
                            guard !ignoreCancel else {
                                break
                            }
                            failure?(err.providerMap())
                            DispatchQueue.main.async {
                                performExtraEndpointClousersFailure(self, error: err)
                            }
                        case .sessionTaskFailed(let error):
                            failure?(error.providerMap())
                            DispatchQueue.main.async {
                                performExtraEndpointClousersFailure(self, error: error)
                            }
                        default:
                            failure?(err.providerMap())
                            DispatchQueue.main.async {
                                performExtraEndpointClousersFailure(self, error: err)
                            }
                        }
                    } else {
                        failure?(error.providerMap())
                        DispatchQueue.main.async {
                            performExtraEndpointClousersFailure(self, error: error)
                        }
                    }
                }

            }
        })
    }

    @discardableResult
    func request(callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, cachedResult: NetworkSuccessMap? = nil, successMap: NetworkSuccessMap?, failure: NetworkFailure?, ignoreCancel: Bool = false) -> Cancellable {
        let queue = callbackQueue ?? DispatchQueue.main
        return request(callbackQueue: .yqNetworking, progress: progress, cachedResult: cachedResult == nil ? nil : { result in
            queue.async {
                guard let json = result as? NetworkMap else {
                    return
                }
                cachedResult?(json)
            }
        }, success: { result in
            queue.async {
                guard let json = result as? NetworkMap else {
                    let error = NetworkError(.unexpected)
                    print(error)
                    failure?(error.providerMap())
                    return
                }
                successMap?(json)
            }
        }, failure: { error in
            queue.async {
                failure?(error.providerMap())
            }
        }, ignoreCancel: ignoreCancel)
    }

    @discardableResult
    func request(callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, cachedResult: NetworkSuccessArray? = nil, successArray: NetworkSuccessArray?, failure: NetworkFailure?, ignoreCancel: Bool = false) -> Cancellable {
        let queue = callbackQueue ?? DispatchQueue.main
        return request(callbackQueue: .yqNetworking, progress: progress, cachedResult: cachedResult == nil ? nil : { result in
            queue.async {
                guard let json = result as? NetworkArray else {
                    return
                }
                cachedResult?(json)
            }
        }, success: { result in
            guard let json = result as? NetworkArray else {
                let error = NetworkError(.unexpected)
                print(error)
                queue.async {
                    failure?(error.providerMap())
                }
                return
            }
            queue.async {
                successArray?(json)
            }
        }, failure: { error in
            queue.async {
                failure?(error.providerMap())
            }
        }, ignoreCancel: ignoreCancel)
    }

    @discardableResult
    func request<T: Decodable>(_: T.Type, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, cachedResult: ((T) -> Void)? = nil, success: ((T) -> Void)?, failure: NetworkFailure?, ignoreCancel: Bool = false) -> Cancellable {
        let queue = callbackQueue ?? DispatchQueue.main
        return request(callbackQueue: .yqNetworking, progress: progress, cachedResult: cachedResult == nil ? nil : { value in
            let queue = callbackQueue ?? DispatchQueue.main
            guard let value = value else {
                return
            }
            guard JSONSerialization.isValidJSONObject(value) else {
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                let result = try decoder.decode(T.self, from: data)
                queue.async {
                    cachedResult?(result)
                }
            } catch let error {
                print(error)
            }
            
        }, success: { value in
            guard let value = value else {
                let error = NetworkError("空数据")
                print(error)
                queue.async {
                    failure?(error.providerMap())
                }
                return
            }
            guard JSONSerialization.isValidJSONObject(value) else {
                queue.async {
                    failure?(NetworkError(.invalidableJSON).providerMap())
                }
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                let result = try decoder.decode(T.self, from: data)
                queue.async {
                    success?(result)
                }
            } catch {
                queue.async {
                    failure?(error.providerMap())
                }
            }
        }, failure: { error in
            print(error)
            queue.async {
                failure?(error.providerMap())
            }
        }, ignoreCancel: ignoreCancel)
    }
}

public extension RequestTarget {
    @discardableResult
    func request(success: NetworkSuccess?, failure: NetworkFailure?) -> Cancellable {
        request(callbackQueue: nil, progress: nil, cachedResult: nil, success: success, failure: failure)
    }

    @discardableResult
    func request(successMap: NetworkSuccessMap?, failure: NetworkFailure?) -> Cancellable {
        request(callbackQueue: nil, progress: nil, cachedResult: nil, successMap: successMap, failure: failure)
    }

    @discardableResult
    func request(successArray: NetworkSuccessArray?, failure: NetworkFailure?) -> Cancellable {
        request(callbackQueue: nil, progress: nil, cachedResult: nil, successArray: successArray, failure: failure)
    }

    @discardableResult
    func request<T: Decodable>(_ type: T.Type, success: ((T) -> Void)?, failure: NetworkFailure?) -> Cancellable {
        request(type, callbackQueue: nil, progress: nil, cachedResult: nil, success: success, failure: failure)
    }
}

extension MoyaError: CustomStringConvertible {
    public var description: String {
        return errorDescription ?? "未识别的MoyaError"
    }
}


extension Error {
    func providerMap() -> Error {
        return NetworkProvider.shared.failureMap(self)
    }
}

public extension Error {
    var asMoyaError: MoyaError? {
        self as? MoyaError
    }

    var asNetworkError: NetworkErrorCompatical? {
        self as? NetworkErrorCompatical
    }
}
