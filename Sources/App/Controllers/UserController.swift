import Vapor
import Crypto

/// Controls basic CRUD operations on `User`s.
final class UserController {
    /// Returns a list of all `Users`s.
    func all(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    func index(_ req: Request) throws -> Future<[User.PublicUser]> {
        return User.query(on: req).all().map { users in
            return try users.map({ (user) in
                return try User.PublicUser(id: user.requireID(), username: user.username, email: user.email)
            })
        }
    }
    
    /// Returns public properties of a `Users`.
    func show(_ req: Request) throws -> Future<User.PublicUser> {
        let user = try req.parameters.next(User.self)
        
        return user.map { user in
            return try User.PublicUser(id: user.requireID(), username: user.username, email: user.email)
        }
    }
    
    func create(_ req: Request) throws -> Future<User.PublicUser> {
        // sync decode and async save
        let user = try req.content.syncDecode(User.self)
        let hasher = try req.make(BCryptDigest.self)
        user.password = try hasher.hash(user.password, cost: 4)
        return user.save(on: req).map { user in
            return User.PublicUser(id: user.id!, username: user.username, email: user.email)
        }
        
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
            if newValues.username != nil {
                user.username = newValues.username!
            }
            
            return user.save(on: req).map { user in
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
}



