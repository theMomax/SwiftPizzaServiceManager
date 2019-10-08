import Vapor
import Fluent
import FluentMySQL


protocol PriceCalculator {
    
    func price(of recipeID: Int) throws -> Future<Double>
}

class MockPriceCalculator: PriceCalculator {
    
    init(on container: Container) {
        self.con = container
    }
    
    var con: Container
    
    func price(of recipeID: Int) throws -> Future<Double> {
        return con.eventLoop.newSucceededFuture(result: 0.0)
    }
}


extension MockPriceCalculator: Service { }


class FixedPriceCalculator: PriceCalculator {
    
    init(on container: Container) {
        self.con = container
    }
    
    var con: Container
    
    func price(of recipeID: Int) throws -> Future<Double> {
        return con.eventLoop.newSucceededFuture(result: 7.0)
    }
}


extension FixedPriceCalculator: Service { }

class NormalPriceCalculator: PriceCalculator {
    
    init(on container: Container) {
        self.con = container
    }
    
    var con: Container
    
    func price(of recipeID: Int) throws -> Future<Double> {
        return con.withNewConnection(to: .mysql) { conn in
            return DBRecipe.query(on: conn).filter(\DBRecipe.id == recipeID).first().flatMap { rOpt in
                if let dbrecipe = rOpt {
                    return try dbrecipe.public(on: conn).map{ recipe in
                        var price = 0.0
                        for r in recipe.resources {
                            price += r.amount
                        }
                        return price
                    }
                } else {
                    throw Abort(.badRequest, reason: "invalid id \(recipeID)")
                }
            }
        }
    }
}


extension NormalPriceCalculator: Service { }
