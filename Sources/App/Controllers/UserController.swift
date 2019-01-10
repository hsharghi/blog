import Vapor
import Crypto
import Authentication
import FluentMySQL
import Fluent

/// Controls basic CRUD operations on `User`s.
final class UserController: RouteCollection {

    func boot(router: Router) throws {
        let users = router.grouped("users")

        users.post("login", use: login)

        users.get("full", use: fullUser)
        users.get(use: index)
        users.get(User.parameter, use: show)
        users.post(use: create)
        users.patch(User.parameter, use: update)
        users.delete(User.parameter, use: delete)
        // good way to get update paramters
//        users.patch(UserContent.self, at: User.parameter, use: update)
    }

    func login(_ req: Request) throws -> Future<User.AuthenticatedUser> {
        let user = try req.content.decode(User.AuthenticatableUser.self).flatMap { (user) -> Future<User> in
            let passwordVerifier = try req.make(BCryptDigest.self)
            return User.authenticate(username: user.email,
                    password: user.password,
                    using: passwordVerifier,
                    on: req).unwrap(or: Abort.init(HTTPResponseStatus.unauthorized))
        }
        return user.toAuthenticatedUser(on: req)
    }

    func index(_ req: Request) throws -> Future<[User.PublicUser]> {
        return User.query(on: req).all().toPublicUsers()
    }

    /// Returns public properties of a `Users`.
    func show(_ req: Request) throws -> Future<User.PublicUser> {
        return try req.parameters.next(User.self).toPublicUser()
    }
    

    /// Returns users with posts and comments for each user
    func fullUser(_ req: Request) throws -> Future<[User.Hamechi]> {        
        return User.query(on: req).range(..<5).all().flatMap { users -> Future<[User.Hamechi]> in
            let ids = users.map { $0.id! }
            var hamechi = [User.Hamechi]()
            let allPosts = Post.query(on: req).filter(\.userId ~~ ids).all()
            let allComments = Comment.query(on: req).filter(\.userId ~~ ids).all()
            
            return map(to: [User.Hamechi].self, allPosts, allComments, { (posts, comments)  in
                users.forEach({ (user) in
                    let userPosts = posts.filter { $0.userId == user.id! }.prefix(2)
                    let userComments = comments.filter { $0.userId == user.id! }.prefix(2)
                    let h = User.Hamechi(user: user.toPublicUser(), posts: Array(userPosts), comments: Array(userComments))
                    hamechi.append(h)
                })
                return hamechi
            })
            
        }
    }
    

    func create(_ req: Request) throws -> Future<User.AuthenticatedUser> {
        // sync decode and async save
        let user = try req.content.syncDecode(User.self)
        return User.query(on: req).filter(\.email == user.email).first().flatMap(to: User.AuthenticatedUser.self) { existingUser in
            guard existingUser == nil else {
                throw Abort(.badRequest, reason: "User with this email address already exists")
            }
            let hasher = try req.make(BCryptDigest.self)
            user.password = try hasher.hash(user.password, cost: 4)
            return user.save(on: req).toAuthenticatedUser(on: req)
        }
    }

    func update(_ req: Request) throws -> Future<User.PublicUser> {
        let user = try req.parameters.next(User.self)
        let newValues = try req.content.decode(User.UpdatableUser.self)

        return flatMap(to: User.PublicUser.self, user, newValues, { user, newValues in

            if newValues.password != nil {
                let hasher = try req.make(BCryptDigest.self)
                user.password = try hasher.hash(newValues.password!, cost: 4)
            }

            user.username = newValues.username ?? user.username

            return user.update(on: req).toPublicUser()
        })
    }


    /// Deletes a parameterized `User`
    func delete(_ req: Request) throws -> Future<HTTPStatus> {


        return try req.parameters.next(User.self).flatMap { user in
            return user.delete(on: req)
        }.catch { (error) in
            print("ridim")
        }.transform(to: .ok)
    }
}

//
//enum VendingMachineError: Error {
//    case invalidSelection
//    case insufficientFunds(reason: String)
//    case outOfStock
//}

