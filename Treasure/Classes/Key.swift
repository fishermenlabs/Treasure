//
//  Key.swift
//  Treasure
//
//  Created by Kevin Weber on 11/6/17.
//  Copyright © 2018 Fishermen Labs. All rights reserved.
//

import Foundation

public struct Key {
    
    public static let id = "id"
    public static let type = "type"
    public static let data = "data"
    public static let links = "links"
    public static let included = "included"
    public static let meta = "meta"
    public static let errors = "errors"
    public static let jsonapi = "jsonapi"
    public static let first = "first"
    public static let last = "last"
    public static let prev = "prev"
    public static let next = "next"
    public static let page = "page"
    public static let self_ = "self"
    public static let collection = "collection"
    public static let href = "href"
    public static let related = "related"
    public static let relationship = "relationship"
    
    public static func attributes(_ key: String? = nil) -> String {
        guard key?.isEmpty == false else {
            return "attributes"
        }
        
        return "attributes.\(key!)"
    }
    
    public static func relationships(_ key: String? = nil) -> String {
        guard key?.isEmpty == false else {
            return "relationships"
        }
        
        return "relationships.\(key!)"
    }
}
