//
//  TopLevel.swift
//  Treasure
//
//  Created by Kevin Weber on 11/6/17.
//  Copyright © 2018 Fishermen Labs. All rights reserved.
//

import Foundation
import Mapper

public struct Errors: TreasureMappable {
    
    let id: String?
    let links: JSONObject?
    let status: String?
    let code: String?
    let title: String?
    let detail: String?
    let source: JSONObject?
    let meta: JSONObject?
    
    public init(map: TreasureMapper) throws {
        id = try? map.from(Key.id)
        links = try? map.from(Key.links)
        status = try? map.from(Key.status)
        code = try? map.from(Key.code)
        title = try? map.from(Key.title)
        detail = try? map.from(Key.detail)
        source = try? map.from(Key.source)
        meta = try? map.from(Key.meta)
    }
}

public struct JSONAPI: TreasureMappable {
    
    let version: String?
    let meta: JSONObject?
    
    public init(map: TreasureMapper) throws {
        version = try? map.from(Key.version)
        meta = try? map.from(Key.meta)
    }
}
