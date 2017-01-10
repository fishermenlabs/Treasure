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

private protocol Relationship: Mappable {
    
    var links: NSDictionary? {get}
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
    
    public let data: [RelationshipData]?
    public var links: NSDictionary?
    
    public init(map: Mapper) throws {
        data = try? map.from(Key.data)
        links = try? map.from(Key.links)
    }
}

public struct RelationshipData: Resource {
    
    public let type: String
    public let id: String
    
    public init(map: Mapper) throws {
        type = try map.from(Key.type)
        id = try map.from(Key.id)
    }
}
