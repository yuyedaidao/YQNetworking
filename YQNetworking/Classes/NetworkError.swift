//
//  NetworkError.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/2/25.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation

public struct HttpCode: RawRepresentable, Equatable {
    public typealias RawValue = Int
    public let rawValue: RawValue
    public init?(rawValue: Int) {
        self.rawValue = rawValue
    }
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

public protocol NetworkErrorCompatical: LocalizedError, CustomStringConvertible {}

public extension HttpCode {
    //  本地的错误
    static let unknown = HttpCode(9_998_765)
    static let unexpected = HttpCode(9_998_766) // 数据结构不符合预期
    static let invalidableJSON = HttpCode(9_998_767) // 不是合理的json数据
}

public struct NetworkError: NetworkErrorCompatical {
       
    public let code: HttpCode
    public let message: String?

    public init(_ message: String?) {
        self.message = message
        code = .unknown
    }

    public init(_ code: HttpCode = .unknown, message: String? = nil) {
        self.code = code
        self.message = message
    }
}

extension NetworkError {
    public var errorDescription: String? {
        var info: String?
        switch code {
        case .unexpected:
            info = message ?? "与预期的数据结构不符"
        case .invalidableJSON:
            info = message ?? "不合理的JSON数据"
        default:
            info = message ?? "未知错误"
        }
        return info
    }
    
    public var failureReason: String? {
        return "错误码: \(code.rawValue)"
    }

}

extension NetworkError {
    public var description: String {
        return errorDescription ?? "未识别的NetworkError"
    }
}

public struct CustomNetworkError: NetworkErrorCompatical {
    public let code: HttpCode
    public let message: String?

    public init(_ message: String?) {
        self.message = message
        code = .unknown
    }

    public init(_ code: HttpCode = .unknown, message: String? = nil) {
        self.code = code
        self.message = message
    }
    
    public var errorDescription: String? {
        return message
    }
    
    public var description: String {
        return errorDescription ?? "未识别的NetworkError"
    }
    public var failureReason: String? {
        return "错误码: \(code.rawValue)"
    }
}

