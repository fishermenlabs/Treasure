//
//  Helpers.swift
//  Treasure
//
//  Created by Kevin Weber on 6/11/18.
//

import Foundation
import Mapper

public typealias JSONObject = [String: Any]

internal func != <Key, Value>(left: [Key: Value], right: [Key: Value]) -> Bool {
    return !NSDictionary(dictionary: left).isEqual(to: right)
}

extension Treasure {
    
    // MARK: Internal
    
    internal func poolData() {
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
    internal static func pool(_ json: [JSONObject]) {
        
        concurrentPoolQueue.async(flags: .barrier) {
            for data in json {
                guard let type = data[Key.type] as? String else { continue }
                
                guard var typePool = privateDataPool[type] as? [JSONObject] else {
                    privateDataPool[type] = [data]
                    continue
                }
                
                if let index = typePool.index(where: { (typeData) -> Bool in
                    if let lhs = typeData[Key.id] as? String, let rhs = data[Key.id] as? String {
                        return lhs == rhs
                    }
                    return false
                }) {
                    typePool.insert(replace(typePool.remove(at: index), with: data), at: index)
                } else {
                    typePool.append(data)
                }
                
                privateDataPool[type] = typePool
            }
        }
    }
    
    /// Finds, if possible, the data resource for the given relationship type and id
    internal static func resourceFor<T: TreasureMappable>(relationshipData: RelationshipData) throws -> T {
        
        let error = MapperError.customError(field: Key.included, message: "Included data does not exist in Treasure chest")
        
        guard let typePool = chest[relationshipData.type] as? [JSONObject] else { throw error }
        
        let data = typePool.filter({ (json) -> Bool in
            guard let jsonId = json[Key.id] as? String else { return false }
            return jsonId == relationshipData.id
        })
        
        guard let first = data.first else { throw error }
        
        return try Mapper(JSON: first).from("")
    }
    
    internal static func jsonForResourceWith(type: String, id: String?, attributes: JSONObject?, relationship: JSONObject?) -> JSONObject {
        
        var data = jsonForResourceDataWith(type: type, id: id, attributes: attributes)
        
        addRelationshipToResource(data: &data, relationship: relationship)
        
        let document = [Key.data: data]
        
        validateDocumentForPost(document)
        
        return document
    }
    
    internal static func jsonForResourceWith(type: String, id: String?, attributes: JSONObject?, relationships: [JSONObject]?) -> JSONObject {
        
        var data = jsonForResourceDataWith(type: type, id: id, attributes: attributes)
        
        addRelationshipsToResource(data: &data, relationships: relationships)
        
        let document = [Key.data: data]
        
        validateDocumentForPost(document)
        
        return document
    }
    
    // MARK: Private
    
    /// Replaces values in the current object in the pool with the new object's values
    private static func replace(_ oldObject: JSONObject, with newObject: JSONObject) -> JSONObject {
        
        return replaceValuesIn(replaceValuesIn(oldObject, with: newObject, for: Key.attributes()), with: newObject, for: Key.relationships())
    }
    
    private static func replaceValuesIn(_ oldObject: JSONObject, with newObject: JSONObject, for key: String) -> JSONObject {
        
        var oldMutable = oldObject
        oldMutable[key] = (newObject[key] as? JSONObject)?.merging((oldObject[key] as? JSONObject) ?? [:]) { (new, _) in new }
        return oldMutable
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
}
