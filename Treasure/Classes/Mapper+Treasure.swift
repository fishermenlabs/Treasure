//
//  Mapper+Treasure.swift
//  Treasure
//
//  Created by Kevin Weber on 12/21/16.
//  Copyright © 2016 Fishermen Labs. All rights reserved.
//
//

import Foundation
import Mapper

public extension Mapper {
    
    /// Maps a ToOneRelationship based on the mapping provided by implementing the Resource protocol
    public func from<T: Resource>(relationship: ToOneRelationship?) throws -> T {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try includedDataFor(relationshipData: relationship!.data!)
    }
    
    /// Maps a ToManyRelationship based on the mapping provided by implementing the Resource protocol
    public func from<T: Resource>(relationship: ToManyRelationship?) throws -> [T] {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try relationship!.data!.map({ (data) -> T in
            try includedDataFor(relationshipData: data)
        })
    }
    
    /// Finds, if possible, the included data resource for the given relationship type and id
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