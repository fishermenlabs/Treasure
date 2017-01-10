# Treasure

Treasure is a small set of tools on top of Lyft's [Mapper](https://github.com/lyft/mapper) library to convert objects according to the [JSON API](http://jsonapi.org) specification. If you're not using the JSON API specification, then only using Mapper should be sufficient.

The initial version of Treasure was built for the bare-minimum task of mapping relationships to included resources.  More strict conformance to the JSON API specification is on the TODO list.

## Installation

#### With [CocoaPods](http://cocoapods.org/)

```ruby
use_frameworks!

pod "Treasure"
```

## Usage

Treasure hinges on [Mapper](https://github.com/lyft/mapper). If you're not familiar with it, then go read up on it first.

Objects must conform to either the `Resource` protocol, which conforms to Mapper's `Mappable` protocol.
`Key` provides convenient constants and functions to construct String keys for Mapper.
Relationships are represented by either a `ToOneRelationship` or a `ToManyRelationship`.
Relationships can be used to map included resources, which are placed into a shared data pool as received by Treasure.  Included resources are not cached, so the data pool will only exist for the current lifecycle.


```swift
import Treasure
import Mapper

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
        manager = try? map.fromRelationship(managerRelationship)
    }
}
```

You can then map to your object by instantiating a new Treasure with your received JSON.

```swift
if let json = json as? [String: Any] {
    let projects: [Project]? = Treasure(json: json).map()
}
```

Other top-level JSON API objects can be accessed through your Treasure instance.

```swift
if let json = json as? [String: Any] {

    let treasure = Treasure(json: json)
    let projects: [Project]? = treasure.map()
    
    guard projects != nil else {
        print(treasure.errors)
    }
}
```

## License

Treasure is available under the MIT license. See the LICENSE file for more info.
Lyft's Mapper is available under the Apache 2.0 License
