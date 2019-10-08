import Vapor

struct V: Content { }

struct Wrapper<T: Content>: ResponseEncodable {
    
    private struct Container<T: Content>: Content {
        var message: String?
        
        var data: T?
        
        init(of data: T? = nil, _ message: String? = nil) {
            self.data = data
            self.message = message
        }
    }
    
    private var container: Container<T>
    
    var status: HTTPStatus
    
    init(of data: T? = nil, _ message: String? = nil, with status: HTTPStatus = .ok) {
        self.status = status
        self.container = Container(of: data, message)
    }
    
    func encode(for request: Request) -> EventLoopFuture<Response> {
        return container.encode(status: status, for: request)
    }
}
