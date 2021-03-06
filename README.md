# Treasure

Treasure is a small set of tools on top of Lyft's [Mapper](https://github.com/lyft/mapper) library to map objects according to the [JSON API](http://jsonapi.org) specification. If you're not using the JSON API specification, then only using Mapper should be sufficient.

## Installation

#### With [CocoaPods](http://cocoapods.org/)

```ruby
use_frameworks!

pod "Treasure"
```

## Usage

Treasure hinges on [Mapper](https://github.com/lyft/mapper). If you're not familiar with it, then go read up on it first.

Objects must conform to the `Resource` protocol, which conforms to Mapper's `Mappable` protocol.

`Key` provides convenient constants and functions to construct String keys for Mapper.

Relationships are represented by either a `ToOneRelationship` or a `ToManyRelationship`.

Relationships can be used to map included resources, which are placed into a shared data pool as received by Treasure. 

Included resources are not cached, so the data pool will only exist for the current lifecycle.

If you set `Treasure.strictValidationOnInitialization` to `true`, incoming resources will be validated, and the initializer will return `nil` if invalid. Validation errors will be thrown as a `DocumentValidationError` and an error message printed to console. If `false`, errors will still be thrown but the resource map may still succeed. `Treasure.strictValidationOnInitialization` is by default set to `false`.

```swift
import Treasure

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
```

You can then map to your object by instantiating a new Treasure with your received JSON.

```swift
if let json = json as? [String: Any] {
    let projects: [Project]? = Treasure(json: json)?.map()
}
```

Other top-level JSON API objects can be accessed through your Treasure instance.

```swift
if let json = json as? [String: Any] {

    let treasure = Treasure(json: json)
    let projects: [Project]? = treasure?.map()

    guard projects != nil else {
        print(treasure!.errors)
    }
}
```

If you'd like to map resources without adding data to the pool, you can use the static version of the  `map` function instead. This is just a convenience wrapper that removes the provided json from the chest before returning the resource. Using this function will not let you access other top-level JSON API objects, as it does not return a `Treasure` object.

```swift
if let json = json as? [String: Any] {
    let projects: [Project]? = Treasure.map(json: json)
}
```

You can build JSON API resources for update or creation via the `jsonForResourceUpdateWith` and `jsonForResourceWith` static functions.

These functions validate the built resource and will `assert(false)` if invalid. If you use the below process to create your JSON, the built resource should be valid.

```swift
let toOneRelationship = ToOneRelationship.jsonWith(key: "users", data: RelationshipData(type: "users", id: "4"))

let newProject = Treasure.jsonForResourceWith(type: "projects", attributes: ["title": "Test Project"], relationship: toOneRelationship)
```

The above call will build the following resource, which you can POST to your backend service for creation.

```json
"data": {
    "type": "projects",
    "attributes": {
        "title": "Test Project"
    },
    "relationships": {
        "users": {
            "data": {
                "type": "users",
                "id": "4"
            }
        }
    }
}
```

If you would like to persist the data pool, you can retrieve it as `Data` by using `Treasure.chestData()`, and store it back using `Treasure.store(data: Data)`

## License

Treasure is available under the MIT license. See the LICENSE file for more info.

Lyft's Mapper is available under the Apache 2.0 License
