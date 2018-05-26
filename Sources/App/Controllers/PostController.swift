import Vapor

/// Controls basic CRUD operations on `User`s.
final class PostController: RouteCollection {
    
    func boot(router: Router) throws {
        let posts = router.grouped("posts")
        
        posts.get(use: index)
        posts.get(Post.parameter, use: show)
        posts.post(use: create)
        //        posts.patch(Post.parameter, use: update)
        
        // good way to get update paramters
        //        posts.patch(UserContent.self, at: User.parameter, use: update)
    }
    
    
    func index(_ req: Request) throws -> Future<[Post.PostList]> {    //1
        return try Post.query(on: req).sort(\.createdAt, .descending).all().flatMap(to: [Post.PostList].self) { posts -> Future<[Post.PostList]> in    //2
            return try posts.map{ post -> Future<Post.PostList> in    //3
                return try post.author.get(on: req).map(to: Post.PostList.self) { author -> Post.PostList in    //4
                    return try Post.PostList(id: post.requireID(), title: post.title, body: post.body, author: author)        //5
                }
            }.flatten(on: req)    //6
        }
    }
    
    
    /// Returns public properties of a `Users`.
    func show(_ req: Request) throws -> Future<Post> {
        return try req.parameters.next(Post.self)
    }
    
    
    
    func create(_ req: Request) throws -> Future<Post> {
        // sync decode and async save
        let postData = try req.content.syncDecode(Post.CreatePost.self)
        var userId : Int
        repeat {
            userId = Int(arc4random_uniform(5))
        } while userId == 0
        let post = Post(title: postData.title, body: postData.body, userId: userId)
        
        return post.save(on: req)
        
    }
    
    /*
     func update(_ req: Request) throws -> Future<User.PublicUser> {
     let user = try req.parameters.next(User.self)
     let newValues = try req.content.decode(User.UpdatableUser.self)
     
     return flatMap(to: User.PublicUser.self, user, newValues, { user, newValues in
     
     if newValues.password != nil {
     let hasher = try req.make(BCryptDigest.self)
     user.password = try hasher.hash(newValues.password!, cost: 4)
     }
     
     user.username = newValues.username ?? user.username
     
     return user.update(on: req).map { user in
     return User.PublicUser(id: user.id!, username: user.username, email: user.email)
     }
     })
     }
     
     
     /// Deletes a parameterized `User`
     func delete(_ req: Request) throws -> Future<HTTPStatus> {
     return try req.parameters.next(User.self).flatMap { user in
     return user.delete(on: req)
     }.transform(to: .ok)
     }
     */
}













