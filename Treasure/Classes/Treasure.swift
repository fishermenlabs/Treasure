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

fileprivate func != <Key, Value>(left: [Key: Value], right: [Key: Value]) -> Bool {
    return !NSDictionary(dictionary: left).isEqual(to: right)
}

public struct Treasure {
    
    /// The shared data pool of resources for the current lifecycle
    public static var chest: JSONObject {
        var poolCopy: JSONObject!
        
        Treasure.concurrentPoolQueue.sync {
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
    
    private static var privateDataPool = JSONObject()
    
    private static let concurrentPoolQueue = DispatchQueue(label: "com.treasure.poolQueue", attributes: .concurrent)
    
    public init?(json: JSONObject) {
        self.document = json
        
        guard validateDocumentIfNeeded(json: self.document) else { return nil }
        
        poolData()
    }
    
    public init?(json: NSDictionary) {
        self.document = json as! JSONObject
        
        guard validateDocumentIfNeeded(json: self.document) else { return nil }
        
        poolData()
    }
    
    /// Maps the json document initialized with Treasure and adds the data to the chest
    public func map<T: Resource>() -> T? {
        return try? Mapper(JSON: document).from(Key.data)
    }
    
    public func map<T: Resource>() -> [T]? {
        return try? Mapper(JSON: document).from(Key.data)
    }
    
    /// Maps the provided json and then removes the data from the chest
    public static func map<T: Resource>(json: JSONObject) -> T? {
        let resource: T? = Treasure(json: json)?.map()

        Treasure.removeResourceFromChest(resource)
        
        return resource
    }
    
    public static func map<T: Resource>(json: JSONObject) -> [T]? {
        let resource: [T]? = Treasure(json: json)?.map()
        
        Treasure.removeResourcesFromChest(resource)
        
        return resource
    }
    
    public static func map<T: Resource>(json: NSDictionary) -> T? {
        let resource: T? = Treasure(json: json)?.map()
        
        Treasure.removeResourceFromChest(resource)
        
        return resource
    }
    
    public static func map<T: Resource>(json: NSDictionary) -> [T]? {
        let resource: [T]? = Treasure(json: json)?.map()
        
        Treasure.removeResourcesFromChest(resource)
        
        return resource
    }
    
    public static func clearChest() {
        Treasure.concurrentPoolQueue.async(flags: .barrier) {
            Treasure.privateDataPool.removeAll()
        }
    }
    
    public static func chestData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: Treasure.chest)
    }
    
    public static func store(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data), let jsonObject = json as? NSDictionary else { return }
        for array in jsonObject.allValues {
            guard let array = array as? [JSONObject] else { continue }
            
            Treasure.pool(array)
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
    
    /// Removes the given Resource from the chest
    public static func removeResourceFromChest(_ resource: Resource?) {
        guard let resource = resource else { return }
        Treasure.concurrentPoolQueue.async(flags: .barrier) {
            
            guard var typePool = Treasure.privateDataPool[resource.type] as? [JSONObject],
                let index = typePool.index(where: { (json) -> Bool in
                    guard let jsonId = json[Key.id] as? String else { return false }
                    return jsonId == resource.id
                }) else { return }
            
            if typePool.count == 1 {
                Treasure.privateDataPool.removeValue(forKey: resource.type)
            } else {
                typePool.remove(at: index)
                Treasure.privateDataPool[resource.type] = typePool
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
    
    //MARK: Private
    
    private func validateDocumentIfNeeded(json: JSONObject) -> Bool {
        
        if Treasure.strictValidationOnInitialization {
            guard Treasure.validateDocument(self.document) else { return false }
        } else {
            let _ = Treasure.validateDocument(self.document)
        }
        
        return true
    }
    
    private func poolData() {
        //Pool top-level data
        if let data = document[Key.data] as? JSONObject {
            Treasure.pool([data])
        } else if let data = document[Key.data] as? [JSONObject] {
            Treasure.pool(data)
        }
            
        //Pool included data
        if let includedData = document[Key.included] as? [JSONObject] {
            Treasure.pool(includedData)
        }
    }
    
    /// Adds the resources in data to the pool if needed
    private static func pool(_ json: [JSONObject]) {
        
        Treasure.concurrentPoolQueue.async(flags: .barrier) {
            for data in json {
                guard let type = data[Key.type] as? String else { continue }
                
                guard let typePool = Treasure.privateDataPool[type] as? [JSONObject] else {
                    Treasure.privateDataPool[type] = [data]
                    continue
                }
                
                var currentPool = typePool
                        
                if let index = typePool.index(where: { (typeData) -> Bool in
                    if let lhs = typeData[Key.id] as? String, let rhs = data[Key.id] as? String {
                        return lhs == rhs
                    }
                    return false
                }) {
                    currentPool.insert(Treasure.replace(currentPool.remove(at: index), with: data), at: index)
                } else {
                    currentPool.append(data)
                }
                
                Treasure.privateDataPool[type] = currentPool
            }
        }
    }

    /// Replaces values in the current object in the pool with the new object's values
    private static func replace(_ oldObject: JSONObject, with newObject: JSONObject) -> JSONObject {
        
        return Treasure.replaceValuesIn(Treasure.replaceValuesIn(oldObject, with: newObject, for: Key.attributes()), with: newObject, for: Key.relationships())
    }
    
    private static func replaceValuesIn(_ oldObject: JSONObject, with newObject: JSONObject, for key: String) -> JSONObject {
        
        var oldMutable = oldObject
        oldMutable[key] = (newObject[key] as? JSONObject)?.merging((oldObject[key] as? JSONObject) ?? [:]) { (new, _) in new }
        return oldMutable
    }
    
    private static func jsonForResourceWith(type: String, id: String?, attributes: JSONObject?, relationship: JSONObject?) -> JSONObject {
        
        var data = Treasure.jsonForResourceDataWith(type: type, id: id, attributes: attributes)
        
        addRelationshipToResource(data: &data, relationship: relationship)
        
        let document = [Key.data: data]
        
        validateDocumentForPost(document)
        
        return document
    }
    
    private static func jsonForResourceWith(type: String, id: String?, attributes: JSONObject?, relationships: [JSONObject]?) -> JSONObject {
        
        var data = Treasure.jsonForResourceDataWith(type: type, id: id, attributes: attributes)
        
        addRelationshipsToResource(data: &data, relationships: relationships)
        
        let document = [Key.data: data]
        
        validateDocumentForPost(document)
        
        return document
    }
    
    private static func addRelationshipToResource(data: inout NSMutableDictionary, relationship: JSONObject?) {
        
        guard let relationship = relationship else { return }
        
        data[Key.relationships()] = relationship
    }
    
    private static func addRelationshipsToResource(data: inout NSMutableDictionary, relationships: [JSONObject]?) {
        
        guard let relationships = relationships else { return }
        
        let relationshipsObject = NSMutableDictionary()
        
        for relationship in relationships {
            relationshipsObject.addEntries(from: relationship)
        }
        
        data[Key.relationships()] = relationshipsObject
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
    private static func resourceFor<T: TreasureMappable>(relationshipData: RelationshipData) throws -> T {
        
        let error = MapperError.customError(field: Key.included, message: "Included data does not exist in Treasure chest")
        
        guard let typePool = Treasure.chest[relationshipData.type] as? [JSONObject] else { throw error }
        
        let data = typePool.filter({ (json) -> Bool in
            guard let jsonId = json[Key.id] as? String else { return false }
            return jsonId == relationshipData.id
        })
        
        guard let first = data.first else { throw error }
        
        return try Mapper(JSON: first).from("")
    }
}
