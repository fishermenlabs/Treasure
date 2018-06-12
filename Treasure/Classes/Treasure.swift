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
    
    /// The shared data pool of resources for the current lifecycle
    public static var chest: JSONObject {
        var poolCopy: JSONObject!
        
        concurrentPoolQueue.sync {
            poolCopy = Treasure.privateDataPool
        }
        
        return poolCopy
    }
    
    /// Strictly validates the incoming json document for specification conformance on initialization when set to `true`
    public static var strictValidationOnInitialization = false
    
    /// Returns the objects under the 'meta' key according to the JSON API specification
    public var meta: JSONObject? {
        return document[Key.meta] as? JSONObject
    }
    
    /// Returns the objects under the 'errors' key according to the JSON API specification
    public var errors: [Errors]? {
        return try? Mapper(JSON: document).from(Key.errors)
    }
    
    /// Returns the objects under the 'jsonapi' key according to the JSON API specification
    public var jsonapi: JSONAPI? {
        return try? Mapper(JSON: document).from(Key.jsonapi)
    }
    
    /// Returns the links objects under the 'links' key according to the JSON API specification
    public var links: JSONObject? {
        return document[Key.links] as? JSONObject
    }
    
    /// Returns the links objects within the included object under the 'links' key according to the JSON API specification
    public var includedLinks: JSONObject? {
        guard let included = document[Key.included] as? JSONObject else { return nil }
        
        return included[Key.links] as? JSONObject
    }
    
    /// The full json object received on initialization
    internal let document: JSONObject
    
    internal static let concurrentPoolQueue = DispatchQueue(label: "com.treasure.poolQueue", attributes: .concurrent)
    
    internal static var privateDataPool = JSONObject()
    
    /// Initialize a Treasure object with a json dictionary
    public init?(json: JSONObject) {
        self.document = json
        
        guard validateDocumentIfNeeded(json: self.document) else { return nil }
        
        poolData()
    }
    
    /// Initialize a Treasure object with a json dictionary
    public init?(json: NSDictionary) {
        self.document = json as! JSONObject
        
        guard validateDocumentIfNeeded(json: self.document) else { return nil }
        
        poolData()
    }
    
    /// Maps the json document initialized with Treasure and adds the data to the chest
    public func map<T: Resource>() -> T? {
        return try? Mapper(JSON: document).from(Key.data)
    }
    
    /// Maps the json document initialized with Treasure and adds the data to the chest
    public func map<T: Resource>() -> [T]? {
        return try? Mapper(JSON: document).from(Key.data)
    }
    
    /// Maps the provided json and then removes the data from the chest
    public static func map<T: Resource>(json: JSONObject) -> T? {
        let resource: T? = Treasure(json: json)?.map()

        removeResourceFromChest(resource)
        
        return resource
    }
    
    /// Maps the provided json and then removes the data from the chest
    public static func map<T: Resource>(json: JSONObject) -> [T]? {
        let resource: [T]? = Treasure(json: json)?.map()
        
        removeResourcesFromChest(resource)
        
        return resource
    }
    
    /// Maps the provided json and then removes the data from the chest
    public static func map<T: Resource>(json: NSDictionary) -> T? {
        let resource: T? = Treasure(json: json)?.map()
        
        removeResourceFromChest(resource)
        
        return resource
    }
    
    /// Maps the provided json and then removes the data from the chest
    public static func map<T: Resource>(json: NSDictionary) -> [T]? {
        let resource: [T]? = Treasure(json: json)?.map()
        
        removeResourcesFromChest(resource)
        
        return resource
    }
    
    /// Remove all json data from the chest
    public static func clearChest() {
        concurrentPoolQueue.async(flags: .barrier) {
            privateDataPool.removeAll()
        }
    }
    
    /// Returns the json chest as Data
    public static func chestData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: Treasure.chest)
    }
    
    /// Stores the provided Data into the chest as json
    public static func store(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data), let jsonObject = json as? NSDictionary else { return }
        for array in jsonObject.allValues {
            guard let array = array as? [JSONObject] else { continue }
            
            pool(array)
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
        return try resourceFor(relationshipData: RelationshipData(type: type, id: id))
    }
    
    /// Retrieves a Resource from the chest for the given ToOneRelationship
    public static func resourceFor<T: Resource>(relationship: ToOneRelationship?) throws -> T {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        return try resourceFor(relationshipData: relationship!.data!)
    }
    
    /// Retrieves a Resource from the chest for the given ToManyRelationship
    public static func resourceFor<T: Resource>(relationship: ToManyRelationship?) throws -> [T] {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try relationship!.data!.map({ (data) -> T in
            try resourceFor(relationshipData: data)
        })
    }
    
    /// Removes the given Resource from the chest
    public static func removeResourceFromChest(_ resource: Resource?) {
        guard let resource = resource else { return }
        concurrentPoolQueue.async(flags: .barrier) {
            
            guard var typePool = privateDataPool[resource.type] as? [JSONObject],
                let index = typePool.index(where: { (json) -> Bool in
                    guard let jsonId = json[Key.id] as? String else { return false }
                    return jsonId == resource.id
                }) else { return }
            
            if typePool.count == 1 {
                privateDataPool.removeValue(forKey: resource.type)
            } else {
                typePool.remove(at: index)
                privateDataPool[resource.type] = typePool
            }
        }
    }
    
    /// Removes the given Resources from the chest
    public static func removeResourcesFromChest(_ resources: [Resource]?) {
        guard let resources = resources else { return }
        
        for res in resources {
            removeResourceFromChest(res)
        }
    }
}
