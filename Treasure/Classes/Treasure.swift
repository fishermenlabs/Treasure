//
//  Treasure.swift
//  Treasure
//
//  Created by Kevin Weber on 12/21/16.
//  Copyright © 2016 Fishermen Labs. All rights reserved.
//

import Foundation
import Mapper

struct Treasure {
    
    //Keep an update pool of included resources
    private static var includedDataPool = [String: Any]()
    
    static var dataPool: NSDictionary {
        return Treasure.includedDataPool as NSDictionary
    }
    
    private let json: NSDictionary
    
    var meta: NSDictionary? {
        return json[Key.meta] as? NSDictionary
    }
    
    var errors: NSDictionary? {
        return json[Key.errors] as? NSDictionary
    }
    
    var jsonapi: NSDictionary? {
        return json[Key.jsonapi] as? NSDictionary
    }
    
    var links: NSDictionary? {
        return json[Key.links] as? NSDictionary
    }
    
    var includedLinks: NSDictionary? {
        if let included = json[Key.included] as? NSDictionary {
            return included[Key.links] as? NSDictionary
        }
        
        return nil
    }
    
    init(json: [String: Any]) {
        self.json = json as NSDictionary
        
        if let includedData = json[Key.included] as? [[String: Any]] {
            pool(includedData)
        }
    }
    
    init(json: NSDictionary) {
        self.json = json
        
        if let includedData = json[Key.included] as? [[String: Any]] {
            pool(includedData)
        }
    }
    
    func map<T: Resource>() -> T? {
        return try? Mapper(JSON: json).from(Key.data)
    }
    
    func map<T: Resource>() -> [T]? {
        return try? Mapper(JSON: json).from(Key.data)
    }
    
    static func clearDataPool() {
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
    
    func fromRelationship<T: Resource>(_ relationship: ToOneRelationship?) throws -> T {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try includedDataFor(relationshipData: relationship!.data!)
    }
    
    func fromRelationship<T: Resource>(_ relationship: ToManyRelationship?) throws -> [T] {
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
    
    static let id = "id"
    static let type = "type"
    static let data = "data"
    static let links = "links"
    static let included = "included"
    static let meta = "meta"
    static let errors = "errors"
    static let jsonapi = "jsonapi"
    static let first = "first"
    static let last = "last"
    static let prev = "prev"
    static let next = "next"
    static let page = "page"
    static let self_ = "self"
    static let relationship = "relationship"
    
    static func attributes(_ key: String) -> String {
        return "attributes.\(key)"
    }
    
    static func relationships(_ key: String) -> String {
        return "relationships.\(key)"
    }
}

func ==(lhs: Resource, rhs: Resource) -> Bool {
    return lhs.type == rhs.type && lhs.id == rhs.id
}

protocol Resource: Mappable {
    
    var id: String {get}
    var type: String {get}
}

private protocol Relationship: Mappable {
    
    var links: NSDictionary? {get}
}

struct RelationshipData: Resource {
    
    let type: String
    let id: String
    
    init(map: Mapper) throws {
        type = try map.from(Key.type)
        id = try map.from(Key.id)
    }
}

struct ToOneRelationship: Relationship {
    
    let data: RelationshipData?
    var links: NSDictionary?
    
    init(map: Mapper) throws {
        data = try? map.from(Key.data)
        links = try? map.from(Key.links)
    }
}

struct ToManyRelationship: Relationship {
    
    let data: [RelationshipData]?
    var links: NSDictionary?
    
    init(map: Mapper) throws {
        data = try? map.from(Key.data)
        links = try? map.from(Key.links)
    }
}
