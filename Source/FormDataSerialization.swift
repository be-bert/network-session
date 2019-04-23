
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
