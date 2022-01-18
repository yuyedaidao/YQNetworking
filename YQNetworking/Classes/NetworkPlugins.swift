//
//  NetworkPlugins.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/7/27.
//

import Foundation
import Moya

public class NetworkPlugins {
    
    public static let shared = NetworkPlugins()
    private var _array: (() -> [PluginType])?
    private var _extraEndpointClosures: (() -> [ExtraEndpointClosure])?
    private init() {}
    
    public func setupOnce(_ plugins: (() -> [PluginType])?, extraEndpointClosures: (() -> [ExtraEndpointClosure])? = nil) {
        _array = plugins
        _extraEndpointClosures = extraEndpointClosures
    }
    
    lazy var values: [PluginType] = {
        _array?() ?? []
    }()
    
    lazy var extraEndpointClosures: [ExtraEndpointClosure] = {
        _extraEndpointClosures?() ?? []
    }()
}
