//
//  Treasure+Validation.swift
//  Treasure
//
//  Created by Kevin Weber on 6/6/18.
//

import Foundation

extension Treasure {
    
    enum DocumentValidationError: Error {
        case invalidTopLevel
        case invalidErrors
        case invalidLinks
        case invalidErrorSource
        case invalidResource
        case invalidRelationship
        case invalidRelationshipResourceLink
    }
    
    internal func validateDocument(_ json: JSONObject) throws {
        try validateTopLevel(json)
    }
    
    private func validateTopLevel(_ json: JSONObject) throws {
        let keys = json.keys
        
        if keys.contains(Key.data) && keys.contains(Key.errors) {
            throw DocumentValidationError.invalidTopLevel
        } else if keys.contains(Key.included) && !keys.contains(Key.data) {
            throw DocumentValidationError.invalidTopLevel
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
            throw DocumentValidationError.invalidErrors
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
                throw DocumentValidationError.invalidErrors
            }
        }
    }
    
    private func validateLinks(json: JSONObject, withAbout: Bool = false) throws {
        if withAbout {
            guard json.keys.contains(Key.about) else {
                throw DocumentValidationError.invalidLinks
            }
        }
        
        guard json.keys.contains(Key.self_) || json.keys.contains(Key.related) else {
            throw DocumentValidationError.invalidLinks
        }
    }
    
    private func validateSource(json: JSONObject) throws {
        guard json.keys.contains(Key.pointer) || json.keys.contains(Key.parameter) else {
            throw DocumentValidationError.invalidErrorSource
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
                throw DocumentValidationError.invalidResource
            }
            
            guard keys.contains(Key.attributes())
                || keys.contains(Key.relationships())
                || keys.contains(Key.links)
                || keys.contains(Key.meta) else {
                throw DocumentValidationError.invalidResource
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
                        throw DocumentValidationError.invalidRelationship
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
                throw DocumentValidationError.invalidRelationshipResourceLink
            }
        }
    }
}
