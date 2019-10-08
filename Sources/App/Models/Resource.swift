import FluentMySQL
import Vapor

final class DBResource: MySQLModel {
    
    var id: Int?
    
    var name: String
    
    var amount: Double
    
    var recipeID: Int?
    
    var storeID: Int?
    
    var `public`: Resource {
        return Resource(from: self)
    }
    
    init(id: Int? = nil, name: String, amount: Double, recipeID: Int? = nil, storeID: Int? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.recipeID = recipeID
        self.storeID = storeID
    }
}

/// Allows `DBResource` to be used as a dynamic migration.
extension DBResource: Migration { }

final class Resource {
    var name: String
    var amount: Double
    
    init(name: String, amount: Double) {
        self.name = name
        self.amount = amount
    }
    
    init(from model: DBResource) {
        self.name = model.name
        self.amount = model.amount
    }
}

/// Allows `Resource` to be encoded to and decoded from HTTP messages.
extension Resource: Content { }
