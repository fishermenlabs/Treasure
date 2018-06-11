//
//  Resource.swift
//  Treasure
//
//  Created by Kevin Weber on 12/21/16.
//  Copyright © 2018 Fishermen Labs. All rights reserved.
//

import Foundation
import Mapper

public func ==(lhs: Resource, rhs: Resource) -> Bool {
    return lhs.type == rhs.type && lhs.id == rhs.id
}

public protocol Resource: TreasureMappable {
    
    var id: String {get}
    var type: String {get}
    
    /// Define how your custom object is created from a TreasureMapper object
    init(map: TreasureMapper) throws
}
