//
//  ResponseDecodable.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2022/1/19.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

public protocol ResponseDecodable {
    var decoder: JSONDecoder {get}
}

extension ResponseDecodable {
    public var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
