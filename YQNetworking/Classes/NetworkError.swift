//
//  NetworkError.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/2/25.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import XTToast

public extension NetworkError.Code {
    // 来自远方的错误
    static let fail = NetworkError.Code(0)
    static let noBindingPhone = NetworkError.Code(3)
    static let noLogin = NetworkError.Code(-1)
//    static let

    //  本地的错误
    static let unknown = NetworkError.Code(9_998_765)
    static let unexpected = NetworkError.Code(10096) // 数据结构不符合预期
    static let invalidableJSON = NetworkError.Code(10097) // 不是合理的json数据
}

public struct NetworkError: Error {
    public struct Code: RawRepresentable, Equatable {
        public typealias RawValue = Int
        public let rawValue: RawValue

        public init?(rawValue: Int) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public let code: Code
    let message: String?

    public init(_ message: String?) {
        self.message = message
        code = .unknown
    }

    public init(_ code: Code = .unknown, message: String? = nil) {
        self.code = code
        self.message = message
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        var info: String = ""
        switch code {
        case .noLogin:
            info = message ?? "请先登录"
        case .fail:
            info = message ?? "访问失败"
        case .noBindingPhone:
            info = message ?? "未绑定手机号"
        case .unexpected:
            info = message ?? "与预期的数据结构不符"
        case .invalidableJSON:
            info = message ?? "不合理的JSON数据"
        case .unknown:
            info = message ?? "未知错误"
        default:
            info = "错误码:\(code.rawValue) "
            if let message = message {
                info += message
            }
        }
        return info
    }
}

extension NetworkError: CustomStringConvertible {
    public var description: String {
        return errorDescription ?? "未识别的NetworkError"
    }
}

extension XTToast {
    
    /// 排除了noLogin的错误提示
    /// - Parameters:
    ///   - error: error
    ///   - hideAfterDelay: 消失时间
    public class func alert(_ error: Error? = nil, hideAfterDelay: Double = XTToastShowDuration) {
        if let error = error {
            guard !error.isNoLogin else {
                XTToast.hide()
                return
            }
            XTToast.error("\(error.localizedDescription)", hideAfterDelay: hideAfterDelay)
        } else {
            XTToast.error(hideAfterDelay: hideAfterDelay)
        }
    }
}
