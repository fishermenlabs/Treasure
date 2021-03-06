//
//  Mapper+Treasure.swift
//  Treasure
//
//  Created by Kevin Weber on 12/21/16.
//  Copyright © 2018 Fishermen Labs. All rights reserved.
//

import Foundation
import Mapper

public typealias TreasureMapper = Mapper

extension Dictionary: DefaultConvertible {}

public protocol TreasureMappable: Mappable {
    
    /// Define how your custom object is created from a TreasureMapper object
    init(map: TreasureMapper) throws
}

public extension Mappable {
    
    static func from(_ JSON: JSONObject) -> Self? {
        return try? self.init(map: Mapper(JSON: JSON))
    }
}

public extension Mapper {
    
    init(JSON: JSONObject) {
        self.init(JSON: JSON as NSDictionary)
    }
    
    /// Maps a ToOneRelationship based on the mapping provided by implementing the Resource protocol
    func from<T: Resource>(_ relationship: ToOneRelationship?) throws -> T {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try Treasure.resourceFor(relationship: relationship!)
    }
    
    /// Maps a ToManyRelationship based on the mapping provided by implementing the Resource protocol
    func from<T: Resource>(_ relationship: ToManyRelationship?) throws -> [T] {
        guard relationship?.data != nil else { throw MapperError.customError(field: Key.data, message: "Relationship data is nil") }
        
        return try Treasure.resourceFor(relationship: relationship!)
    }
}
