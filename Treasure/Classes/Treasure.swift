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
    public static let collection = "collection"
    public static let href = "href"
    public static let related = "related"
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
    
    /// The shared data pool of resources for the current lifecycle
    public static var chest: JSONObject {
        return Treasure.privateDataPool
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
    
    public static func clearChest() {
        Treasure.privateDataPool.removeAll()
    }
    
    public static func chestData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: Treasure.privateDataPool)
    }
    
    public static func store(_ data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data), let jsonObject = json as? NSDictionary {
            for array in jsonObject.allValues {
                if let array = array as? [JSONObject] {
                    Treasure.pool(array)
                }
            }
        }
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
    
    /// Retrieves a Resource from the chest for the given type and id
    public static func resourceFor<T: Resource>(type: String, id: String) throws -> T {
        return try Treasure.resourceFor(relationshipData: RelationshipData(type: type, id: id))
    }
    
    /// Retrieves a Resource from the chest for the given ToOneRelationship
    public static func resourceFor<T: Resource>(relationship: ToOneRelationship?) throws -> T {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        return try Treasure.resourceFor(relationshipData: relationship!.data!)
    }
    
    /// Retrieves a Resource from the chest for the given ToManyRelationship
    public static func resourceFor<T: Resource>(relationship: ToManyRelationship?) throws -> [T] {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try relationship!.data!.map({ (data) -> T in
            try Treasure.resourceFor(relationshipData: data)
        })
    }
    
    //MARK: Private
    
    private static var privateDataPool = JSONObject()
    
    private func initialize() {
        poolData()
    }
    
    private func poolData() {
        
        //Pool top-level data
        if let data = json[Key.data] as? JSONObject {
            Treasure.pool([data])
        } else if let data = json[Key.data] as? [JSONObject] {
            Treasure.pool(data)
        }
        
        //Pool included data
        if let includedData = json[Key.included] as? [JSONObject] {
            Treasure.pool(includedData)
        }
    }
    
    /// Adds the resources in data to the pool if needed
    private static func pool(_ json: [JSONObject]) {
        
        for data in json {
            if let type = data[Key.type] as? String {
                if let typePool = Treasure.privateDataPool[type] as? [JSONObject] {
                    
                    if let index = typePool.index(where: { (typeData) -> Bool in
                        if let lhs = typeData[Key.id] as? String, let rhs = data[Key.id] as? String {
                            return lhs == rhs
                        }
                        return false
                    }) {
                        var currentPool = typePool
                        let newData = Treasure.replace(currentPool.remove(at: index), with: data)
                        currentPool.insert(newData, at: index)
                        Treasure.privateDataPool[type] = currentPool
                    } else {
                        var currentPool = typePool
                        currentPool.append(data)
                        Treasure.privateDataPool[type] = currentPool
                    }
                    
                } else {
                    Treasure.privateDataPool[type] = [data] 
                }
            }
        }
    }

    /// Replaces values in the current object in the pool with the new object's values
    private static func replace(_ oldObject: JSONObject, with newObject: JSONObject) -> JSONObject {
        
        guard oldObject != newObject else { return newObject }
    
        let withAttributes = Treasure.replaceValuesIn(oldObject, with: newObject, for: Key.attributes())
        return Treasure.replaceValuesIn(withAttributes, with: newObject, for: Key.relationships())
    }
    
    private static func replaceValuesIn(_ oldObject: JSONObject, with newObject: JSONObject, for key: String) -> JSONObject {
        
        if let oldValues = oldObject[key] as? JSONObject {
            
            if let newValues = newObject[key] as? JSONObject {
                
                guard oldValues != newValues else {
                    return newObject
                }
                
                var oldMutable = oldObject
                var oldMutableValues = oldValues
                
                for key in (newValues as NSDictionary).allKeys {
                    let key = key as! String
                    oldMutableValues[key] = newValues[key]
                }
                
                oldMutable[key] = oldMutableValues
                
                return oldMutable
            } else {
                return oldObject
            }
        } else if let newValues = newObject[key] as? JSONObject {
            
            var oldMutable = oldObject
            
            oldMutable[key] = newValues
            return oldMutable
        }
        
        return oldObject
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
    
    /// Finds, if possible, the data resource for the given relationship type and id
    private static func resourceFor<T: Mappable>(relationshipData: RelationshipData) throws -> T {
        
        let error = MapperError.customError(field: Key.included, message: "Included data does not exist in pool")
        
        if let typePool = Treasure.chest[relationshipData.type] as? [JSONObject] {
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

fileprivate func != <Key, Value>(left: [Key: Value], right: [Key: Value]) -> Bool {
    return !NSDictionary(dictionary: left).isEqual(to: right)
}
