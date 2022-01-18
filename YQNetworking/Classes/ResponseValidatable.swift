//
//  ResponseValidatable.swift
//  links
//
//  Created by 王叶庆 on 2020/8/3.
//

import Foundation
import Moya

public struct ValidationResponse {
    public let originalValue: Any?
    public let validValue: Any?
    public init(originalValue: Any?, validValue: Any?) {
        self.originalValue = originalValue
        self.validValue = validValue
    }
    public static let empty = ValidationResponse(originalValue: nil, validValue: nil)
}

public typealias ValidationResult = Result<ValidationResponse, MoyaError>
public protocol ResponseValidatable {
    /// 校验数据是否正确并返回相关数据
    /// - Parameters:
    ///   - response: Response
    ///   - dataOnly: 是否应该只校验response的data
    func validateResponse(_ response: Response, dataOnly: Bool) -> ValidationResult
}

public extension ResponseValidatable {
    func validateResponse(_ response: Response, dataOnly: Bool = false) -> ValidationResult {
        return Self.defaultValidateResponse(response, dataOnly: dataOnly)
    }

    static func defaultValidateResponse(_ response: Response, dataOnly: Bool = false) -> ValidationResult {
        do {
            let _response: Response
            if dataOnly {
                _response = response
            } else {
                _response = try response.filter(statusCode: 200)
            }
            guard let value = try _response.mapJSON() as? NetworkMap else {
                return .failure(MoyaError.underlying(NetworkError(.unexpected), response))
            }
            let code = value["code"] as? Int ?? NetworkError.Code.unknown.rawValue
            guard code == 1 else {
                let message = value["errmsg"] as? String ?? ""
                return .failure(MoyaError.underlying(NetworkError(NetworkError.Code(code), message: message.isEmpty ? nil : message), response))
            }
            let data = value["data"]
            return .success(ValidationResponse(originalValue: value, validValue: data))
        } catch {
            if let error = error as? MoyaError {
                return .failure(error)
            } else {
                return .failure(MoyaError.underlying(error, response))
            }
        }
    }

    static func simpleValidateResponse(_ response: Response, dataOnly: Bool = false) -> ValidationResult {
        do {
            let _response: Response
            if dataOnly {
                _response = response
            } else {
                _response = try response.filter(statusCode: 200)
            }
            let value = try _response.mapJSON()
            return .success(ValidationResponse(originalValue: value, validValue: value))
        } catch {
            return .failure(MoyaError.underlying(error, response))
        }
    }
}
