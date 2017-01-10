//
//  Resource.swift
//  Treasure
//
//  Created by Kevin Weber on 12/21/16.
//  Copyright © 2016 Fishermen Labs. All rights reserved.
//
//

import Foundation
import Mapper

public func ==(lhs: Resource, rhs: Resource) -> Bool {
    return lhs.type == rhs.type && lhs.id == rhs.id
}

public protocol Resource: Mappable {
    
    var id: String {get}
    var type: String {get}
}
