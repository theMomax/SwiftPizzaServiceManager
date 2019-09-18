import Vapor
import FluentMySQL

/// Controls basic CRUD operations on `Recipe`s.
final class RecipeController {
    
    /// Saves a decoded `Recipe` to the database.
    func create(_ req: Request) throws -> EventLoopFuture<Response> {
        return try req.content.decode(Recipe.self).flatMap { recipe in

            guard recipe.id == nil else {
                throw RecipeError.createWithSpecificId
            }
            
            
            guard recipe.title != "" && recipe.resources.count > 0 else {
                throw RecipeError.illegalContent
            }
            
            return DBRecipe.query(on: req).filter(\DBRecipe.title == recipe.title).first().flatMap { duplicate in
                guard duplicate == nil else {
                    throw RecipeError.duplicateTitle(title: recipe.title)
                }
                
                let dbrecipe: DBRecipe = DBRecipe(title: recipe.title)
                
                return dbrecipe.create(on: req).flatMap { dbrecipe in
                    
                    for r in recipe.resources {
                        let dbresource = DBResource(name: r.name, amount: r.amount, recipeID: dbrecipe.id)
                        _ = dbresource.save(on: req)
                    }
                    
                    return Responder(of: dbrecipe.id, with: .created).respond(to: req)
                }
            }
            
        }
    }
    
    /// Updates a decoded `Recipe` on the database.
    func update(_ req: Request) throws -> EventLoopFuture<Response> {
        return try req.content.decode(Recipe.self).flatMap { recipe in
            return try req.parameters.next(DBRecipe.self).flatMap { dbrecipe in
                recipe.id = dbrecipe.id
                
                guard recipe.title != "" && recipe.resources.count > 0 else {
                    throw RecipeError.illegalContent
                }
                
                return dbrecipe.update(on: req).flatMap { dbrecipe in
                    
                    for r in recipe.resources {
                        let dbresource = DBResource(name: r.name, amount: r.amount, recipeID: dbrecipe.id)
                        _ = dbresource.save(on: req)
                    }
                    
                    return Responder(of: dbrecipe.id, with: .created).respond(to: req)
                }
            }
        }
    }
    
    /// Returns the requested `Recipe`.
    func fetch(_ req: Request) throws -> EventLoopFuture<Response> {
        return try req.parameters.next(DBRecipe.self).flatMap { recipe in
            return try recipe.resolve(on: req).flatMap({ recipe in
                return Responder(of: recipe, "found").respond(to: req)
            })
        }
    }
    
    /// Returns a list of all `Recipe`s.
    func fetchAll(_ req: Request) throws -> EventLoopFuture<Response> {
        return DBRecipe.query(on: req).all().flatMap { dbrecipes in
            
            if dbrecipes.count == 0 {
                throw RecipeError.noRecipesFound
            }
            
            return try dbrecipes.map { dbrecipe in
                return try dbrecipe.resolve(on: req)
            }.flatten(on: req).flatMap { recipes in
                return Responder(of: recipes, "\(recipes.count) recipes found").respond(to: req)
            }
        }
    }
    
    /// Deletes a parameterized `Recipe`.
    func delete(_ req: Request) throws -> EventLoopFuture<Response> {
        return try req.parameters.next(DBRecipe.self).flatMap { recipe in
            return try recipe.resources.query(on: req).all().flatMap { resources in
                
                for r in resources {
                    _ = r.delete(on: req)
                }
                
                return recipe.delete(on: req).flatMap { (_) in
                    return Responder<String>("recipe was deleted succesfully").respond(to: req)
                }
            }
        }
    }
}
