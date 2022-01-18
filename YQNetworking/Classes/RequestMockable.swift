//
//  RequestMockable.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/3/8.
//

import Foundation
import Moya

public protocol RequestMockable {
    var stubBehavior: StubBehavior { get }
}

public extension RequestMockable {
    var stubBehavior: StubBehavior {
        return .never
    }
}
