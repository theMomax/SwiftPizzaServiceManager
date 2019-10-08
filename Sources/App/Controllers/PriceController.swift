import Vapor
import FluentMySQL

final class PriceController: RouteCollection {
    
    /// Registers handlers
    func boot(router: Router) throws {
        let v1 = router.grouped("api/v1")
        
        v1.get("price", Int.parameter, use: price)
    }
    
    
    func price(_ req: Request) throws -> Future<Wrapper<Double>> {
        return try req.make(PriceCalculator.self).price(of: req.parameters.next(Int.self)).map { price in
            return Wrapper(of: price)
        }
    }
}
