//
//  Treasure.swift
//  Treasure
//
//  Created by Kevin Weber on 12/21/16.
//  Copyright © 2016 Fishermen Labs. All rights reserved.
//

import Foundation
import Mapper

public struct Treasure {
    
    /// The shared data pool of included resources for the current lifecycle
    private static var includedDataPool = [String: Any]()
    
    public static var dataPool: NSDictionary {
        return Treasure.includedDataPool as NSDictionary
    }
    
    /// The full json object received on instantiation
    private let json: NSDictionary
    
    /// Returns the objects under the 'meta' key according to the JSON API specification
    public var meta: NSDictionary? {
        return json[Key.meta] as? NSDictionary
    }
    
    /// Returns the objects under the 'errors' key according to the JSON API specification
    public var errors: NSDictionary? {
        return json[Key.errors] as? NSDictionary
    }
    
    /// Returns the objects under the 'jsonapi' key according to the JSON API specification
    public var jsonapi: NSDictionary? {
        return json[Key.jsonapi] as? NSDictionary
    }
    
    /// Returns the links objects under the 'links' key according to the JSON API specification
    public var links: NSDictionary? {
        return json[Key.links] as? NSDictionary
    }
    
    /// Returns the links objects within the included object under the 'links' key according to the JSON API specification
    public var includedLinks: NSDictionary? {
        if let included = json[Key.included] as? NSDictionary {
            return included[Key.links] as? NSDictionary
        }
        
        return nil
    }
    
    public init(json: [String: Any]) {
        self.json = json as NSDictionary
        
        if let includedData = json[Key.included] as? [[String: Any]] {
            pool(includedData)
        }
    }
    
    public init(json: NSDictionary) {
        self.json = json
        
        if let includedData = json[Key.included] as? [[String: Any]] {
            pool(includedData)
        }
    }
    
    public func map<T: Resource>() -> T? {
        return try? Mapper(JSON: json).from(Key.data)
    }
    
    public func map<T: Resource>() -> [T]? {
        return try? Mapper(JSON: json).from(Key.data)
    }
    
    public static func clearDataPool() {
        Treasure.includedDataPool.removeAll()
    }
    
    /// Adds the resources in data to the includedDataPool if needed
    private func pool(_ data: [[String: Any]]) {
        for data in data {
            if let type = data[Key.type] as? String {
                if let typePool = Treasure.includedDataPool[type] as? [[String: Any]] {
                    
                    if let index = typePool.index(where: { (typeData) -> Bool in
                        if let lhs = typeData[Key.id] as? String, let rhs = data[Key.id] as? String {
                            return lhs == rhs
                        }
                        return false
                    }) {
                        var currentPool = typePool
                        currentPool.remove(at: index)
                        currentPool.insert(data, at: index)
                    } else {
                        var currentPool = typePool
                        currentPool.append(data)
                        Treasure.includedDataPool[type] = currentPool
                    }
                
                } else {
                    Treasure.includedDataPool[type] = [data]
                }
            }
        }
    }
}

public struct Key {
    
    public static let id = "id"
    public static let type = "type"
    public static let data = "data"
    public static let links = "links"
    public static let included = "included"
    public static let meta = "meta"
    public static let errors = "errors"
    public static let jsonapi = "jsonapi"
    public static let first = "first"
    public static let last = "last"
    public static let prev = "prev"
    public static let next = "next"
    public static let page = "page"
    public static let self_ = "self"
    public static let relationship = "relationship"
    
    public static func attributes(_ key: String) -> String {
        return "attributes.\(key)"
    }
    
    public static func relationships(_ key: String) -> String {
        return "relationships.\(key)"
    }
}
