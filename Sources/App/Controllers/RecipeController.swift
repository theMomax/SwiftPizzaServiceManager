import Vapor
import FluentMySQL

/// Controls basic CRUD operations on `Recipe`s.
final class RecipeController: RouteCollection {
    
    /// Registers handlers
    func boot(router: Router) throws {
        let v1 = router.grouped("api/v1")
        
        v1.put("recipe", use: create)
        v1.put(Recipe.self, at: "recipe", DBRecipe.parameter, use: update)
        v1.get("recipe", DBRecipe.parameter, use: fetch)
        v1.get("recipe", use: fetchAll)
        v1.delete("recipe", DBRecipe.parameter, use: delete)
    }
    
    
    /// Saves a decoded `Recipe` to the database.
    func create(_ req: Request) throws -> Future<Wrapper<Int>> {
        return try req.content.decode(Recipe.self).flatMap(to: (DBRecipe?, Recipe).self, { recipe in
            guard recipe.id == nil else {
                throw RecipeError.createWithSpecificId
            }
            
            guard recipe.title != "" && recipe.resources.count > 0 else {
                throw RecipeError.illegalContent
            }
            
            return DBRecipe.query(on: req).filter(\DBRecipe.title == recipe.title).first().and(result: recipe)
        }).flatMap(to: (DBRecipe, Recipe).self, { (duplicate, recipe) in
            guard duplicate == nil else {
                throw RecipeError.duplicateTitle(title: recipe.title)
            }
            
            let dbrecipe: DBRecipe = DBRecipe(title: recipe.title)
            
            return dbrecipe.create(on: req).and(result: recipe)
        }).map(to: Wrapper<Int>.self,  { (dbrecipe, recipe) in
            
            for r in recipe.resources {
                let dbresource = DBResource(name: r.name, amount: r.amount, recipeID: dbrecipe.id)
                _ = dbresource.save(on: req)
            }
            
            return Wrapper(of: dbrecipe.id!, with: .created)
        })
    }
    
    /// Updates a decoded `Recipe` on the database.
    func update(_ req: Request, recipe: Recipe) throws -> Future<Wrapper<Int>> {
        return try req.parameters.next(DBRecipe.self).flatMap(to: (DBRecipe, Recipe).self, { dbrecipe in
            recipe.id = dbrecipe.id
            
            guard recipe.title != "" && recipe.resources.count > 0 else {
                throw RecipeError.illegalContent
            }
            
            dbrecipe.title = recipe.title
            _ = try dbrecipe.resources.query(on: req).all().map({ resources in
                for r in resources {
                    _ = r.delete(on: req)
                }
            })
            
            return dbrecipe.update(on: req).and(result: recipe)
        }).map { (dbrecipe, recipe) in
            
            for r in recipe.resources {
                let dbresource = DBResource(name: r.name, amount: r.amount, recipeID: dbrecipe.id)
                _ = dbresource.save(on: req)
            }
            
            return Wrapper(of: dbrecipe.id)
        }
    }
    
    /// Returns the requested `Recipe`.
    func fetch(_ req: Request) throws -> Future<Wrapper<Recipe>> {
        return try req.parameters.next(DBRecipe.self).flatMap { recipe in
            return try recipe.public(on: req)
        }.map { recipe in
            return Wrapper(of: recipe, "found")
        }
    }
    
    /// Returns a list of all `Recipe`s.
    func fetchAll(_ req: Request) throws -> Future<Wrapper<[Recipe]>> {
        return DBRecipe.query(on: req).all().flatMap { dbrecipes in
            
            guard dbrecipes.count > 0 else {
                throw RecipeError.noRecipesFound
            }
            
            return try dbrecipes.map { dbrecipe in
                return try dbrecipe.public(on: req)
            }.flatten(on: req).map { recipes in
                return Wrapper(of: recipes, "\(recipes.count) recipes found")
            }
        }
    }
    
    /// Deletes a parameterized `Recipe`.
    func delete(_ req: Request) throws -> Future<Wrapper<V>> {
        return try req.parameters.next(DBRecipe.self).flatMap(to: ([DBResource], DBRecipe).self, { recipe in
            return try recipe.resources.query(on: req).all().and(result: recipe)
        }).flatMap { (resources, recipe) in
            
            for r in resources {
                _ = r.delete(on: req)
            }
            
            return recipe.delete(on: req)
        }.map { () in
            return Wrapper<V>("recipe was deleted succesfully")
        }
    }
}
