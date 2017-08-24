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
        
        guard let identifiedItem = self.identifyItem(item) else {
            finishWithFailure(error: DEUploadError.unrecognizableExtensionItem)
            return
        }
        
        self.prepareItem(identifiedItem: identifiedItem)
    }
    
    private enum IdentificationResult {
        case urlToShareInfo(SharingURL)
        case remoteUrl(NSItemProvider)
        case plainText(NSItemProvider)
        case itemAttributedText(NSAttributedString)
        case attachment(item: NSItemProvider, type: DetailedMediaFileType)
    }
    
    private func identifyItem(_ item: NSExtensionItem) -> IdentificationResult? {
        if let sharingUrl = item.sharingUrl {
            return IdentificationResult.urlToShareInfo(sharingUrl)
        }
        
        if let remoteUrlAttachment = item.remoteUrlAttachments.first {
            return IdentificationResult.remoteUrl(remoteUrlAttachment)
        }
        
        if let attachment = item.attachments?.first as? NSItemProvider,
            attachment.hasItemConformingToTypeIdentifier(DEUti.plainText.rawValue) {
            if let text = item.attributedContentText {
                return IdentificationResult.itemAttributedText(text)
            }
            return IdentificationResult.plainText(attachment)
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
            mediaAttachment = item.attachmentsConformingToTypeIdentifier(kUTTypeContent as String).first
            mediaType = .file
        }
        
        if let attachment = mediaAttachment, let type = mediaType {
            return IdentificationResult.attachment(item: attachment, type: type)
        }
        
        return nil
    }
    
    private func prepareItem(identifiedItem: IdentificationResult) {
        switch identifiedItem {
        case .urlToShareInfo(let urlInfo):
            self.finish(item: .init(content: .url(urlInfo.url)))
            
        case .remoteUrl(let urlExtensionItem):
            self.loadRemoteUrl(attachment: urlExtensionItem)
            
        case .attachment(item: let attachment, type: let type):
            self.loadData(attachment: attachment, type: type)
            
        case .plainText(let item):
            self.loadText(attachment: item)
            
        case .itemAttributedText(let attributedString):
            self.finish(item: DEUploadPreparedItem.init(content: .text(attributedString.string)))
        }
    }
    
    private func loadData(attachment: NSItemProvider, type: DetailedMediaFileType) {
        guard !self.isCancelled else {
            return
        }
        
        attachment.loadData(options: nil, onSuccess: { [weak self] itemData in
            switch itemData {
            case .image(let image):
                self?.prepareItem(image: image)
            case .urlData(url: let url, data: let data):
                self?.handleFileDataLoaded(url: url, data: data)
            }
        }, onFailure: { [weak self] error in
            self?.finishWithFailure(error: error)
        })
    }
    
    private func loadText(attachment: NSItemProvider) {
        guard !self.isCancelled else {
            return
        }
        
        attachment.loadItem(forTypeIdentifier: DEUti.plainText.rawValue, options: nil) { (text, error) in
            if let text = text as? String {
                self.finish(item: DEUploadPreparedItem.init(content: .text(text)))
            }
            else {
                let targetError = error ?? DEUploadError.unrecognizableExtensionItem
                self.finishWithFailure(error: targetError)
            }
        }
    }
    
    private func prepareItem(image: UIImage) {
        guard let encodedImage = self.encodeImage(image) else {
            self.finishWithFailure(error: DEUploadError.fileLengthExceedsMaximum)
            return
        }
        
        let dataRep = DEUploadDataRepresentation.init(data: encodedImage.data,
                                                      uti: encodedImage.format.uti.rawValue)
        let details = self.getImageDetails(image)
        let uploadReap = DEUploadImageRepresentation.init(dataRepresentation: dataRep, details: details)
        
        let preview = self.buildPreviewRepresentation(original: image)
        
        // Guaranteed, otherwise encoding failed
        let fileExtension = encodedImage.format.uti.fileExtension!
        let name = self.generateName(prefix:"image_").appending(".").appending(fileExtension)
        
        let item = DEUploadPreparedItem.init(content: .image(uploadReap), preview: preview, originalName: name)
        self.finish(item: item)
    }
    
    private func generateName(prefix: String = "") -> String {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "YYYY-MM-dd-HH-mm"
        let base = formatter.string(from: Date())
        return prefix.appending(base)
    }
    
    private struct EncodedImage {
        var data: Data
        var format: Format
        
        enum Format {
            case png
            case jpeg
            
            var uti: DEUti {
                switch self {
                case .png: return .png
                case .jpeg: return .jpeg
                }
            }
            
        }
    }
    
    private func encodeImage(_ image: UIImage) -> EncodedImage? {
        if let data = UIImagePNGRepresentation(image) {
            return .init(data: data, format: .png)
        }
        if let data = UIImageJPEGRepresentation(image, 1.0) {
            return .init(data: data, format: .jpeg)
        }
        return nil
    }
    
    private func loadRemoteUrl(attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (item, error) in
            
            guard !self.isCancelled else {
                return
            }
            
            if let item = item {
                func finish(url: URL) {
                    self.finish(item: .init(content: .url(url)))
                }
                
                func finish(string: String) {
                    if let url = URL.init(string: string) {
                        finish(url: url)
                    }
                    else {
                        self.finish(item: .init(content: .text(string)))
                    }
                }
                
                func finish(data: Data) {
                    if let string = String(data: data, encoding: .utf8) {
                        finish(string: string)
                    }
                    self.finishWithFailure(error: DEUploadError.unexpectedUrlContent)
                }
                
                
                switch item {
                case let url as URL: finish(url: url)
                case let link as String: finish(string: link)
                case let data as Data: finish(data: data)
                default: self.finishWithFailure(error: DEUploadError.unrecognizableExtensionItem)
                }
            }
            else {
                self.finishWithFailure(error: error)
            }
            
        }
    }
    
    private func handleFileDataLoaded(url: URL, data: Data) {
        guard self.targetType != .file else {
            let name = url.lastPathComponent.isEmpty ? nil : url.lastPathComponent
            
            let mimeTypeRepresentableType = self.attachment.mimeRepresentableTypeIdentifiers.first
            
            /// Ho to define most specific UTI? Like when pdf-file has "public.file-url" and "comp.adobe.pdf" UTIs?
            let mostSpecificUti =  mimeTypeRepresentableType ?? self.attachment.registeredTypeIdentifiers.first as! String
            let item = DEUploadPreparedItem.init(content: .bytes(.init(data: data, uti: mostSpecificUti)),
                                                 originalName: name)
            self.finish(item: item)
            return
        }
        
        loadMedia(url: url, data: data)
    }
    
    private func loadMedia(url: URL, data: Data) {
        
        self.loadedData = data
        
        if !url.lastPathComponent.isEmpty {
            self.proposedFilename = url.lastPathComponent
        }
        
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
    
    private func finish(item: DEUploadPreparedItem) {
        self.finish(result: DLGAsyncOperationResult.success(item))
    }
    
    private func finishIfMediaLoaded() {
        guard self.doesPreviewLoadingFinished,
            let data = self.loadedData,
            let details = self.loadedDetails,
            !self.isCancelled else {
                return
        }
        
        let content: DEUploadPreparedItem.Content = self.buildContent(data: data, details: details)
        let item = DEUploadPreparedItem.init(content: content,
                                             preview: self.loadedPreview,
                                             originalName: self.proposedFilename)
        
        finish(item: item)
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
    
    private func getImageDetails(_ image: UIImage) -> DEUploadImageDetails {
        let size = DEUploadIntegerSize.init(size: image.pixelSize)
        let details = DEUploadImageDetails.init(size: size)
        return details
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
    
    private var proposedFilename: String? = nil
    
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
