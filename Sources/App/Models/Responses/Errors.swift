import Vapor

enum RecipeError: AbortError {
    
    case createWithSpecificId
    case noRecipesFound
    case duplicateTitle(title: String)
    case illegalContent
    case deleteNonexistant(id: Int)
    
    
    
    var identifier: String {
        get {
            return "RecipeError.\(reason)"
        }
    }
    
    
    var status: HTTPResponseStatus {
        get {
            switch self {
            case .createWithSpecificId, .duplicateTitle:
                return .conflict
            case .noRecipesFound:
                return .ok
            case .illegalContent, .deleteNonexistant:
                return .badRequest
            }
        }
    }
    
    var reason: String{
        get {
            switch self {
            case .createWithSpecificId:
                return "cannot create recipe with specific id"
            case .noRecipesFound:
                return "no recipes found"
            case let .duplicateTitle(title):
                return "recipe with title \(title) already exists"
            case .illegalContent:
                return "illegal content for recipe"
            case let .deleteNonexistant(id):
                return "recipe with id \(id) did not exist"
            }
        }
    }
}

enum StoreError: AbortError {
    
    case noItems
    case outOf(item: String)
    
    var identifier: String {
        get {
            return "StoreError.\(reason)"
        }
    }
    
    var status: HTTPResponseStatus {
        get {
            switch self {
            case .noItems:
                return .ok
            case .outOf:
                return .imUsed
            }
        }
    }
    
    var reason: String {
        get {
            switch self {
            case .noItems:
                return "no items found"
            case let .outOf(item):
                return "not enough \(item) available"
            }
        }
    }
    
}
