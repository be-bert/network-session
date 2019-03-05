
import Foundation

public class MultiPartFormDataSerialization {
    
    public struct MultiFormData {
        
        let data: Data
        let name: String
        let fileName: String
        let mimeType: String
        
        public init(data: Data, name: String, fileName: String, mimeType: String) {
            self.data = data
            self.name = name
            self.fileName = fileName
            self.mimeType = mimeType
        }
        
    }
    
    public static func data(fromMultiForData formDatum: [MultiFormData], boundary: String, withParameters params: [String: String]?) -> Data {
        
        let bodyData = NSMutableData()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        if let params = params {
            for (key, value) in params {
                bodyData.appendString(boundaryPrefix)
                bodyData.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                bodyData.appendString("\(value)\r\n")
            }
        }
        
        for formData in formDatum {
            bodyData.appendString(boundaryPrefix)
            bodyData.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(formData.fileName)\"\r\n")
            bodyData.appendString("Content-Type: \(formData.mimeType)\r\n\r\n")
            bodyData.append(formData.data)
            bodyData.appendString("\r\n")
            bodyData.appendString("--".appending(boundary.appending("--")))
        }
        
        
        return bodyData as Data
    }
}
