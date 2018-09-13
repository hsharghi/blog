import Vapor
import Crypto
import Authentication
import Pagination
import FluentSQL


/// Controls basic CRUD operations on `User`s.
final class PostController: RouteCollection {
    
    func boot(router: Router) throws {
        
//        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCrypt)
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        //        let basicAuthGroup = router.grouped([basicAuthMiddleware, guardAuthMiddleware])
        
        let guardedRoutes = router.grouped([tokenAuthMiddleware, guardAuthMiddleware])
        let posts = guardedRoutes.grouped("posts")
        //        let posts = router.grouped("posts",[basicAuthMiddleware, guardAuthMiddleware])
        
        posts.get(use: index)
        posts.post(use: create)
        posts.patch(Post.parameter, use: update)
        
        router.get("posts", Post.parameter, use: show)
        router.get("posts", "all", use: all)
        router.get("posts", "paginated", use: paginatedPosts)
        router.get("postcomments", use: getPostsWithComments)

        // good way to get update paramters
        //        posts.patch(UserContent.self, at: User.parameter, use: update)
    }
    
    func paginatedPosts(_ req: Request) throws -> Future<Paginated<Post>> {
        return try Post.query(on: req).paginate(for: req)
    }
    

    func getPostsWithComments(_ req: Request) throws -> Future<PaginatedResponse<Post.PostWithComments>> {
        return try Post.query(on: req).paginate(for: req).flatMap { posts -> Future<PaginatedResponse<Post.PostWithComments>> in
            let postIds = try posts.data.map({ try $0.requireID() })
            let authorIds = posts.data.map({ $0.userId })
            let comments = try Comment.query(on: req).filter(\.postId ~~ postIds).all()
            let users = try User.query(on: req).filter(\.id ~~ authorIds).all()
            return map(to: PaginatedResponse<Post.PostWithComments>.self, comments, users, { (comments, users) -> PaginatedResponse<Post.PostWithComments> in
                var postsWithComments: [Post.PostWithComments] = []
                try posts.data.forEach({ (post) in
                    let postComments = comments.filter({$0.postId == post.id})
                    let user = users.filter({$0.id == post.userId}).first
                    try postsWithComments.append(Post.PostWithComments(id: post.requireID(), title: post.title, body: post.body, author: user?.toPublicUser(), comments: postComments))
                })
                
                return PaginatedResponse(data: postsWithComments, pageInfo: posts.page)
            })
        }
    }
    
    
    /*
     // with on relation (only comments)
     
    func getPostsWithComments(_ req: Request) throws -> Future<PaginatedResponse<Post.PostWithComments>> {
        return try Post.query(on: req).paginate(for: req).flatMap { posts -> Future<PaginatedResponse<Post.PostWithComments>> in
            let postIds = try posts.data.map({ try $0.requireID() })
            return try Comment.query(on: req).filter(\.postId ~~ postIds).all().map(to: PaginatedResponse<Post.PostWithComments>.self, { comments in
                var postsWithComments: [Post.PostWithComments] = []
                try posts.data.forEach({ (post) in
                    let postComments = comments.filter({$0.postId == post.id})
                    try postsWithComments.append(Post.PostWithComments(id: post.requireID(), title: post.title, body: post.body, comments: postComments))
                })
                
                return PaginatedResponse(data: postsWithComments, pageInfo: posts.page)
            })
        }
    }
    */

    func all(_ req: Request) throws -> Future<[Post.PostList]> {
        return try Post.query(on: req).sort(\.createdAt, .descending).all().flatMap(to: [Post.PostList].self) { posts -> Future<[Post.PostList]> in
            let p = try Page(number: 1, data: posts, size: 10, total: posts.count)
            print(p)
            return try posts.map{ post -> Future<Post.PostList> in
                return try post.author.get(on: req).map(to: Post.PostList.self) { author -> Post.PostList in
                    return try Post.PostList(id: post.requireID(), title: post.title, body: post.body, author: author.toPublicUser())
                }
            }.flatten(on: req)
        }
    }

    func index(_ req: Request) throws -> Future<Paginated<Post>> {
        let user = try req.authenticated(User.self)
        return (try user?.posts.query(on: req).paginate(for: req))!
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
            throw Abort(.forbidden, reason: "Couldn't get the authenticated user!")
        }
        let postData = try req.content.syncDecode(Post.CreatePost.self)
        let post = Post(title: postData.title, body: postData.body, userId: userId!)
        
        return post.save(on: req)
        
    }
    
    
    func update(_ req: Request) throws -> Future<Post> {
        let user = try req.authenticated(User.self)
        let userId = user?.id
        guard userId != nil else {
            throw Abort(.forbidden, reason: "Couldn't get the authenticated user!")
        }
        
        let post = try req.parameters.next(Post.self).map { post throws -> Post in
            guard post.userId == userId else {
                throw Abort(.forbidden, reason: "The post you are trying to update, is not yours!")
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
            throw Abort(.forbidden, reason: "Couldn't get the authenticated user!")
        }
        
        return try req.parameters.next(Post.self).flatMap { post throws -> Future<HTTPStatus> in
            guard post.userId == userId else {
                throw Abort(.forbidden, reason: "The post you are trying to delete, is not yours!")
            }
            return post.delete(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
}












