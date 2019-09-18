import FluentMySQL
import Vapor

enum PromiseError: Error {
    case resourcesPromiseFailed
}

final class DBRecipe: MySQLModel {
    
    typealias ID = Int
    
    static let idKey: IDKey = \.id
    
    var id: Int?
    
    var title: String
    
    init(id: Int? = nil, title: String = "") {
        self.id = id
        self.title = title
    }
    
    func resolve(on con: DatabaseConnectable) throws -> EventLoopFuture<Recipe> {
        return try resources.query(on: con).all().map { resources in
            let recipe = Recipe(id: self.id, title: self.title)
            for r in resources {
                recipe.resources.append(Resource(from: r))
            }
            return recipe
        }
    }
}

extension DBRecipe {
    
    var resources: Children<DBRecipe, DBResource> {
        return children(\.recipeID)
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
