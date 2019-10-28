import Vapor
import FluentMySQL

final class ResourceController: RouteCollection {
    
    /// Registers handlers
    func boot(router: Router) throws {
        let v1 = router.grouped("api/v1")
        
        v1.get("store", use: fetchAvailable)
        v1.post([Resource].self, at: "refill", use: add)
        v1.post("order", DBRecipe.parameter, use: order)
    }
    
    var store: DBStore
    
    init() {
        self.store = DBStore(id: 1)
    }
    
    /// removes the required resources from the store if available
    func order(_ req: Request) throws -> Future<Wrapper<V>> {
        return try req.parameters.next(DBRecipe.self).flatMap(to: ([DBResource], DBRecipe).self, { recipe in
            return try recipe.resources.query(on: req).all().and(result: recipe)
        }).flatMap { (resources, recipe) in
            return try self.store.remove(resources, on: req).transform(to: Wrapper<V>("ordered \(recipe.title)"))
        }
    }
    
    
    /// Returns a list of all resources in store
    func fetchAvailable(_ req: Request) throws -> Future<Wrapper<[Resource]>> {
        return try store.items.query(on: req).all().map { items in
            
            guard items.count > 0 else {
                throw RecipeError.noRecipesFound
            }
            
            return Wrapper(of: items.map { dbresource in
                return dbresource.public
            }, "\(items.count) resources found")
        }
    }
    
    /// Adds a resource to the store
    func add(_ req: Request, resources: [Resource]) throws -> Future<Wrapper<V>> {
        let message = req.eventLoop.newPromise(of: Wrapper<V>.self)
        
        DispatchQueue.global().async {
            DBStore.semaphore.wait()
            defer {
                DBStore.semaphore.signal()
            }
            for r in resources {
                let dbr = DBResource(name: r.name, amount: r.amount, storeID: self.store.id!)
                _ = dbr.save(on: req)
            }
            message.succeed(result: Wrapper<V>("\(resources.count) resources added to store"))
        }
        return message.futureResult
    }
    
}

