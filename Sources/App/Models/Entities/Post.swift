import FluentMySQL
import Vapor
import Pagination
import Fluent
import FluentSQL

/// A single entry of a Todo list.
final class Post: MySQLModel {

    static let entity = "posts"

    var id: Int?
    var title: String
    var body: String
    var createdAt: Date?
    var updatedAt: Date?
    var userId: User.ID

    static var createdAtKey: TimestampKey? = \.createdAt
    static var updatedAtKey: TimestampKey? = \.updatedAt
    

    /// Creates a new `Post`.
    init(id: Int? = nil, title: String, body: String, userId: User.ID, createdAt: Date? = nil) {
        self.id = id
        self.title = title
        self.body = body
        if let date = createdAt {
            self.createdAt = date
        }
        self.userId = userId
    }
    /*
    func willCreate(on connection: MySQLConnection) throws -> EventLoopFuture<Post> {
         self.title = "***changed title***"
        return connection.future(self.self)

    }
 */
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
            builder.reference(from: \.userId, to: \User.id)
        }
    }
}

/// Allows `Post` to be encoded to and decoded from HTTP messages.
extension Post: Content { }

/// Allows `Post` to be used as a dynamic parameter in route definitions.
extension Post: Parameter { }

extension Post: Paginatable { }

extension Post {
    var author: Parent<Post, User> {
        return parent(\.userId)
    }
    
    var comments: Children<Post, Comment> {
        return children(\.postId)
    }
}

extension Post {
    struct CreatePost: Content {
        var title: String
        var body: String
    }
    
    struct UpdatablePost: Content {
        var title: String?
        var body: String?
    }

    struct PostList: Content {
        var id: Int
        var title : String
        var body: String
        var author: User.PublicUser?
        
        init(id: Int, title: String, body: String, author: User.PublicUser? = nil) {
            self.id = id
            self.title = title
            self.body = body
            self.author = author
        }
    }
    
    struct PostWithComments: Content {
        var id: Int
        var title : String
        var body: String
        var author: User.PublicUser?
        var comments: [Comment]
        
        init(id: Int, title: String, body: String, author: User.PublicUser?, comments: [Comment]) {
            self.id = id
            self.title = title
            self.body = body
            self.author = author
            self.comments = comments
        }
    }
//
//    struct PublicUser: Content {        
//        var id: Int
//        var username: String?
//        var email: String
//    }
}
