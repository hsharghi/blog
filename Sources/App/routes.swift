import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    let userController = UserController()
    let usersGroupRoutes = router.grouped("users")
//    router.get("users", use: userController.index)
    usersGroupRoutes.get(use: userController.index)
    usersGroupRoutes.get("all", use: userController.all)
    usersGroupRoutes.get(User.parameter, use: userController.show)
    usersGroupRoutes.post(use: userController.create)
    usersGroupRoutes.patch(User.parameter, use: userController.update)

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
}
