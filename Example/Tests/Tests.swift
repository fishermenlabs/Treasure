import UIKit
import XCTest
import Treasure
import Mapper

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        struct User: Resource {
            
            let id: String
            let type: String
            let name: String
            
            init(map: Mapper) throws {
                id = try map.from(Key.id)
                type = try map.from(Key.type)
                name = try map.from(Key.attributes("name"))
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
        
        let userJson: JSONObject = [
            "id": "4",
            "type": "users",
            "attributes": [
                "name": "Test User"
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
        
        let testProject: Project? = Treasure(json: json).map()
        let testUser: User? = User.from(userJson)
        
        if let manager = testProject?.manager, let user = testUser {
            XCTAssertTrue(manager == user)
        } else {
            XCTFail()
        }
    }
    
    func testCreateToOne() {
        
        let toOneRelationship = ToOneRelationship(data: RelationshipData(type: "users", id: "4")).jsonWith(key: "users")!
        
        let project = Treasure.jsonForResourceWith(type: "projects", attributes: ["title": "Test ToOne"], relationship: toOneRelationship)
        
        let json: JSONObject = [
            "data": [
                "type": "projects",
                "attributes": [
                    "title": "Test ToOne"
                ],
                "relationships": [
                    "users": [
                        "data": ["type": "users", "id": "4"]
                    ]
                ]
            ]
        ]
        
        XCTAssertTrue(project as NSDictionary == json as NSDictionary)
    }
    
    func testCreateToMany() {
        
        let pointsData1 = RelationshipData(type: "points", id: "1")
        let pointsData2 = RelationshipData(type: "points", id: "2")
        
        let toManyRelationship = ToManyRelationship.jsonWith(key: "points", data: [pointsData1, pointsData2])
        
        let uuid = UUID()
        
        let project = Treasure.jsonForResourceWith(type: "projects", id: uuid, attributes: ["title": "Test ToMany"], relationship: toManyRelationship)
        
        let json: JSONObject = [
            "data": [
                "type": "projects",
                "id": uuid.uuidString,
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
        
        XCTAssertTrue(project as NSDictionary == json as NSDictionary)
    }
    
    func testCreateCombo() {
        
        let usersData = RelationshipData(type: "users", id: "4")
        let pointsData1 = RelationshipData(type: "points", id: "1")
        let pointsData2 = RelationshipData(type: "points", id: "2")
        
        let toOneRelationship = ToOneRelationship.jsonWith(key: "users", data: usersData)
        let toManyRelationship = ToManyRelationship(data: [pointsData1, pointsData2]).jsonWith(key: "points")!

        let project = Treasure.jsonForResourceWith(type: "projects", attributes: ["title": "Test ToMany"], relationships: [toOneRelationship, toManyRelationship])
        
        let json: JSONObject = [
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
        
        XCTAssertTrue(project as NSDictionary == json as NSDictionary)
    }
    
    func testUpdate() {
        
        let toOneRelationship = ToOneRelationship(data: RelationshipData(type: "users", id: "10")).jsonWith(key: "users")!
        
        let project = Treasure.jsonForResourceUpdateWith(type: "projects", id: "1", attributes: ["title": "The Best Project"], relationship: toOneRelationship)
        
        let json: JSONObject = [
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
        
        XCTAssertTrue(project as NSDictionary == json as NSDictionary)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
