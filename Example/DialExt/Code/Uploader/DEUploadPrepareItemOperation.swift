//
//  DEUploadPrepareItemOperation.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 27/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import MobileCoreServices
import AVFoundation
import ImageIO

public class DEUploadPrepareItemOperation: DLGAsyncOperation<DEUploadPreparedItem> {
    
    public let extensionItem: NSExtensionItem
    
    public let config: Config
    
    public struct Config {
        
        public static let `default` = Config()
        
        var previewOutput: PreviewOutput = .jpg(compression: 0.8)
        
        public enum PreviewOutput {
            case png
            case jpg(compression: CGFloat)
        }
        
    }
    
    public init(extensionItem: NSExtensionItem, config: Config = Config.default) {
        self.extensionItem = extensionItem
        self.config = config
    }
    
    public override func onDidStart() {
        
        let item = self.extensionItem
        
        if let sharingUrl = item.sharingUrl {
            let preparedItem = DEUploadPreparedItem.init(content: .url(sharingUrl.url))
            finish(result: DLGAsyncOperationResult.success(preparedItem))
            return
        }
        
        var mediaAttachment: NSItemProvider? = nil
        var mediaType: DetailedMediaFileType? = nil
        
        if mediaAttachment == nil, let videoAttachment = item.videoAttachments.first {
            mediaAttachment = videoAttachment
            mediaType = .video
        }
        
        if mediaAttachment == nil, let imageAttachment = item.imageAttachments.first {
            mediaAttachment = imageAttachment
            mediaType = .image
        }
        
        if mediaAttachment == nil, let audioAttachment = item.audioAttachments.first {
            mediaAttachment = audioAttachment
            mediaType = .audio
        }
        
        if mediaAttachment == nil {
            mediaAttachment = item.attachmentsWithTypeIdentifier(kUTTypeContent as String).first
            mediaType = .file
        }
        
        if let attachment = mediaAttachment, let type = mediaType {
            self.attachment = attachment
            self.targetType = type
            self.loadFileData()
        }
        else {
            finishWithFailure(error: DEUploadError.unrecognizableExtensionItem)
        }
        
    }
    
    private func loadFileData() {
        self.attachment.loadData(options: nil) { [weak self] (result) in
            withOptionalExtendedLifetime(self, body: {
                guard !self!.isCancelled else {
                    return
                }
                
                switch result {
                case let .failure(error):
                    self!.finishWithFailure(error: error)
                    break
                case let .success(url: url, data: data):
                    self!.handleFileDataLoaded(url: url, data: data)
                    break
                }
            })
        }
    }
    
    private func handleFileDataLoaded(url: URL, data: Data) {
        guard self.targetType != .file else {
            let mostSpecificUti = self.attachment.registeredTypeIdentifiers.first as! String
            let item = DEUploadPreparedItem.init(content: .bytes(.init(data: data, uti: mostSpecificUti)))
            self.finish(result: DLGAsyncOperationResult.success(item))
            return
        }
        
        loadMedia(url: url, data: data)
    }
    
    private func loadMedia(url: URL, data: Data) {
        
        self.loadedData = data
        
        loadPreview(onLoaded: { [weak self ] rep in
            withOptionalExtendedLifetime(self, body: {
                self!.loadedPreview = rep
                self!.doesPreviewLoadingFinished = true
            })
        })
        
        switch self.targetType! {
        case .image:
            self.loadImageDetails(url: url, data: data, onLoaded: { [weak self] details in
                withOptionalExtendedLifetime(self, body: {
                    self!.loadedDetails = .image(details)
                })
            })
        case .video:
            self.loadVideoDetails(url: url, data: data, onLoaded: { [weak self] (details) in
                withOptionalExtendedLifetime(self, body: {
                    self!.loadedDetails = .video(details)
                })
            })
        case .audio:
            self.loadAudioDetails(url: url, data: data, onLoaded: { [weak self] (details) in
                withOptionalExtendedLifetime(self, body: {
                    self!.loadedDetails = .audio(details)
                })
            })
        default:
            fatalError()
        }
    }
    
    private func buildContent(data: Data, details: LoadedDetails) -> DEUploadPreparedItem.Content {
        let fileRep = DEUploadDataRepresentation.init(data: self.loadedData!,
                                                      mimeType: self.attachment.supposedMimeType!,
                                                      fileExtension: self.attachment.supposedFileExtension!)
        
        
        let content: DEUploadPreparedItem.Content
        switch self.loadedDetails! {
        case let .audio(details):
            content = .audio(DEUploadAudioRepresentation.init(dataRepresentation: fileRep, details: details))
        case let .video(details):
            content = .video(DEUploadVideoRepresentation.init(dataRepresentation: fileRep, details: details))
        case let .image(details):
            content = .image(DEUploadImageRepresentation.init(dataRepresentation: fileRep, details: details))
        }
        return content
    }
    
    private func finishIfMediaLoaded() {
        guard self.doesPreviewLoadingFinished,
            let data = self.loadedData,
            let details = self.loadedDetails,
            !self.isCancelled else {
                return
        }
        
        let content: DEUploadPreparedItem.Content = self.buildContent(data: data, details: details)
        let item = DEUploadPreparedItem.init(content: content, preview: self.loadedPreview)
        
        finish(result: DLGAsyncOperationResult.success(item))
    }
    
    private func loadVideoDetails(url: URL, data: Data, onLoaded:@escaping ((DEUploadVideoDetails) -> ())) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVURLAsset.init(url: url)
            let duration = Int(asset.duration.seconds)
            let size = asset.tracks(withMediaType: AVMediaTypeVideo).first!.naturalSize
            let integerSize = DEUploadIntegerSize.init(size: size)
            let details = DEUploadVideoDetails.init(size: integerSize, durationInSeconds: duration)
            DispatchQueue.main.async {
                onLoaded(details)
            }
        }
    }
    
    /// Callback performed on main thread
    private func loadPreview(onLoaded: @escaping ((DEUploadImageRepresentation?) -> ()) ) {
        self.attachment.loadPreviewImage(options: nil, completionHandler: {[weak self] value, error in
            withOptionalExtendedLifetime(self, body: {
                guard !self!.isCancelled else {
                    return
                }
                
                var image: UIImage? = nil
                
                switch value {
                case let valueImage as UIImage: image = valueImage
                case let data as Data: image = UIImage.init(data: data)!
                case let url as URL: image = UIImage.init(contentsOfFile: url.path)!
                default: break
                }
                
                if let previewImage = image {
                    let optimizedImage = previewImage.limited(bySize: .init(width: 90.0, height: 90.0))
                    let previewRep = self!.buildPreviewRepresentation(original: optimizedImage)
                    DispatchQueue.main.async {
                        onLoaded(previewRep)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        onLoaded(nil)
                    }
                }
                
            })
        })
    }
    
    private func buildPreviewRepresentation(original: UIImage) -> DEUploadImageRepresentation {
        let data: Data
        let utType: String
        let size = DEUploadIntegerSize.init(size: original.pixelSize)
        
        switch self.config.previewOutput {
        case .png:
            data = UIImagePNGRepresentation(original)!
            utType = kUTTypePNG as String
        case let .jpg(compression):
            data = UIImageJPEGRepresentation(original, compression)!
            utType = kUTTypeJPEG as String
        }
        
        let details = DEUploadImageDetails.init(size: size)
        let dataRep = DEUploadDataRepresentation.init(data: data, uti: utType)
        let rep = DEUploadImageRepresentation.init(dataRepresentation: dataRep, details: details)
        return rep
    }
    
    private func loadImageDetails(url: URL, data: Data, onLoaded: @escaping ((DEUploadImageDetails) -> ())) {
        DispatchQueue.global(qos: .background).async {
            let image = UIImage.init(data: data)!
            let size = DEUploadIntegerSize.init(size: image.pixelSize)
            let details = DEUploadImageDetails.init(size: size)
            DispatchQueue.main.async {
                onLoaded(details)
            }
        }
    }
    
    private func loadAudioDetails(url: URL, data: Data, onLoaded: @escaping ((DEUploadAudioDetails) -> ())) {
        DispatchQueue.global(qos: .background).async {
            var duration: Int = 0
            do {
                let player = try AVAudioPlayer.init(contentsOf: url)
                let fetchedDuration = player.duration
                duration = Int(fetchedDuration)
            }
            catch {
                print("Fail to load sound for define duration: \(error)")
            }
            let details = DEUploadAudioDetails.init(durationInSeconds: duration)
            DispatchQueue.main.async {
                onLoaded(details)
            }
            
        }
    }
    
    private var attachment: NSItemProvider!
    
    private var targetType: DetailedMediaFileType!
    
    private var loadedData: Data? = nil
    
    private var loadedPreview: DEUploadImageRepresentation?
    
    private var doesPreviewLoadingFinished: Bool = false {
        didSet {
            self.finishIfMediaLoaded()
        }
    }
    
    private var loadedDetails: LoadedDetails? = nil {
        didSet {
            self.finishIfMediaLoaded()
        }
    }
    
    private enum LoadedDetails {
        case image(DEUploadImageDetails)
        case video(DEUploadVideoDetails)
        case audio(DEUploadAudioDetails)
    }
    
    private enum DetailedMediaFileType: Int {
        case image
        case video
        case audio
        case file
    }
}
