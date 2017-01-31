//
//  Treasure.swift
//  Treasure
//
//  Created by Kevin Weber on 12/21/16.
//  Copyright © 2016 Fishermen Labs. All rights reserved.
//

import Foundation
import Mapper

public typealias JSONObject = [String: Any]

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
    
    public static func attributes(_ key: String? = nil) -> String {
        guard key?.isEmpty == false else {
            return "attributes"
        }
        
        return "attributes.\(key!)"
    }
    
    public static func relationships(_ key: String? = nil) -> String {
        guard key?.isEmpty == false else {
            return "relationships"
        }
        
        return "relationships.\(key!)"
    }
}

public struct Errors: Mappable {
    
    let id: String?
    let links: JSONObject?
    let status: String?
    let code: String?
    let title: String?
    let detail: String?
    let source: JSONObject?
    let meta: JSONObject?
    
    public init(map: Mapper) throws {
        id = try? map.from(Key.id)
        links = try? map.from(Key.links)
        status = try? map.from("status")
        code = try? map.from("code")
        title = try? map.from("title")
        detail = try? map.from("detail")
        source = try? map.from("source")
        meta = try? map.from(Key.meta)
    }
}

public struct JSONAPI: Mappable {
    
    let version: String?
    let meta: JSONObject?
    
    public init(map: Mapper) throws {
        version = try? map.from("version")
        meta = try? map.from(Key.meta)
    }
}

public struct Treasure {
    
    /// The shared data pool of included resources for the current lifecycle
    public static var dataPool: JSONObject {
        return Treasure.includedDataPool
    }
    
    /// The full json object received on initialization
    private let json: JSONObject
    
    /// Returns the objects under the 'meta' key according to the JSON API specification
    public var meta: JSONObject? {
        return json[Key.meta] as? JSONObject
    }
    
    /// Returns the objects under the 'errors' key according to the JSON API specification
    public var errors: [Errors]? {
        return try? Mapper(JSON: json).from(Key.errors)
    }
    
    /// Returns the objects under the 'jsonapi' key according to the JSON API specification
    public var jsonapi: JSONAPI? {
        return try? Mapper(JSON: json).from(Key.jsonapi)
    }
    
    /// Returns the links objects under the 'links' key according to the JSON API specification
    public var links: JSONObject? {
        return json[Key.links] as? JSONObject
    }
    
    /// Returns the links objects within the included object under the 'links' key according to the JSON API specification
    public var includedLinks: JSONObject? {
        if let included = json[Key.included] as? JSONObject {
            return included[Key.links] as? JSONObject
        }
        
        return nil
    }
    
    public init(json: JSONObject) {
        self.json = json
        
        initialize()
    }
    
    public init(json: NSDictionary) {
        self.json = json as! JSONObject
        
        initialize()
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
    
    /// Builds a new JSON API resource for updating attributes with an optional single Relationship
    public static func jsonForResourceUpdateWith(type: String, id: String, attributes: JSONObject, relationship: JSONObject? = nil) -> JSONObject {
        return jsonForResourceWith(type: type, id: id, attributes: attributes, relationship: relationship)
    }
    
    /// Builds a new JSON API resource for updating attributes with an optional multiple Relationships
    public static func jsonForResourceUpdateWith(type: String, id: String, attributes: JSONObject, relationships: [JSONObject]? = nil) -> JSONObject {
        return jsonForResourceWith(type: type, id: id, attributes: attributes, relationships: relationships)
    }
    
    /// Builds a new JSON API resource with a single Relationship
    public static func jsonForResourceWith(type: String, id: UUID? = nil, attributes: JSONObject? = nil, relationship: JSONObject? = nil) -> JSONObject {
        
        return jsonForResourceWith(type: type, id: id?.uuidString, attributes: attributes, relationship: relationship)
    }
    
    /// Builds a new JSON API resource with multiple Relationships
    public static func jsonForResourceWith(type: String, id: UUID? = nil, attributes: JSONObject? = nil, relationships: [JSONObject]? = nil) -> JSONObject {
        
        return jsonForResourceWith(type: type, id: id?.uuidString, attributes: attributes, relationships: relationships)
    }
    
    //MARK: Private
    
    private static var includedDataPool = JSONObject()
    
    private func initialize() {
        poolIncludedData()
    }
    
    private func poolIncludedData() {
        if let includedData = json[Key.included] as? [JSONObject] {
            pool(includedData)
        }
    }
    
    /// Adds the resources in data to the includedDataPool if needed
    private func pool(_ data: [JSONObject]) {
        for data in data {
            if let type = data[Key.type] as? String {
                if let typePool = Treasure.includedDataPool[type] as? [JSONObject] {
                    
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
    
    private static func jsonForResourceWith(type: String, id: String?, attributes: JSONObject?, relationship: JSONObject?) -> JSONObject {
        
        var data = Treasure.jsonForResourceDataWith(type: type, id: id, attributes: attributes)
        
        addRelationshipToResource(data: &data, relationship: relationship)
        
        return [Key.data: data]
    }
    
    private static func jsonForResourceWith(type: String, id: String?, attributes: JSONObject?, relationships: [JSONObject]?) -> JSONObject {
        
        var data = Treasure.jsonForResourceDataWith(type: type, id: id, attributes: attributes)
        
        addRelationshipsToResource(data: &data, relationships: relationships)
        
        return [Key.data: data]
    }
    
    private static func addRelationshipToResource(data: inout NSMutableDictionary, relationship: JSONObject?) {
        
        if let relationship = relationship {
            data[Key.relationships()] = relationship
        }
    }
    
    private static func addRelationshipsToResource(data: inout NSMutableDictionary, relationships: [JSONObject]?) {
        
        if let relationships = relationships {
            let relationshipsObject = NSMutableDictionary()
            for relationship in relationships {
                relationshipsObject.addEntries(from: relationship)
            }
            
            data[Key.relationships()] = relationshipsObject
        }
    }
    
    private static func jsonForResourceDataWith(type: String, id: String? = nil, attributes: JSONObject?) -> NSMutableDictionary {
        
        let data: NSMutableDictionary = [Key.type: type]
        
        if let id = id {
            data[Key.id] = id
        }
        
        if let attributes = attributes {
            data[Key.attributes()] = attributes
        }
        
        return data
    }
}
