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
    case model
}

extension Network: RequestTarget {
    var baseURL: URL {
        switch self {
        case .login:
            return URL(string: "http://iqilu.shandian8.com")!
        case .model:
            return URL(string: "https://api.apiopen.top")!
        }
        
    }

    var path: String {
        switch self {
        case .login:
            return "/login"
        case .model:
            return "/singlePoetry"
        }
    }

    var method: Moya.Method {
        switch self {
        case .login:
            return .post
        case .model:
            return .get
        }
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

    var decoder: JSONDecoder {
        return JSONDecoder()
    }
}
