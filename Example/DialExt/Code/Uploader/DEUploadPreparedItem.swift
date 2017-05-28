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
    
    public init(content: Content, preview: DEUploadImageRepresentation? = nil) {
        self.content = content
        self.preview = preview
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
    
    var preview: DEUploadImageRepresentation?
    
    public enum Content {
        
        case image(DEUploadImageRepresentation)
        
        case video(DEUploadVideoRepresentation)
        
        case audio(DEUploadAudioRepresentation)
        
        case bytes(DEUploadDataRepresentation)
        
        case url(URL)
        
        case text(String)
        
        public func proposedFilename(idx: Int) -> String? {
            switch self {
            case let .image(rep): return rep.filename(base: "image_\(idx)")
            case let .video(rep): return rep.filename(base: "video_\(idx)")
            case let .audio(rep): return rep.filename(base: "audio_\(idx)")
            case .bytes(_): return "file_\(idx)"
            default: return nil
            }
        }
    }
    
}
