//
//  Relationship.swift
//  Treasure
//
//  Created by Kevin Weber on 12/21/16.
//  Copyright © 2016 Fishermen Labs. All rights reserved.
//
//

import Foundation
import Mapper

public protocol Relationship: Mappable {
    
    var links: JSONObject? {get}
}

public struct ToOneRelationship: Relationship {
    
    public let data: RelationshipData?
    public var links: JSONObject?
    
    public init(map: Mapper) throws {
        data = try? map.from(Key.data)
        links = try? map.from(Key.links)
    }
    
    public init(data: RelationshipData) {
        self.data = data
    }
    
    public func jsonWith(key: String) -> JSONObject? {
        
        guard data != nil else { return nil }
        
        return [key: [Key.data: data!.json]]
    }
    
    public static func jsonWith(key: String, data: RelationshipData) -> JSONObject {
        return [key: [Key.data: data.json]]
    }
}

public struct ToManyRelationship: Relationship {
    
    public let data: [RelationshipData]?
    public var links: JSONObject?
    
    public init(map: Mapper) throws {
        data = try? map.from(Key.data)
        links = try? map.from(Key.links)
    }
    
    public init(data: [RelationshipData]) {
        self.data = data
    }
    
    public func jsonWith(key: String) -> JSONObject? {
        
        guard data != nil else { return nil }

        return [key: [Key.data: data!.map { $0.json } ]]
    }
    
    public static func jsonWith(key: String, data: [RelationshipData]) -> JSONObject {
        return [key: [Key.data: data.map { $0.json } ]]
    }
}

public struct RelationshipData: Resource {
    
    public let type: String
    public let id: String
    
    public var json: JSONObject {
        return [Key.type: type, Key.id: id]
    }
    
    public init(map: Mapper) throws {
        type = try map.from(Key.type)
        id = try map.from(Key.id)
    }
    
    public init(type: String, id: String) {
        self.type = type
        self.id = id
    }
}
