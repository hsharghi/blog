import Vapor
import Crypto

/// Controls basic CRUD operations on `User`s.
final class UserController: RouteCollection {
    
    func boot(router: Router) throws {
        let users = router.grouped("users")
        
        users.get(use: index)
        users.get(User.parameter, use: show)
        users.post(use: create)
        users.patch(User.parameter, use: update)

        // good way to get update paramters
//        users.patch(UserContent.self, at: User.parameter, use: update)
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



