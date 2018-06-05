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
        status = try? map.from("status")
        code = try? map.from("code")
        title = try? map.from("title")
        detail = try? map.from("detail")
        source = try? map.from("source")
        meta = try? map.from(Key.meta)
    }
}

public struct JSONAPI: TreasureMappable {
    
    let version: String?
    let meta: JSONObject?
    
    public init(map: TreasureMapper) throws {
        version = try? map.from("version")
        meta = try? map.from(Key.meta)
    }
}

