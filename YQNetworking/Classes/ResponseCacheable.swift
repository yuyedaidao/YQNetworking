//
//  ResponseCacheable.swift
//  YQNetworking
//
//  Created by 王叶庆 on 2021/3/12.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Cache
import Foundation

public protocol ResponseCacheable where Self: RequestTarget {
    var cacheable: Bool { get }
    var cacheKey: String { get }
    func storeData(_ data: Data)
    func fetchData() -> Data?
    func removeData()
}

public extension ResponseCacheable {
    static var storage: Storage<Data>? {
        let config = DiskConfig(name: "YQNetworking", expiry: .seconds(30 * 24 * 3600), maxSize: 50000, directory: nil, protectionType: .complete)
        do {
            return try Storage(diskConfig: config, memoryConfig: MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10), transformer: TransformerFactory.forData())
        } catch {
            log.error(error)
            return nil
        }
    }

    var cacheable: Bool {
        return false
    }

    var cacheKey: String {
        return baseURL.absoluteString + path
    }

    func storeData(_ data: Data) {
        do {
            try Self.storage?.setObject(data, forKey: cacheKey)
        } catch {
            log.error(error)
        }
    }

    func fetchData() -> Data? {
        do {
            return try Self.storage?.object(forKey: cacheKey)
        } catch {
            log.error(error)
            return nil
        }
    }

    func removeData() {
        try? Self.storage?.removeObject(forKey: cacheKey)
    }
}
