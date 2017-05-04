import UIKit
import XCTest
import Treasure
import Mapper

fileprivate func == <K, V>(left: [K:V], right: [K:V]) -> Bool {
    return NSDictionary(dictionary: left).isEqual(to: right)
}

class Tests: XCTestCase {
    
    struct User: Resource {
        
        let id: String
        let type: String
        let name: String
        let description: String
        
        init(map: Mapper) throws {
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
        
        init(map: Mapper) throws {
            id = try map.from(Key.id)
            type = try map.from(Key.type)
            title = try map.from(Key.attributes("title"))
            
            let managerRelationship: ToOneRelationship? = try? map.from(Key.relationships("users"))
            manager = try? map.from(managerRelationship)
        }
    }
    
    struct TestJson {
        
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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        
        Treasure.clearChest()
        
        super.tearDown()
    }
    
    func testExample() {
        
        let testProject: Project? = Treasure(json: TestJson.projectJson).map()
        let testUser: User? = User.from(TestJson.userJson)
        
        if let manager = testProject?.manager, let user = testUser {
            XCTAssertTrue(manager == user)
        } else {
            XCTFail()
        }
    }
    
    func testCreateToOne() {
        
        let toOneRelationship = ToOneRelationship(data: RelationshipData(type: "users", id: "4")).jsonWith(key: "users")!
        
        let project = Treasure.jsonForResourceWith(type: "projects", attributes: ["title": "Test Project"], relationship: toOneRelationship)
        
        let testJson = [
            "data": [
                "type": "projects",
                "attributes": [
                    "title": "Test Project"
                ],
                "relationships": [
                    "users": [
                        "data": ["type": "users", "id": "4"]
                    ]
                ]
            ]
        ]
        
        XCTAssertTrue(project as NSDictionary == testJson as NSDictionary)
    }
    
    func testCreateToMany() {
        
        let pointsData1 = RelationshipData(type: "points", id: "1")
        let pointsData2 = RelationshipData(type: "points", id: "2")
        
        let toManyRelationship = ToManyRelationship.jsonWith(key: "points", data: [pointsData1, pointsData2])
        
        let uuid = UUID()
        
        let project = Treasure.jsonForResourceWith(type: "projects", id: uuid, attributes: ["title": "Test ToMany"], relationship: toManyRelationship)
        
        XCTAssertTrue(project as NSDictionary == TestJson.projectPointsJson(id: uuid) as NSDictionary)
    }
    
    func testCreateCombo() {
        
        let usersData = RelationshipData(type: "users", id: "4")
        let pointsData1 = RelationshipData(type: "points", id: "1")
        let pointsData2 = RelationshipData(type: "points", id: "2")
        
        let toOneRelationship = ToOneRelationship.jsonWith(key: "users", data: usersData)
        let toManyRelationship = ToManyRelationship(data: [pointsData1, pointsData2]).jsonWith(key: "points")!

        let project = Treasure.jsonForResourceWith(type: "projects", attributes: ["title": "Test ToMany"], relationships: [toOneRelationship, toManyRelationship])
        
        XCTAssertTrue(project as NSDictionary == TestJson.projectJsonManyRelationships as NSDictionary)
    }
    
    func testUpdate() {
        
        let _: Project? = Treasure(json: TestJson.projectJson).map()
        
        let toOneRelationship = ToOneRelationship(data: RelationshipData(type: "users", id: "10")).jsonWith(key: "users")!
        
        let project = Treasure.jsonForResourceUpdateWith(type: "projects", id: "1", attributes: ["title": "The Best Project"], relationship: toOneRelationship)
        
        XCTAssertTrue(project as NSDictionary == TestJson.projectJsonUpdated as NSDictionary)
    }
    
    func testReplace() {
        
        let userJson: JSONObject = [
            "id": "4",
            "type": "users",
            "attributes": [
                "name": "New Name"
            ],
            "relationships": [
                "projects": [
                    "data": ["type": "projects", "id": "1"]
                ]
            ]
        ]
        
        let testUserJson: JSONObject = [
            "id": "4",
            "type": "users",
            "attributes": [
                "name": "New Name",
                "description": "The best test user ever"
            ],
            "relationships": [
                "projects": [
                    "data": ["type": "projects", "id": "1"]
                ]
            ]
        ]
        
        let json: JSONObject = [
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
        
        let _: Project? = Treasure(json: TestJson.projectJson).map()
        let _: Project? = Treasure(json: json).map()
        
        if let user = Treasure.chest["users"] as? [JSONObject] {
            XCTAssertTrue(user.first! == testUserJson)
        } else {
            XCTFail()
        }
    }
    
    func testStoreData() {
        
        let _: Project? = Treasure(json: TestJson.projectJson).map()
        let _: User? = Treasure(json: TestJson.userJson).map()
        
        let json = Treasure.chest
        if let data = Treasure.chestData() {
            
            Treasure.clearChest()
            
            Treasure.store(data)

            XCTAssertTrue(json == Treasure.chest)
        } else {
            XCTFail()
        }
    }
    
    func testResourceFromRelationship() {
        
        let project: Project? = Treasure(json: TestJson.projectJson).map()
        
        let relationship: ToOneRelationship = ToOneRelationship(data: RelationshipData(type: "users", id: "4"))
        
        let user: User? = try? Treasure.resourceFor(relationship: relationship)
        
        if let user = user, let manager = project?.manager {
            XCTAssert(manager == user)
        } else {
            XCTFail()
        }
    }
    
}
