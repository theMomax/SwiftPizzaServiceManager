import FluentMySQL
import Vapor

enum PromiseError: Error {
    case resourcesPromiseFailed
}

final class DBRecipe: MySQLModel {
    
    init(id: Int? = nil, title: String = "") {
        self.id = id
        self.title = title
    }
    
    var id: Int?
    
    var title: String
    
    var resources: Children<DBRecipe, DBResource> {
        return children(\.recipeID)
    }
    
    
    func `public`(on con: DatabaseConnectable) throws -> EventLoopFuture<Recipe> {
        return try resources.query(on: con).all().map { resources in
            let recipe = Recipe(id: self.id, title: self.title)
            for r in resources {
                recipe.resources.append(r.public)
            }
            return recipe
        }
    }
}

extension DBRecipe: Migration { }

extension DBRecipe: Parameter { }

final class Recipe {
    
    var id: Int?
    
    var title: String
    
    var resources: [Resource]
    
    init(id: Int? = nil, title: String = "", resources: [Resource] = []) {
        self.id = id
        self.title = title
        self.resources = resources
    }
}

extension Recipe: Content { }
