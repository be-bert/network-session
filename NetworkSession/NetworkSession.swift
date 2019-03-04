
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
        
        
        var request = URLRequest(url: URL(string: path)!)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        configureHeaders(headers: headers, request: &request)
        
        let filename = "hello.jpg"
//
//        let boundaryPrefix = "--\(boundary)\r\n"
//
        let mimeType = "image/jpg"
//
//        var bodyString = ""
//
//        if let headers = headers {
//            for (key, value) in headers {
//                bodyString += boundaryPrefix
//                bodyString += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
//                bodyString += "\(value)\r\n"
//            }
//        }
//
//
//        bodyString += boundaryPrefix
//        bodyString += "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n"
//        bodyString += "Content-Type: \(mimeType)\r\n\r\n"
//        let image = UIImage(data: body)
//        let jpgData = image?.jpegData(compressionQuality: 80)?.base64EncodedData()
//
//        bodyString += String(data: jpgData!, encoding: .utf8)!
//        bodyString += "\r\n"
//        bodyString += "--".appending(boundary.appending("--"))
        
//        let data = bodyString.data(using: .utf8)
        
        let data = createBody(parameters: [:], boundary: boundary, data: body, mimeType: mimeType, filename: filename)
        
        let tempDir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.dreamhousedesign.DreamHouseDesign")//FileManager.default.temporaryDirectory
        let localURL = tempDir!.appendingPathComponent("throwaway2")
        try! data.write(to: localURL)

        
//        var bodyString = ""
//
//        var filePathKey = "file"
//
//        let boundary = "Boundary-\(UUID().uuidString)"
//
//        if let headers = headers {
//            for (key, value) in headers {
//                bodyString += "--\(boundary)\r\n"
//                bodyString += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
//                bodyString += "\(value)\r\n"
//            }
//        }
//
//        var tempDir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.dreamhousedesign.DreamHouseDesign") //FileManager.default.temporaryDirectory
//        let localURL = tempDir!.appendingPathComponent("throwaway")
//        try! body.write(to: localURL)
//
//        let urls = [localURL]
//
//        for url in urls {
//            let filename = url.lastPathComponent
//            let data = try Data(contentsOf: url)
//            let mimetype = mimeType(for: path)
//
//            bodyString += "--\(boundary)\r\n"
//            bodyString += "Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n"
//            bodyString += "Content-Type: \(mimetype)\r\n\r\n"
//            bodyString += data.base64EncodedString()  //UIImage(data: body) //String(decoding: data, as: UTF8.self)
//            bodyString += "\r\n"
//        }
//
//        bodyString += "--\(boundary)--\r\n"
//
//        let data = bodyString.data(using: .utf8)!
//
//        var request = URLRequest(url: URL(string: path)!)
//        request.httpMethod = "POST"
//        request.httpBody = data
     /////////////////////////////////////
//
//        var urlComponents: URLComponents!
//        do {
//            urlComponents = try configureURLComponents(path: path, params: params)
//        } catch {
//            throw error
//        }
//
//        var request: URLRequest!
//        do {
//            request = try configureRequest(urlComponents: urlComponents)
//        } catch {
//            throw error
//        }
//
//        configureHeaders(headers: headers, request: &request)
//
//        let tempDir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.dreamhousedesign.DreamHouseDesign")//FileManager.default.temporaryDirectory
//        let localURL = tempDir!.appendingPathComponent("throwaway2")
//        try! body.write(to: localURL)
//
        let task = uploadTask(with: request, fromFile: localURL)
        task.resume()
    }
    
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
                request.addValue(value, forHTTPHeaderField: key)
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
