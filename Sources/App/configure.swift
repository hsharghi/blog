//import FluentSQLite
import FluentMySQL
import Vapor
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
//    try services.register(FluentSQLiteProvider())
    try services.register(FluentMySQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    try services.register(AuthenticationProvider())

    // Configure a SQLite database
//    let sqlite = try SQLiteDatabase(storage: .file(path: "/Users/hadi/Programming/Swift/vapor/blog/mydb.sqlite"))

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    let config = MySQLDatabaseConfig(
        username: "root",
        password: "hadi2400",
        database: "blog"
    )
    let mysql = MySQLDatabase(config: config)
    //    databases.add(database: sqlite, as: .sqlite)
    databases.add(database: mysql, as: .mysql)

    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: Post.self, database: .mysql)
    services.register(migrations)

}
