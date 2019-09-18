import Vapor


struct Wrapper<T: Content>: Content {
    var message: String?
    
    var data: T?
    
    init(of data: T? = nil, _ message: String? = nil) {
        self.data = data
        self.message = message
    }
}

struct Responder<T: Content> {
    
    var wrapper: Wrapper<T>
    
    var status: HTTPStatus
    
    init(of data: T? = nil, _ message: String? = nil, with status: HTTPStatus = .ok) {
        self.status = status
        self.wrapper = Wrapper(of: data, message)
    }
    
    func respond(to request: Request) -> EventLoopFuture<Response> {
        return wrapper.encode(status: status, for: request)
    }
}
