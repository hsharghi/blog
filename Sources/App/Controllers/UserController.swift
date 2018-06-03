import Vapor
import Crypto

/// Controls basic CRUD operations on `User`s.
final class UserController: RouteCollection {
    
    func boot(router: Router) throws {
        let users = router.grouped("users")
        
        users.post("login", use: login)
        users.post("register", use: register)
        
        users.get(use: index)
        users.get(User.parameter, use: show)
        users.post(use: create)
        users.patch(User.parameter, use: update)

        // good way to get update paramters
//        users.patch(UserContent.self, at: User.parameter, use: update)
    }
    
    
    func register(_ req: Request) throws -> Future<User> {
        let user = req.content.syncDecode(User.self)
        
        
        return try request.content.decode(User.self).flatMap(to: User.PublicUser.self) { user in // 2
            let passwordHashed = try request.make(BCryptDigest.self).hash(user.password)
            let newUser = User(username: user.username, password: passwordHashed)
            return newUser.save(on: request).flatMap(to: User.PublicUser.self) { createdUser in
                let accessToken = try Token.createToken(forUser: createdUser) // 3
                return accessToken.save(on: request).map(to: User.PublicUser.self) { createdToken in // 4
                    let publicUser = User.PublicUser(username: createdUser.username, token: createdToken.token)
                    return publicUser // 5
                }
            }
        }
    }
    }
    
    func login(_ req: Request) throws -> Future<User> {
        let user = try req.content.decode(User.AuthenticatableUser.self).flatMap { (user) -> Future<User> in
            let passwordVerifier = try req.make(BCryptDigest.self)
            return User.authenticate(username: user.email,
                                     password: user.password,
                                     using: passwordVerifier,
                                     on: req).unwrap(or: Abort.init(HTTPResponseStatus.unauthorized))
        }
    }
    
    
    /// Returns a list of all `Users`s.
    func all(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    func index(_ req: Request) throws -> Future<[User.PublicUser]> {
        return User.query(on: req).all().toPublicUser()
    }
    

    /// Returns public properties of a `Users`.
    func show(_ req: Request) throws -> Future<User.PublicUser> {
        return try req.parameters.next(User.self).toPublicUser()
    }
    
    func create(_ req: Request) throws -> Future<User.PublicUser> {
        // sync decode and async save
        let user = try req.content.syncDecode(User.self)
        let hasher = try req.make(BCryptDigest.self)
        user.password = try hasher.hash(user.password, cost: 4)
        return user.save(on: req).toPublicUser()
        
        // async decode and async save with flatMap
        //        return try req.content.decode(User.self).flatMap { user in
        //            return user.save(on: req)
        //        }
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
            }.transform(to: .ok)
    }
}



