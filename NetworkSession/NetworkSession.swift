
import Foundation

public protocol NetworkSession {
    
    func post(to path: String, params: [String: String]?, headers: [String: String]?, body: Data?, completion: @escaping (Result<Data, Error>) -> Void)
    
}

public enum URLError: Error {
    
    case incorrectPath(_ path: String)
    case noUrl
    case unacceptableStatusCode(_ code: Int)
    
}

extension URLSession: NetworkSession {
    
    public func post(to path: String, params: [String : String]?, headers: [String : String]?, body: Data?, completion: @escaping (Result<Data, Error>) -> Void) {
        
        guard var urlComponents = URLComponents(string: path) else {
            completion(Result.failure(URLError.incorrectPath(path)))
            return
        }
        
        var queryItems = [URLQueryItem]()
        
        if let params = params {
            for (key, value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            completion(Result.failure(URLError.noUrl))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        request.httpBody = body
        
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
    
}
