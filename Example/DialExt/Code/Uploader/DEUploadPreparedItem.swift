import Foundation

public class DEUploadPreparedItem {
    
    public let content: Content
    
    public var mediaFileRepresented : MediaFile? {
        
        switch self.content {
        case let .image(file): return file
        case let .video(file): return file
        case let .mediaFile(file): return file
        case let .bytes(data): return MediaFile.init(data: data)
            
        default: return nil
        }
    }
    
    public var messageRepresentable: String? {
        switch self.content {
        case let .url(url): return url.absoluteString
        case let .text(text): return text
        default: return nil
        }
    }
    
    public init(content: Content) {
        self.content = content
    }
    
    public enum Content {
        
        case image(MediaFile)
        
        case video(MediaFile)
        
        case mediaFile(MediaFile)
        
        case url(URL)
        
        case text(String)
        
        case bytes(Data)
        
    }
    
    public class MediaFile {
        
        public let file: HttpRequestFormDataRepresentation
        
        public let preview: HttpRequestFormDataRepresentation?
        
        public var allHttpRequestFormDataRepresentationItems: [HttpRequestFormDataRepresentation] {
            var items: [HttpRequestFormDataRepresentation] = []
            items.append(file)
            if let preview = self.preview {
                items.append(preview)
            }
            return items
        }
        
        public var previewable: Bool {
            return preview != nil
        }
        
        public func update(byPreview: HttpRequestFormDataRepresentation?) -> MediaFile {
            return MediaFile.init(file: self.file, preview: byPreview)
        }
        
        public init(file: HttpRequestFormDataRepresentation, preview: HttpRequestFormDataRepresentation? = nil) {
            self.file = file
            self.preview = preview
        }
        
        convenience public init(data: Data) {
            self.init(file: HttpRequestFormDataRepresentation.init(data: data))
        }
        
    }
    
    public class HttpRequestFormDataRepresentation {
        
        public let mimeType: String
        
        public var size: CGSize? = nil
        
        public let data: Data
        
        public let fileExtension: String?
        
        public init(mimeType: String, data: Data, fileExtension: String? = nil) {
            self.mimeType = mimeType
            self.data = data
            self.fileExtension = fileExtension
        }
        
        convenience public init(data: Data) {
            self.init(mimeType: "application/octet-stream", data: data)
        }
        
    }
    
}
