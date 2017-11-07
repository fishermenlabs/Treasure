//
//  TopLevel.swift
//  ModelMapper
//
//  Created by Kevin Weber on 11/6/17.
//

import Foundation
import Mapper

public struct Errors: Mappable {
    
    let id: String?
    let links: JSONObject?
    let status: String?
    let code: String?
    let title: String?
    let detail: String?
    let source: JSONObject?
    let meta: JSONObject?
    
    public init(map: Mapper) throws {
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

public struct JSONAPI: Mappable {
    
    let version: String?
    let meta: JSONObject?
    
    public init(map: Mapper) throws {
        version = try? map.from("version")
        meta = try? map.from(Key.meta)
    }
}

