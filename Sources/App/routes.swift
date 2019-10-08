import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {    
    try RecipeController().boot(router: router)
    try ResourceController().boot(router: router)
    try PriceController().boot(router: router)
}
