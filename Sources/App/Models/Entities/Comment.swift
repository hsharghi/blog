import FluentMySQL
import Vapor
import Pagination
import Fluent

/// A single entry of a Todo list.
final class Comment: MySQLModel {

    static let entity = "comments"
    
    var id: Int?
    var userId: User.ID
    var postId: Post.ID
    var body: String
    var createdAt: Date?
    var updatedAt: Date?

    static var createdAtKey: TimestampKey? = \.createdAt
    static var updatedAtKey: TimestampKey? = \.updatedAt
    

    /// Creates a new `Comment`.
    init(id: Int? = nil, postId: Post.ID, userId: User.ID, body: String) {
        self.id = id
        self.body = body
        self.userId = userId
        self.postId = postId
    }
}

/// Allows `Comment` to be used as a dynamic migration.
extension Comment: Migration {
    //optional method if want more control over migration process
    internal static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return MySQLDatabase.create(self, on: connection) { builder in
            
            // auto create fields from model properties
            try addProperties(to: builder)

            builder.reference(from: \.userId, to: \User.id)
            builder.reference(from: \.postId, to: \Post.id)
        }
    }
}

/// Allows `Comment` to be encoded to and decoded from HTTP messages.
extension Comment: Content { }

/// Allows `Comment` to be used as a dynamic parameter in route definitions.
extension Comment: Parameter { }

extension Comment: Paginatable { }

extension Comment {
    var commentator: Parent<Comment, User> {
        return parent(\.userId)
    }
    
    var post: Parent<Comment, Post> {
        return parent(\.postId)
    }
}


extension Comment: Pivot {
    static var leftIDKey: WritableKeyPath<Comment, Int> {
        return \.userId
    }
    
    static var rightIDKey: WritableKeyPath<Comment, Int> {
        return \.postId

    }
    
    typealias Left = User
    
    typealias Right = Post
}


extension Comment {
    struct CreateComment: Content {
        var body: String
    }
    
    struct UpdatableComment: Content {
        var body: String?
    }
    
    struct CommentList: Content {
        var id: Int
        var body: String
        var commentator: User.PublicUser?
        var onPost: Post?
        var date: Date
        
        init(id: Int, body: String, onPost: Post? = nil, commentator: User.PublicUser? = nil, date: Date) {
            self.id = id
            self.onPost = onPost
            self.body = body
            self.commentator = commentator
            self.date = date
        }
    }
}
