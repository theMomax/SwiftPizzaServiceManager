import Vapor
import FluentMySQL

final class ResourceController {
    
    var store: DBStore
    
    init() {
        self.store = DBStore(id: 1)
    }
    
    /// removes the required resources from the store if available
    func order(_ req: Request) throws -> EventLoopFuture<Response> {
        return try req.parameters.next(DBRecipe.self).flatMap { recipe in
            return try recipe.resources.query(on: req).all().flatMap { resources in
                return try self.store.remove(resources, on: req).transform(to: Responder<String>("ordered \(recipe.title)").respond(to: req))
            }
        }
    }
    
    
    /// Returns a list of all resources in store
    func fetchAvailable(_ req: Request) throws -> EventLoopFuture<Response> {
        return try store.items.query(on: req).all().flatMap { items in
            
            if items.count == 0 {
                throw RecipeError.noRecipesFound
            }
            
            return items.map { dbresource in
                return dbresource.resolve(on: req)
            }.flatten(on: req).flatMap { resources in
                return Responder(of: resources, "\(resources.count) recipes found").respond(to: req)
            }
        }
    }
    
    /// Adds a resource to the store
    func add(_ req: Request) throws -> EventLoopFuture<Response> {
        return try req.content.decode([Resource].self).flatMap { resources in
            DBStore.semaphore.wait()
            defer {
                DBStore.semaphore.signal()
            }
            for r in resources {
                let dbr = DBResource(name: r.name, amount: r.amount, storeID: self.store.id!)
                _ = dbr.save(on: req)
            }
            return Responder<String>("\(resources.count) resources added to store").respond(to: req)
        }
    }
    
}

