
import Foundation
import MobileCoreServices

public protocol NetworkSession {
    
    func post(to path: String, params: [String: String]?, headers: [String: String]?, body: Data?, completion: @escaping (Result<Data, Error>) -> Void)
    func backgroundPost(to path: String, params: [String : String]?, headers: [String : String]?, body: Data) throws
}

public enum URLError: Error {
    
    case incorrectPath(_ path: String)
    case noUrl
    case unacceptableStatusCode(_ code: Int)
    
}

extension URLSession: NetworkSession {
    
    public func post(to path: String, params: [String : String]?, headers: [String : String]?, body: Data?, completion: @escaping (Result<Data, Error>) -> Void) {
        var urlComponents: URLComponents!
        do {
            urlComponents = try configureURLComponents(path: path, params: params)
        } catch {
            completion(Result.failure(error))
            return
        }
        
        var request: URLRequest!
        do {
            request = try configureRequest(urlComponents: urlComponents)
        } catch {
            completion(Result.failure(error))
            return
        }
        
        configureHeaders(headers: headers, request: &request)
        
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
    
    public func backgroundPost(to path: String, params: [String : String]?, headers: [String : String]?, body: Data) throws {
        
        var urlComponents: URLComponents!
        do {
            urlComponents = try configureURLComponents(path: path, params: params)
        } catch {
            throw error
        }
        
        var request: URLRequest!
        do {
            request = try configureRequest(urlComponents: urlComponents)
        } catch {
           throw error
        }
        
        configureHeaders(headers: headers, request: &request)
        
        let tempDir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.dreamhousedesign.DreamHouseDesign")
        let localURL = tempDir!.appendingPathComponent(UUID().uuidString)
        try! body.write(to: localURL)

        let task = uploadTask(with: request, fromFile: localURL)
        task.resume()
    }
    
    // MARK: private methods
    
    func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data,
                    mimeType: String,
                    filename: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        
        return body as Data
    }
    
    
    private func mimeType(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    
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
    
    func configureRequest(urlComponents: URLComponents) throws -> URLRequest  {
        guard let url = urlComponents.url else {
            throw URLError.noUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        return request
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
