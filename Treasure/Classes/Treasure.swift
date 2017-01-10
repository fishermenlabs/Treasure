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
    
    //Keep an update pool of included resources
    private static var includedDataPool = [String: Any]()
    
    public static var dataPool: NSDictionary {
        return Treasure.includedDataPool as NSDictionary
    }
    
    private let json: NSDictionary
    
    public var meta: NSDictionary? {
        return json[Key.meta] as? NSDictionary
    }
    
    public var errors: NSDictionary? {
        return json[Key.errors] as? NSDictionary
    }
    
    public var jsonapi: NSDictionary? {
        return json[Key.jsonapi] as? NSDictionary
    }
    
    public var links: NSDictionary? {
        return json[Key.links] as? NSDictionary
    }
    
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
    
    private func pool(_ data: [[String: Any]]) {
        for data in data {
            if let type = data[Key.type] as? String {
                if let typePool = Treasure.includedDataPool[type] as? [[String: Any]] {
                    if typePool.filter({ (typeData) -> Bool in
                        if let lhs = typeData[Key.id] as? String, let rhs = data[Key.id] as? String {
                            return lhs == rhs
                        }
                        return false
                    }).isEmpty {
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

extension Mapper {
    
    public func fromRelationship<T: Resource>(_ relationship: ToOneRelationship?) throws -> T {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try includedDataFor(relationshipData: relationship!.data!)
    }
    
    public func fromRelationship<T: Resource>(_ relationship: ToManyRelationship?) throws -> [T] {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try relationship!.data!.map({ (data) -> T in
            try includedDataFor(relationshipData: data)
        })
    }
    
    private func includedDataFor<T: Mappable>(relationshipData: RelationshipData) throws -> T {
        
        let error = MapperError.customError(field: Key.included, message: "Included data does not exist in pool")
        
        if let typePool = Treasure.dataPool[relationshipData.type] as? [NSDictionary] {
            let data = typePool.filter({ (json) -> Bool in
                if let jsonId = json[Key.id] as? String, jsonId == relationshipData.id {
                    return true
                }
                
                return false
            })
            
            guard data.first != nil else {
                throw error
            }
            
            return try Mapper(JSON: data.first!).from("")
        }
        
        throw error
    }
}

struct Key {
    
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

func ==(lhs: Resource, rhs: Resource) -> Bool {
    return lhs.type == rhs.type && lhs.id == rhs.id
}

public protocol Resource: Mappable {
    
    var id: String {get}
    var type: String {get}
}

private protocol Relationship: Mappable {
    
    var links: NSDictionary? {get}
}

public struct RelationshipData: Resource {
    
    public let type: String
    public let id: String
    
    public init(map: Mapper) throws {
        type = try map.from(Key.type)
        id = try map.from(Key.id)
    }
}

public struct ToOneRelationship: Relationship {
    
    public let data: RelationshipData?
    public var links: NSDictionary?
    
    public init(map: Mapper) throws {
        data = try? map.from(Key.data)
        links = try? map.from(Key.links)
    }
}

public struct ToManyRelationship: Relationship {
    
    let data: [RelationshipData]?
    public var links: NSDictionary?
    
    public init(map: Mapper) throws {
        data = try? map.from(Key.data)
        links = try? map.from(Key.links)
    }
}
