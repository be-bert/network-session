
import Foundation
import MobileCoreServices

public protocol NetworkSession {
    func post(to path: String, headers: [String: String]?, data: Data?, completion: @escaping (Result<Data, Error>) -> Void)
    func backgroundPost(to path: String, headers: [String: String]?, fileLocation: URL) throws
}

public enum URLError: Error {
    
    case malformedPath(_ path: String)
    case incorrectPath(_ path: String)
    case noUrl
    case unacceptableStatusCode(_ code: Int)
    
}

extension URLSession: NetworkSession {
    
    public func post(to path: String, headers: [String : String]?, data: Data?, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: path) else {
            completion(Result.failure(URLError.malformedPath(path)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        configureHeaders(headers: headers, request: &request)
        
        request.httpBody = data
        
        let task = uploadTask(with: request, from: nil) { (data, response, error) in
            DispatchQueue.main.async {
                if let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) == false {
                    completion(.failure(URLError.unacceptableStatusCode(response.statusCode)))
                }
                else if let data = data {
                    completion(.success(data))
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    public func backgroundPost(to path: String, headers: [String : String]?, fileLocation: URL) throws {
        guard let url = URL(string: path) else {
            throw URLError.malformedPath(path)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        configureHeaders(headers: headers, request: &request)
        
        let task = uploadTask(with: request, fromFile: fileLocation)
        task.resume()
    }
    
    // MARK: private methods
    
    func configureURLComponents(path: String, params: [String : String]?) throws -> URLComponents {
        guard var urlComponents = URLComponents(string: path) else {
            throw URLError.incorrectPath(path)
        }
        
        var queryItems = [URLQueryItem]()
        
        if let params = params {
            for (key, value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        
        urlComponents.queryItems = queryItems
        
        return urlComponents
    }
    
    func configureHeaders(headers: [String : String]?, request: inout URLRequest) {
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
    }
    
}


extension NSMutableData {
    
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
    
}
