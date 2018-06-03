import Vapor
import Crypto
import Authentication
import Debugging

/// Controls basic CRUD operations on `User`s.
final class PostController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCrypt)
        let guardAuthMiddleware = User.guardAuthMiddleware()
        //        let basicAuthGroup = router.grouped([basicAuthMiddleware, guardAuthMiddleware])
        
        let guardedRoutes = router.grouped([basicAuthMiddleware, guardAuthMiddleware])
        let posts = guardedRoutes.grouped("posts")
        //        let posts = router.grouped("posts",[basicAuthMiddleware, guardAuthMiddleware])
        
        posts.get(use: index)
        posts.post(use: create)
        posts.patch(Post.parameter, use: update)
        
        router.get("posts", Post.parameter, use: show)
        router.get("posts", "all", use: all)
        
        // good way to get update paramters
        //        posts.patch(UserContent.self, at: User.parameter, use: update)
    }
    
    
    func all(_ req: Request) throws -> Future<[Post.PostList]> {
        
        return try Post.query(on: req).sort(\.createdAt, .descending).all().flatMap(to: [Post.PostList].self) { posts -> Future<[Post.PostList]> in    //2
            return try posts.map{ post -> Future<Post.PostList> in    //3
                return try post.author.get(on: req).map(to: Post.PostList.self) { author -> Post.PostList in    //4
                    let publicUser = User.PublicUser(id: author.id!, username: author.username, email: author.email)
                    return try Post.PostList(id: post.requireID(), title: post.title, body: post.body, author: publicUser)        //5
                }
                }.flatten(on: req)    //6
        }
    }
    
    func index(_ req: Request) throws -> Future<[Post]> {
        let user = try req.authenticated(User.self)
        return (try user?.posts.query(on: req).sort(\.createdAt, .descending).all())!
    }
    
    
    func show(_ req: Request) throws -> Future<Post.PostList> {
        return try req.parameters.next(Post.self).flatMap(to: Post.PostList.self) { post -> Future<Post.PostList> in
            return try post.author.get(on: req).map{ author -> Post.PostList in
                let publicUser = User.PublicUser(id: author.id!, username: author.username, email: author.email)
                return Post.PostList(id: post.id!, title: post.title, body: post.body, author: publicUser)
            }
        }
    }
    
    
    
    func create(_ req: Request) throws -> Future<Post> {
        // sync decode and async save
        
        let user = try req.authenticated(User.self)
        let userId = user?.id
        guard userId != nil else {
            throw AuthError(
                identifier: "userNotGot",
                reason: "Couldn't get the authenticated user!",
                source: .capture()
            )
        }
        let postData = try req.content.syncDecode(Post.CreatePost.self)
        //        repeat {
        //            userId = Int(arc4random_uniform(5))
        //        } while userId == 0
        let post = Post(title: postData.title, body: postData.body, userId: userId!)
        
        return post.save(on: req)
        
    }
    
    
    func update(_ req: Request) throws -> Future<Post> {
        let user = try req.authenticated(User.self)
        let userId = user?.id
        guard userId != nil else {
            throw AuthError(
                identifier: "userNotGot",
                reason: "Couldn't get the authenticated user!",
                source: .capture()
            )
        }
        
        let post = try req.parameters.next(Post.self).map { post throws -> Post in
            guard post.userId == userId else {
                throw AuthError(
                    identifier: "notYourPost",
                    reason: "The post you are trying to update, is not yours!",
                    source: .capture()
                )
            }
            return post
        }
        
        let newValues = try req.content.decode(Post.UpdatablePost.self)
        
        return flatMap(to: Post.self, post, newValues, { (post, newValues) in
            post.title = newValues.title ?? post.title
            post.body = newValues.body ?? post.body
            
            return post.update(on: req)
        })
    }
    
    
    /// Deletes a parameterized `Post`
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.authenticated(User.self)
        let userId = user?.id
        guard userId != nil else {
            throw AuthError(
                identifier: "userNotGot",
                reason: "Couldn't get the authenticated user!",
                source: .capture()
            )
        }
        
        return try req.parameters.next(Post.self).flatMap { post throws -> Future<HTTPStatus> in
            guard post.userId == userId else {
                throw AuthError(
                    identifier: "notYourPost",
                    reason: "The post you are trying to delete, is not yours!",
                    source: .capture()
                )
            }
            return post.delete(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
}


struct AuthError: Debuggable {
    /// See Debuggable.readableName
    public static let readableName = "Can't get User"
    
    /// See Debuggable.reason
    public let identifier: String
    
    /// See Debuggable.reason
    public var reason: String
    
    /// See Debuggable.sourceLocation
    public var sourceLocation: SourceLocation?
    
    /// See stackTrace
    public var stackTrace: [String]
    
    /// Create a new authentication error.
    init(
        identifier: String,
        reason: String,
        source: SourceLocation
        ) {
        self.identifier = identifier
        self.reason = reason
        self.sourceLocation = source
        self.stackTrace = AuthenticationError.makeStackTrace()
    }
}















