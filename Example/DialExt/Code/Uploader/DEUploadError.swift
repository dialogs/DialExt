import Foundation

public enum DEUploadError: Error {
    
    /// Trying to upload too many items
    case tooManyItems
    
    /// Uploading file size is too big
    case fileLengthExceedsMaximum
    
    /// Nothing to upload
    case noItemsToUpload
    
    /// Authorization info is invalid
    case invalidAuthInfo
    
    /// Uploading now (for single-item workers only)
    case busy
    
    case unrecognizableExtensionItem
    
    public var localizedDescription: String {
        switch self {
        case .tooManyItems: return "Items limit exceeded"
        case .noItemsToUpload: return "No items to upload"
        case .invalidAuthInfo: return "Invalid authorization info"
        case .busy: return "Already uploading now"
        case .unrecognizableExtensionItem: return "Could not recognize sharing item"
        case .fileLengthExceedsMaximum:
            return NSError(domain: NSURLErrorDomain, code: NSURLErrorDataLengthExceedsMaximum, userInfo: nil).localizedDescription
        }
    }
    
}
