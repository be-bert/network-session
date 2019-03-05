
import Foundation

public class FormDataSerialization {
    
    public enum SerializationError: Error {
        case failedConverting
    }
    
    public static func data(fromFormData params: [String: Any]) throws -> Data {
        var formStrings = [String]()
        for(key, value) in params
        {
            formStrings.append(key + "=\(value)")
        }
        let combinedString = formStrings.map { String($0) }.joined(separator: "&")
        if let data = combinedString.data(using: .utf8) {
            return data
        } else {
            throw SerializationError.failedConverting
        }
    }
    
}

public class MultiPartFormDataSerialization {
    
   public struct MultiFormData {
        let data: Data
        let name: String
        let fileName: String
        let mimeType: String
    }
    
    public static func data(fromMultiForData formDatum: [MultiFormData], withParameters params: [String: String]?) -> Data {
        
        let bodyData = NSMutableData()
        
        let boundary = "--\(UUID().uuidString)\r\n"
        
        if let params = params {
            for (key, value) in params {
                bodyData.appendString(boundary)
                bodyData.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                bodyData.appendString("\(value)\r\n")
            }
        }
        
        for formData in formDatum {
            bodyData.appendString(boundary)
            bodyData.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(formData.fileName)\"\r\n")
            bodyData.appendString("Content-Type: \(formData.mimeType)\r\n\r\n")
            bodyData.append(formData.data)
            bodyData.appendString("\r\n")
            bodyData.appendString("--".appending(boundary.appending("--")))
        }
       
        
        return bodyData as Data
    }
}
