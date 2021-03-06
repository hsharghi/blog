import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example to check if local server is working
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    try router.register(collection: UserController())
    try router.register(collection: PostController())
    try router.register(collection: CommentController())
    try router.register(collection: SeederController())
    

    // Example of configuring a controller
    //    let userController = UserController()
    //    router.post("users", use: UserController.create)
    //    router.get("users", use: UserController.index)
    //    router.get("users", User.parameter, use: UserController.show)
    //    router.patch("users", use: UserController.update)
    //    router.delete("users", User.parameter, use: UserController.delete)
}

