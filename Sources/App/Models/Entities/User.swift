import FluentMySQL
import Vapor
import Authentication
//import JWTAuthenticatable

/// A single entry of a Todo list.
final class User: MySQLModel {
    
    static let entity = "users"

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

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }

/// Allow authenticate for User model
extension User: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> { return \User.email }
    static var passwordKey: WritableKeyPath<User, String> { return \User.password }
}


extension User: TokenAuthenticatable {
    typealias TokenType = Token
}


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
    
    struct AuthenticatableUser: Content {
        var email: String
        var password: String
    }

    struct AuthenticatedUser: Content {
        var token: String
    }

    struct PublicUser: Content {
        var id: Int
        var username: String?
        var email: String
    }
    
    struct FullUser: Content {
        var user: User.PublicUser
        var posts: [Post]
        var comments: [Comment]
    }
    
}

extension Future where T == User {
    func toPublicUser() -> Future<User.PublicUser> {
        return self.map { user in
            return try User.PublicUser(id: user.requireID(), username: user.username, email: user.email)
        }
    }

    func toAuthenticatedUser(on conn: DatabaseConnectable) -> Future<User.AuthenticatedUser> {
        return self.flatMap(to: User.AuthenticatedUser.self) { createdUser in
            let accessToken = try Token.createToken(forUser: createdUser)
            return accessToken.save(on: conn).map(to: User.AuthenticatedUser.self) { createdToken in
                return User.AuthenticatedUser(token: createdToken.token)
            }
        }
    }
}

extension Future where T == [User] {
    func toPublicUsers() -> Future<[User.PublicUser]> {
        return self.map { users in
            return users.map({ (user) in
                return user.toPublicUser()
            })
        }
    }
}

extension User {
    func toPublicUser() -> User.PublicUser {
        return User.PublicUser(id: self.id!, username: self.username, email: self.email)
    }
}


