//
//  Treasure+Validation.swift
//  Treasure
//
//  Created by Kevin Weber on 6/6/18.
//

import Foundation

extension Treasure {
    
    enum DocumentValidationError: Error {
        case invalidTopLevel(String)
        case invalidErrors(String)
        case invalidLinks(String)
        case invalidErrorSource(String)
        case invalidResource(String)
        case invalidRelationship(String)
        case invalidRelationshipResourceLink(String)
    }
    
    internal func validateDocument(_ json: JSONObject) -> Bool {
        do {
            try validateTopLevel(json)
        } catch {
            print("Treasure JSON API Document Validation Error: \(error)")
            return false
        }
        
        return true
    }
    
    private func validateTopLevel(_ json: JSONObject) throws {
        let keys = json.keys
        
        if keys.contains(Key.data) && keys.contains(Key.errors) {
            throw DocumentValidationError.invalidTopLevel("data and errors must not exist in the same document")
        } else if keys.contains(Key.included) && !keys.contains(Key.data) {
            throw DocumentValidationError.invalidTopLevel("included must not exist without data")
        } else if keys.contains(Key.meta)
            || keys.contains(Key.data)
            || keys.contains(Key.errors) {
            
            if let links = document[Key.links] as? JSONObject {
                try validateLinks(json: links)
            }
            
            if keys.contains(Key.errors) {
                try validateErrors(json)
            }
            
            if keys.contains(Key.data) {
                try validatePrimaryData(json)
            }
            
            if let included = document[Key.included] as? [JSONObject] {
                try validateResources(json: included)
            }
        }
    }
    
    private func validateErrors(_ json: JSONObject) throws {
        guard let errors = json[Key.errors] as? [JSONObject] else {
            throw DocumentValidationError.invalidErrors("errors is invalid")
        }
        
        for error in errors {
            let keys = error.keys
            
            if keys.contains(Key.id)
                || keys.contains(Key.links)
                || keys.contains(Key.status)
                || keys.contains(Key.code)
                || keys.contains(Key.title)
                || keys.contains(Key.detail)
                || keys.contains(Key.source)
                || keys.contains(Key.meta) {
                
                if let links = error[Key.links] as? JSONObject {
                    try validateLinks(json: links, withAbout: true)
                }
                
                if let source = error[Key.source] as? JSONObject {
                    try validateSource(json: source)
                }
                
            } else {
                throw DocumentValidationError.invalidErrors("errors may contain id, links, status, code, title, detail, source and or meta")
            }
        }
    }
    
    private func validateLinks(json: JSONObject, withAbout: Bool = false) throws {
        if withAbout {
            guard json.keys.contains(Key.about) else {
                throw DocumentValidationError.invalidLinks("links within errors must contain about")
            }
        }
        
        guard json.keys.contains(Key.self_) || json.keys.contains(Key.related) else {
            throw DocumentValidationError.invalidLinks("links may contain either self or related")
        }
    }
    
    private func validateSource(json: JSONObject) throws {
        guard json.keys.contains(Key.pointer) || json.keys.contains(Key.parameter) else {
            throw DocumentValidationError.invalidErrorSource("source may contain either pointer and or paramater")
        }
    }
    
    private func validatePrimaryData(_ document: JSONObject) throws {
        
        if let data = document[Key.data] as? JSONObject {
            try validateResources(json: [data])
        } else if let data = document[Key.data] as? [JSONObject] {
            try validateResources(json: data)
        }
    }
    
    private func validateResources(json: [JSONObject]) throws {
        for resource in json {
            let keys = resource.keys
            
            guard keys.contains(Key.id) && keys.contains(Key.type) else {
                throw DocumentValidationError.invalidResource("resouce must contain id and type")
            }
            
            guard keys.contains(Key.attributes())
                || keys.contains(Key.relationships())
                || keys.contains(Key.links)
                || keys.contains(Key.meta) else {
                throw DocumentValidationError.invalidResource("resource may contain either attributes, relationships, links, and or meta")
            }
            
            if let relationship = resource[Key.relationships()] as? JSONObject {
                try validateRelationships(json: [relationship])
            } else if let relationships = resource[Key.relationships()] as? [JSONObject] {
                try validateRelationships(json: relationships)
            }
            
            if let links = resource[Key.links] as? JSONObject {
                try validateLinks(json: links)
            }
        }
    }
    
    private func validateRelationships(json: [JSONObject]) throws {
        for relationship in json {
            let keys = relationship.keys

            for key in keys {
                
                guard let object = relationship[key] as? JSONObject,
                    object.keys.contains(Key.links)
                    || object.keys.contains(Key.data)
                    || object.keys.contains(Key.meta) else {
                        throw DocumentValidationError.invalidRelationship("relationship may contain either data, links, and or meta")
                }
                
                if let links = object[Key.links] as? JSONObject {
                    try validateLinks(json: links)
                }
                
                if let data = object[Key.data] as? JSONObject {
                    try validateResourceLinkage(json: [data])
                } else if let data = object[Key.data] as? [JSONObject] {
                    try validateResourceLinkage(json: data)
                }
            }
        }
    }
    
    private func validateResourceLinkage(json: [JSONObject]) throws {
        for resource in json {
            let keys = resource.keys

            guard keys.contains(Key.id) && keys.contains(Key.type) else {
                throw DocumentValidationError.invalidRelationshipResourceLink("relationship link must contain id and type")
            }
        }
    }
}
