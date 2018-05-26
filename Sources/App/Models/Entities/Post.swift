import FluentMySQL
import Vapor

/// A single entry of a Todo list.
final class Post: MySQLModel {

    var id: Int?
    var title: String
    var body: String
    var createdAt: Date?
    var updatedAt: Date?
    var userId: User.ID

    static var createdAtKey: WritableKeyPath<Post, Date?> {
        return \.createdAt
    }
    
    static var updatedAtKey: WritableKeyPath<Post, Date?> {
        return \.updatedAt
    }
    

    /// Creates a new `Post`.
    init(id: Int? = nil, title: String, body: String, userId: User.ID) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = userId
    }
}

/// Allows `Post` to be used as a dynamic migration.
extension Post: Migration {
    //optional method if want more control over migration process
    internal static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return MySQLDatabase.create(self, on: connection) { builder in
            
            // auto create fields from model properties
            try addProperties(to: builder)
//
//            try builder.field(type: Int.mySQLColumnDefinition, for: \.id, isIdentifier: true)
//            try builder.field(for: \.title)
//            try builder.field(for: \.body)
//            try builder.field(for: \.createdAt)
//            try builder.field(for: \.updatedAt)
//            try builder.field(for: \.userId)
            try builder.addReference(from: \.userId, to: \User.id)
        }
    }
}

/// Allows `Post` to be encoded to and decoded from HTTP messages.
extension Post: Content { }

/// Allows `Post` to be used as a dynamic parameter in route definitions.
extension Post: Parameter { }

extension Post: Timestampable { }

extension Post {
    var author: Parent<Post, User> {
        return parent(\.userId)
    }
}

extension Post {
    struct CreatePost: Content {
        var title: String
        var body: String
    }
    
    struct PostList: Content {
        var id: Int
        var title : String
        var body: String
        var author: User?
        
        init(id: Int, title: String, body: String, author: User? = nil) {
            self.id = id
            self.title = title
            self.body = body
            self.author = author
        }
    }
//
//    struct PublicUser: Content {        
//        var id: Int
//        var username: String?
//        var email: String
//    }
}
