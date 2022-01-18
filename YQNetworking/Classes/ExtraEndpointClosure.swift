//
//  ExtraEndingPoint.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/10/14.
//

import Foundation
import Moya

public struct ExtraEndpointClosure {
    var success: ((RequestTarget, Response, Any?) -> ())?
    var failure: ((RequestTarget, Error) -> ())?
    public init(success: ((RequestTarget, Response, Any?) -> ())? = nil, failure: ((RequestTarget, Error) -> ())? = nil) {
        self.success = success
        self.failure = failure
    }
}
