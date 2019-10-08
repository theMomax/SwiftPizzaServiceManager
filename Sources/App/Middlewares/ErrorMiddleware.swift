import Vapor
import Fluent

extension ErrorMiddleware {
    
    /// Structure of `ErrorMiddleware` default response.
    internal struct ErrorResponse: Codable {
        /// The error message.
        var message: String?
    }
    
    public static func custom(environment: Environment, log: Logger) -> ErrorMiddleware {
        return .init { req, error in
            // log the error
            log.report(error: error, verbose: !environment.isRelease)
            
            // variables to determine
            let status: HTTPResponseStatus
            let reason: String
            let headers: HTTPHeaders
            
            // inspect the error type
            switch error {
            case let abort as AbortError:
                // this is an abort error, we should use its status, reason, and headers
                reason = abort.reason
                status = abort.status
                headers = abort.headers
            case let validation as ValidationError:
                // this is a validation error
                reason = validation.reason
                status = .badRequest
                headers = [:]
            case let fluent as FluentError where fluent.reason.starts(with: "Could not convert parameter"):
                reason = fluent.reason
                status = .badRequest
                headers = [:]
            case let debuggable as Debuggable where !environment.isRelease:
                // if not release mode, and error is debuggable, provide debug
                // info directly to the developer
                reason = debuggable.reason
                status = .internalServerError
                headers = [:]
            default:
                // not an abort error, and not debuggable or in dev mode
                // just deliver a generic 500 to avoid exposing any sensitive error info
                reason = "Something went wrong."
                status = .internalServerError
                headers = [:]
            }
            
            // create a Response with appropriate status
            let res = req.response(http: .init(status: status, headers: headers))
            
            // attempt to serialize the error to json
            do {
                let errorResponse = ErrorResponse(message: reason)
                res.http.body = try HTTPBody(data: JSONEncoder().encode(errorResponse))
                res.http.headers.replaceOrAdd(name: .contentType, value: "application/json; charset=utf-8")
            } catch {
                res.http.body = HTTPBody(string: "Oops: \(error)")
                res.http.headers.replaceOrAdd(name: .contentType, value: "text/plain; charset=utf-8")
            }
            return res
        }
    }
    
}
