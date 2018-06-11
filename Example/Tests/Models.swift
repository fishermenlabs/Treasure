//
//  Models.swift
//  Treasure_Tests
//
//  Created by Kevin Weber on 11/6/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Treasure

struct User: Resource {
    
    let id: String
    let type: String
    let name: String
    let description: String
    
    init(map: TreasureMapper) throws {
        id = try map.from(Key.id)
        type = try map.from(Key.type)
        name = try map.from(Key.attributes("name"))
        description = try map.from(Key.attributes("description"))
    }
}

struct Project: Resource {
    
    let id: String
    let type: String
    let title: String
    let manager: User?
    
    init(map: TreasureMapper) throws {
        id = try map.from(Key.id)
        type = try map.from(Key.type)
        title = try map.from(Key.attributes("title"))
        
        let managerRelationship: ToOneRelationship? = try? map.from(Key.relationships("users"))
        manager = try? map.from(managerRelationship)
    }
}

struct TestJson {
    
    static let validDocumentWithRelationship: JSONObject = [
        "data": [
            "id": "1",
            "type": "projects",
            "attributes": [
                "title": "Test Project"
            ],
            "relationships": [
                "author": [
                    "links": [
                        "self": "/projects/1/relationships/author",
                        "related": "/projects/1/author"
                    ],
                    "data": [ "type": "people", "id": "9" ]
                ]
            ]
        ]
    ]
    
    static let validDocumentWithManyRelationships: JSONObject = [
        "data": [
            "id": "1",
            "type": "projects",
            "attributes": [
                "title": "Test ToMany"
            ],
            "relationships": [
                "users": [
                    "data": ["type": "users", "id": "4"]
                ],
                "points": [
                    "data": [["type": "points", "id": "1"], ["type": "points", "id": "2"]]
                ]
            ]
        ]
    ]
    
    static let validTopLevelJson: JSONObject = [
        "data": [
            "id": "2",
            "type": "projects",
            "attributes": [
                "title": "Test Project"
            ]
        ],
        "links": [
            "self": "http://example.com/projects"
        ],
        "meta": [
            "test": "tester"
        ]
    ]
    
    static let invalidTopLevelJson: JSONObject = [
        "data": [
            "id": "1",
            "type": "projects",
            "attributes": [
                "title": "Test Project"
            ]
        ],
        "errors": [
            "title": "There was an error."
        ],
        "meta": [
            "test": "tester"
        ]
    ]
    
    static let invalidTopLevelIncludedJson: JSONObject = [
        "meta": [
            "test": "tester"
        ],
        "included": [userJson]
    ]
    
    static let metaJson: JSONObject = [
        "meta": [
            "test": "tester"
        ]
    ]
    
    static let userJson: JSONObject = [
        "id": "4",
        "type": "users",
        "attributes": [
            "name": "Test User",
            "description": "The best test user ever"
        ]
    ]
    
    static let projectJson: JSONObject = [
        "data": [
            "id": "1",
            "type": "projects",
            "attributes": [
                "title": "Test Project"
            ],
            "relationships": [
                "users": [
                    "data": ["type": "users", "id": "4"]
                ]
            ]
        ],
        "included": [userJson]
    ]
    
    static let projectJsonUpdated: JSONObject = [
        "data": [
            "id": "1",
            "type": "projects",
            "attributes": [
                "title": "The Best Project"
            ],
            "relationships": [
                "users": [
                    "data": ["type": "users", "id": "10"]
                ]
            ]
        ]
    ]
    
    static let projectJsonManyRelationships: JSONObject = [
        "data": [
            "type": "projects",
            "attributes": [
                "title": "Test ToMany"
            ],
            "relationships": [
                "users": [
                    "data": ["type": "users", "id": "4"]
                ],
                "points": [
                    "data": [["type": "points", "id": "1"], ["type": "points", "id": "2"]]
                ]
            ]
        ]
    ]
    
    static func projectPointsJson(id: UUID) -> JSONObject {
        return ["data": [
            "type": "projects",
            "id": id.uuidString,
            "attributes": [
                "title": "Test ToMany"
            ],
            "relationships": [
                "points": [
                    "data": [["type": "points", "id": "1"], ["type": "points", "id": "2"]]
                ]
            ]
            ]
        ]
    }
}
