import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    let recipeController = RecipeController()
    let v1 = router.grouped("api/v1")
    
    v1.put("recipe", use: recipeController.create)
    v1.put("recipe", DBRecipe.parameter, use: recipeController.update)
    v1.get("recipe", DBRecipe.parameter, use: recipeController.fetch)
    v1.get("recipe", use: recipeController.fetchAll)
    v1.delete("recipe", DBRecipe.parameter, use: recipeController.delete)
    
    let resourceController = ResourceController()
    
    v1.get("store", use: resourceController.fetchAvailable)
    v1.post("refill", use: resourceController.add)
    v1.post("order", DBRecipe.parameter, use: resourceController.order)
}
