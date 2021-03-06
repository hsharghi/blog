import Vapor
import Crypto
import Authentication
import Pagination
import Fluent
import FluentMySQL

/// Controls basic CRUD operations on `User`s.
final class CommentController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCrypt)
        let guardAuthMiddleware = User.guardAuthMiddleware()
        
        let guardedRoutes = router.grouped([basicAuthMiddleware, guardAuthMiddleware])
        let comments = guardedRoutes.grouped("comments")
        
        comments.get("my", use: getMyComments)
        comments.post(use: create)
        comments.patch(Comment.parameter, use: update)
        comments.delete(Comment.parameter, use: delete)

        router.get("comments", "post", Post.parameter, use: getCommentsOnPost)
        router.get("test", use: test)
    }
    
    func test(_ req: Request) throws -> Future<[Comment]> {
        let ids: [Int]  = []
//
//        return req.withPooledConnection(to: .mysql) { conn -> Future<[User]> in
//            return conn.raw("""
//               // enter raw query
//            """).all(decoding: Comment.self)
//        }

      
        return User.find(1, on: req).flatMap(to: [Comment].self) { user -> Future<[Comment]> in
            if let user = user  {
                return try user.comments.query(on: req).all()
//                            return try user.posts.query(on: req).all().map { posts -> Future<[Comment]> in
//                                return try posts.forEach({ post in
//                                        return try post.comments.query(on: req).filter(\.userId == user.id).all()
//                                })
//                            }

            } else {
                throw Abort(HTTPStatus.notFound)
            }
        }
    }
    
    
    func getMyComments(_ req: Request) throws -> Future<[Comment.CommentList]> {
        let user = try req.authenticated(User.self)
        guard user != nil else {
            throw Abort(.unauthorized, reason: "You need to login to see comments")
        }        
        return try user!.comments.query(on: req).sort(\.createdAt, .descending).all().flatMap(to: [Comment.CommentList].self) { comments -> Future<[Comment.CommentList]> in
            return comments.map { comment -> Future<Comment.CommentList> in
                return comment.post.get(on: req).map(to: Comment.CommentList.self) { post -> Comment.CommentList in
                    return try Comment.CommentList(id: comment.requireID(), body: comment.body, onPost: post, commentator: user!.toPublicUser(), date: comment.createdAt ?? Date())
                }
                }.flatten(on: req)
        }
    }
    
//
//    func getCommentsOnPost(_ req: Request) throws -> Future<Paginated<Comment.CommentList>> {
//        return try req.parameters.next(Post.self).flatMap(to: Paginated<Comment.CommentList>.self) { post -> Future<Paginated<Comment.CommentList>> in
//            return try post.comments.query(on: req).sort(\.createdAt, .descending).paginate(for: req).flatMap(to: Paginated<Comment.CommentList>.self) { comments -> Future<Paginated<Comment.CommentList>> in
//                var commentList = comments.data
//                 = try comments.data.map { comment -> Future<Comment.CommentList> in
//                    return try comment.commentator.get(on: req).map(to: Comment.CommentList.self) { commentator -> Comment.CommentList in
//                        return try Comment.CommentList(id: comment.requireID(), body: comment.body, commentator: commentator.toPublicUser(), date: comment.createdAt ?? Date())
//                    }
//                    }.flatten(on: req)
//                
//            }
//        }
//    }
//


    
    
    func getCommentsOnPost(_ req: Request) throws -> Future<[Comment.CommentList]> {
        return try req.parameters.next(Post.self).flatMap(to: [Comment.CommentList].self) { post -> Future<[Comment.CommentList]> in
            return try post.comments.query(on: req).sort(\.createdAt, .descending).all().flatMap(to: [Comment.CommentList].self) { comments -> Future<[Comment.CommentList]> in
                return comments.map { comment -> Future<Comment.CommentList> in
                    return comment.commentator.get(on: req).map(to: Comment.CommentList.self) { commentator -> Comment.CommentList in
                        return try Comment.CommentList(id: comment.requireID(), body: comment.body, commentator: commentator.toPublicUser(), date: comment.createdAt ?? Date())
                    }
                    }.flatten(on: req)
            }
        }
    }

    
    func create(_ req: Request) throws -> Future<Comment> {
        // sync decode and async save
        
        let user = try req.authenticated(User.self)
        let userId = user?.id
        guard userId != nil else {
            throw Abort(.forbidden, reason: "Couldn't get the authenticated user!")
        }
        let commentData = try req.content.syncDecode(Comment.CreateComment.self)
        
        return req.content[Int.self, at: "postId"].flatMap(to: Comment.self) { postId  in
            guard postId != nil else {
                throw Abort(.badRequest, reason: "`postId` is required")
            }

            return Post.find(postId!, on: req).flatMap(to: Comment.self) { post in
                guard post != nil else {
                    throw Abort(.badRequest, reason: "The post you are trying to put a comment on, is not found!")
                }

                let comment = Comment(postId: postId!, userId: userId!, body: commentData.body)
                return comment.save(on: req)
            }
        }
        
    }
    
    
    func update(_ req: Request) throws -> Future<Comment> {
        let user = try req.authenticated(User.self)
        let userId = user?.id
        guard userId != nil else {
            throw Abort(.forbidden, reason: "Couldn't get the authenticated user!")

        }
        
        let comment = try req.parameters.next(Comment.self).map { comment throws -> Comment in
            guard comment.userId == userId else {
                throw Abort(.forbidden, reason: "The comment you are trying to update, is not yours!")
            }
            return comment
        }
        
        let newValues = try req.content.decode(Comment.UpdatableComment.self)
        
        return flatMap(to: Comment.self, comment, newValues, { (comment, newValues) in
            comment.body = newValues.body ?? comment.body
            
            return comment.update(on: req)
        })
    }
    
    
    /// Deletes a parameterized `Post`
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.authenticated(User.self)
        let userId = user?.id
        guard userId != nil else {
            throw Abort(.forbidden, reason: "Couldn't get the authenticated user!")

        }
        
        return try req.parameters.next(Comment.self).flatMap { comment throws -> Future<HTTPStatus> in
            guard comment.userId == userId else {
                throw Abort(.forbidden, reason: "The comment you are trying to delete, is not yours!")
            }
            return comment.delete(on: req).transform(to: HTTPStatus.ok)
        }
    }
    
}













