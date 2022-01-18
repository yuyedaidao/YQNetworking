//
//  RequestGlobalParameters.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/7/26.
//

import Foundation

public enum AppendentParametersMode {
    case merge
    case targetOnly
}
public protocol AppendentParametersType where Self: RequestTarget {
    var appendentParametersMode: AppendentParametersMode {get}
    var appendentParameters: NetworkMap? {get}
}

extension AppendentParametersType {
    public var appendentParametersMode: AppendentParametersMode {
        return .merge
    }
    public var appendentParameters: NetworkMap? {nil}
}
