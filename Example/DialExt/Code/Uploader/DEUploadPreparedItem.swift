import Foundation
import MobileCoreServices

/**
 * Describes item providing full information for uploading
 */
public class DEUploadPreparedItem {

    /**
     * Contains fully prepared content
     */
    public let content: Content
    
    public let originalName: String?
    
    public init(content: Content, preview: DEUploadImageRepresentation? = nil, originalName: String? = nil) {
        self.content = content
        self.preview = preview
        self.originalName = originalName
    }
    
    var messageRepresentable: String? {
        switch self.content {
        case let .url(url): return url.absoluteString
        case let .text(text): return text
        default: return nil
        }
    }
    
    public var dataRepresentation: DEUploadDataRepresentation? {
        switch self.content {
        case let .image(image): return image.dataRepresentation
        case let .video (video): return video.dataRepresentation
        case let .audio(audio): return audio.dataRepresentation
        case let .bytes(bytes): return bytes
        default: return nil
        }
    }
    
    public func proposeName(baseBuilder:(()->(String))) -> String {
        if let name = self.originalName {
            return name
        }
        
        let name = baseBuilder()
        let filename = self.content.proposedFilename(base: baseBuilder())
        return filename ?? name
    }
    
    var preview: DEUploadImageRepresentation?
    
    public enum Content {
        
        case image(DEUploadImageRepresentation)
        
        case video(DEUploadVideoRepresentation)
        
        case audio(DEUploadAudioRepresentation)
        
        case bytes(DEUploadDataRepresentation)
        
        case url(URL)
        
        case text(String)
                
        public func proposedFilename(base: String) -> String? {
            switch self {
            case let .image(rep): return rep.filename(base: base)
            case let .video(rep): return rep.filename(base: base)
            case let .audio(rep): return rep.filename(base: base)
            case let .bytes(rep): return rep.filename(base: base)
            default: return nil
            }
        }
    }
    
}
