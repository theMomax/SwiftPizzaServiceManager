import FluentSQLite // TODO: remove
import FluentMySQL
import Vapor

enum ServerError: Error {
    case databaseConnectionError
}

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentMySQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.custom(environment: env, log: PrintLogger())) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    let mysql = MySQLDatabase(config: MySQLDatabaseConfig.init(hostname: "localhost", username: "root", password: "root", database: "pizza_swift", transport: MySQLTransportConfig.unverifiedTLS))

    // Register the configured MySQL database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: mysql, as: .mysql)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    
    migrations.add(model: DBResource.self, database: .mysql)
    migrations.add(model: DBRecipe.self, database: .mysql)
    migrations.add(model: DBStore.self, database: .mysql)
    services.register(migrations)
}
