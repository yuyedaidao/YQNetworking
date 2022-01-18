//
//  Networking.swift
//  YQNetworking_Example
//
//  Created by 王叶庆 on 2021/2/26.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Moya
import YQNetworking

enum Network {
    case login
}

extension Network: RequestTarget {
    var baseURL: URL {
        return URL(string: "http://iqilu.shandian8.com")!
    }

    var path: String {
        return "/login"
    }

    var method: Moya.Method {
        return .post
    }

    var sampleData: Data {
        return Data()
    }

    var headers: [String: String]? {
        return nil
    }

    var task: Task {
        return .requestPlain
    }

//    var stubBehavior: StubBehavior {
//        return .delayed(seconds: 5)
//    }

    func validateResponse(_ response: Response, dataOnly _: Bool) -> Result<Any?, MoyaError> {
        do {
            let response = try response.filter(statusCode: 200)
            guard let value = try response.mapJSON() as? NetworkMap else {
                let info = "解析数据失败"
                return .failure(MoyaError.underlying(NetworkError(info), response))
            }
            return .success(value)
        } catch {
            return .failure(MoyaError.underlying(error, response))
        }
    }
}
