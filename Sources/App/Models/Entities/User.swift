import FluentMySQL
import Vapor
import Authentication

/// A single entry of a Todo list.
final class User: MySQLModel {
    /// The unique identifier for this `Todo`.
    var id: Int?
    
    /// A title describing what this `Todo` entails.
    var username: String?
    var email: String
    var password: String
    
    /// Creates a new `User`.
    init(id: Int? = nil, username: String? = nil, email: String, password: String) {
        self.id = id
        self.email = email
        self.username = username
        self.password = password
    }
}

/// Allows `Todo` to be used as a dynamic migration.
extension User: Migration {
    //optional method if want more control over migration process
    internal static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return MySQLDatabase.create(self, on: connection) { builder in
            try addProperties(to: builder)
//
//            try builder.field(type: Int.mySQLColumnDefinition, for: \.id, isIdentifier: true)
//            try builder.field(for: \.username)
//            try builder.field(for: \.email)
//            try builder.field(for: \.password)
//            builder.field(type: .varChar(length: 191), for: \.body)
        }
    }
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }

extension User {
    var posts: Children<User, Post> {
        return children(\.userId)
    }
    
    var comments: Children<User, Comment> {
        return children(\.userId)
    }
    
}


extension User {
    struct UpdatableUser: Content {
        var username: String?
        var password: String?
    }
    
    struct PublicUser: Content {        
        var id: Int
        var username: String?
        var email: String
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: WritableKeyPath<User, String> = \.email
    static let passwordKey: WritableKeyPath<User, String> = \.password
}

