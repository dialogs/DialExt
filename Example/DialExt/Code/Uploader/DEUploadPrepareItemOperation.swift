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
        case vcard(NSItemProvider)
        case remoteUrl(NSItemProvider)
        case plainText(NSItemProvider)
        case itemAttributedText(NSAttributedString)
        case attachment(item: NSItemProvider, type: DetailedMediaFileType)
    }
    
    private func identifyItem(_ item: NSExtensionItem) -> IdentificationResult? {
        
        if let vcardProvider = item.firstAttachmentConformingToTypeIdentifier("public.vcard") {
            return IdentificationResult.vcard(vcardProvider)
        }
        
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
            mediaAttachment = item.attachmentsConformingToTypeIdentifier(kUTTypeData as String).first
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
            
        case .vcard(let provider):
            self.loadVcardAsDocument(attachment: provider)
            
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
    
    private func loadVcardAsDocument(attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: "public.vcard", options: nil) { (item, error) in
            if let item = item, let vcardData = item as? Data {
                let rep = DEUploadDataRepresentation.init(data: vcardData, uti: "public.vcard")
                let content = DEUploadPreparedItem.Content.bytes(rep)
                let item = DEUploadPreparedItem.init(content: content)
                self.finish(item: item)
            }
            else {
                let targetError: Error = error ?? DEUploadError.unrecognizableExtensionItem
                self.finishWithFailure(error: error)
            }
        }
    }
    
    private func loadData(attachment: NSItemProvider, type: DetailedMediaFileType) {
        guard !self.isCancelled else {
            return
        }
        
        attachment.loadData(options: nil, onSuccess: { [weak self] itemData in
            switch itemData {
            case .image(let image):
                self?.prepareItem(image: image, attachment: attachment, type: type)
            case .data(let data):
                self?.prepareData(data: data, attachment: attachment, type: type)
            case .urlData(url: let url, data: let data):
                self?.handleFileDataLoaded(url: url, data: data, attachment: attachment, type: type)
            }
            }, onFailure: { [weak self] error in
                self?.finishWithFailure(error: error)
        })
    }
    
    private func loadText(attachment: NSItemProvider) {
        guard !self.isCancelled else {
            return
        }
        
        attachment.loadItem(forTypeIdentifier: DEUti.plainText.rawValue, options: nil) { (itemContent, error) in
            guard let content = itemContent else {
                self.finishWithFailure(error: error)
                return
            }
            
            switch content {
            case let text as String:
                self.finish(item: DEUploadPreparedItem.init(content: .text(text)))
                
            case let url as URL:
                var name: String? = nil
                if !url.lastPathComponent.isEmpty {
                    name = url.lastPathComponent
                }
                
                let data: Data
                do {
                    data = try Data.init(contentsOf: url)
                }
                catch {
                    self.finishWithFailure(error: error)
                    return
                }
                
                let rep = DEUploadDataRepresentation.init(data: data, uti: DEUti.plainText.rawValue)
                self.finish(item: DEUploadPreparedItem.init(content: .bytes(rep), preview: nil, originalName: name))
                
            default:
                DELog("Unexpected item: \(String(describing: content))")
                self.finishWithFailure(error: DEUploadError.unrecognizableExtensionItem)
            }
        }
    }
    
    private func prepareData(data: Data, attachment: NSItemProvider, type: DetailedMediaFileType) {
        switch type {
        case .image:
            DispatchQueue.global(qos: .background).async {
                if let image = UIImage(data: data) {
                    let uti = data.de_representationType?.utiType ?? (kUTTypeImage as String)
                    let dataRep = DEUploadDataRepresentation.init(data: data, uti: uti)
                    let details = self.getImageDetails(image)
                    let uploadRep = DEUploadImageRepresentation.init(dataRepresentation: dataRep, details: details)
                    
                    let previewImage = image.limited(bySize: .init(width: 90.0, height: 90.0))
                    let preview = self.buildPreviewRepresentation(original: previewImage)
                    
                    let item = DEUploadPreparedItem(content: .image(uploadRep), preview: preview, originalName: nil)
                    DispatchQueue.main.async {
                        self.finish(item: item)
                    }
                }
                else {
                    let uti = kUTTypeImage as String
                    let dataRep = DEUploadDataRepresentation.init(data: data, uti: uti)
                    let item = DEUploadPreparedItem(content: .bytes(dataRep), preview: nil, originalName: nil)
                    DispatchQueue.main.async {
                        self.finish(item: item)
                    }
                    DispatchQueue.main.async {
                        self.finishWithFailure(error: DEUploadError.unrecognizableExtensionItem)
                    }
                }
            }
            
        case .video:
            DispatchQueue.global(qos: .background).async {
                let uti = kUTTypeVideo as String
                let dataRep = DEUploadDataRepresentation.init(data: data, uti: uti)
                let item = DEUploadPreparedItem(content: .bytes(dataRep), preview: nil, originalName: nil)
                DispatchQueue.main.async {
                    self.finish(item: item)
                }
            }
            
        case .audio:
            DispatchQueue.global(qos: .background).async {
                let uti = kUTTypeAudio as String
                let dataRep = DEUploadDataRepresentation.init(data: data, uti: uti)
                let item = DEUploadPreparedItem(content: .bytes(dataRep), preview: nil, originalName: nil)
                DispatchQueue.main.async {
                    self.finish(item: item)
                }
            }
            
        case .file:
            DispatchQueue.global(qos: .background).async {
                let uti = kUTTypeData as String
                let dataRep = DEUploadDataRepresentation.init(data: data, uti: uti)
                let item = DEUploadPreparedItem(content: .bytes(dataRep), preview: nil, originalName: nil)
                DispatchQueue.main.async {
                    self.finish(item: item)
                }
            }
        }
    }
    
    private func prepareItem(image: UIImage, attachment: NSItemProvider, type: DetailedMediaFileType) {
        guard let encodedImage = self.encodeImage(image) else {
            self.finishWithFailure(error: DEUploadError.fileLengthExceedsMaximum)
            return
        }
        
        let dataRep = DEUploadDataRepresentation.init(data: encodedImage.data,
                                                      uti: encodedImage.format.uti.rawValue)
        let details = self.getImageDetails(image)
        let uploadRep = DEUploadImageRepresentation.init(dataRepresentation: dataRep, details: details)
        
        let previewImage = image.limited(bySize: .init(width: 90.0, height: 90.0))
        let preview = self.buildPreviewRepresentation(original: previewImage)
        
        // Guaranteed, otherwise encoding failed
        let fileExtension = encodedImage.format.uti.fileExtension!
        let name = self.generateName(prefix:"image_").appending(".").appending(fileExtension)
        
        let item = DEUploadPreparedItem.init(content: .image(uploadRep), preview: preview, originalName: name)
        DispatchQueue.main.async {
            self.finish(item: item)
        }
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
    
    private func handleFileDataLoaded(url: URL, data: Data, attachment: NSItemProvider, type: DetailedMediaFileType) {
        guard type != .file else {
            let name = url.lastPathComponent.isEmpty ? nil : url.lastPathComponent
            
            let mimeTypeRepresentableType = attachment.mimeRepresentableTypeIdentifiers.first
            
            /// Ho to define most specific UTI? Like when pdf-file has "public.file-url" and "comp.adobe.pdf" UTIs?
            let mostSpecificUti =  mimeTypeRepresentableType ?? attachment.registeredTypeIdentifiers.first!
            let item = DEUploadPreparedItem.init(content: .bytes(.init(data: data, uti: mostSpecificUti)),
                                                 originalName: name)
            self.finish(item: item)
            return
        }
        
        loadMedia(url: url, data: data, attachment: attachment, type: type) { [weak self] media in
            withExtendedLifetime(self, {
                self?.finish(attachment: attachment, data: data, media: media)
            })
        }
    }
    
    private struct LoadedMedia {
        let name: String?
        let details: LoadedDetails
        let preview: DEUploadImageRepresentation?
    }
    
    private func loadMedia(url: URL,
                           data: Data,
                           attachment: NSItemProvider,
                           type: DetailedMediaFileType,
                           completionBlock: @escaping (LoadedMedia) -> () ) {
        
        var proposedName: String? = nil
        if !url.lastPathComponent.isEmpty {
            proposedName = url.lastPathComponent
        }
        
        var loadedDetails: LoadedDetails? = nil
        var loadedPreview: DEUploadImageRepresentation? = nil
        
        let group = DispatchGroup.init()
        
        group.enter()
        let originalImageData: Data? = (type == .image) ? data : nil
        loadPreview(attachment: attachment, originalData: originalImageData, url: url, type: type, onLoaded: { rep in
            loadedPreview = rep
            group.leave()
        })
        
        switch type {
        case .image:
            group.enter()
            self.loadImageDetails(url: url, data: data, onLoaded: { details in
                loadedDetails = LoadedDetails.image(details)
                group.leave()
            })
        case .video:
            group.enter()
            self.loadVideoDetails(url: url, data: data, onLoaded: { (details) in
                loadedDetails = LoadedDetails.video(details)
                group.leave()
            })
        case .audio:
            group.enter()
            self.loadAudioDetails(url: url, data: data, onLoaded: { (details) in
                loadedDetails = LoadedDetails.audio(details)
                group.leave()
            })
        default:
            fatalError()
        }
        
        group.notify(queue: .global(qos: .background), execute: {
            guard let details = loadedDetails else {
                fatalError("group finished, but loaded details is nil")
            }
            let media = LoadedMedia.init(name: proposedName, details: details, preview: loadedPreview)
            completionBlock(media)
        })
    }
    
    private func buildContent(attachment: NSItemProvider, data: Data, details: LoadedDetails) -> DEUploadPreparedItem.Content {
        let fileRep = DEUploadDataRepresentation.init(data: data,
                                                      mimeType: attachment.supposedMimeType!,
                                                      fileExtension: attachment.supposedFileExtension!)
        
        
        let content: DEUploadPreparedItem.Content
        switch details {
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
    
    private func finish(attachment: NSItemProvider, data: Data, media: LoadedMedia) {
        self.finish(attachment: attachment,
                    name: media.name,
                    preview: media.preview,
                    data: data,
                    details: media.details)
    }
    
    private func finish(attachment: NSItemProvider,
                        name: String?,
                        preview: DEUploadImageRepresentation?,
                        data: Data,
                        details: LoadedDetails) {
        guard !self.isCancelled else {
            return
        }
        let content = self.buildContent(attachment: attachment, data: data, details: details)
        let item = DEUploadPreparedItem.init(content: content, preview: preview, originalName: name)
        self.finish(item: item)
    }
    
    private func loadVideoDetails(url: URL, data: Data, onLoaded:@escaping ((DEUploadVideoDetails) -> ())) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVURLAsset.init(url: url)
            let duration = Int(asset.duration.seconds)
            let size: CGSize
            if let track = asset.tracks(withMediaType: AVMediaType.video).first {
                size = track.naturalSize
            }
            else {
                size = CGSize.zero
            }
            let integerSize = DEUploadIntegerSize.init(size: size)
            let details = DEUploadVideoDetails.init(size: integerSize, durationInSeconds: duration)
            DispatchQueue.main.async {
                onLoaded(details)
            }
        }
    }
    
    private func generateVideoPreview(url: URL) -> DEUploadImageRepresentation? {
        let asset = AVURLAsset.init(url: url)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        let cgImage: CGImage
        do {
            cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
        }
        catch {
            return nil
        }
        
        let image = UIImage.init(cgImage: cgImage)
        let previewImage = image.limited(bySize: .init(width: 90.0, height: 90.0))
        let preview = self.buildPreviewRepresentation(original: previewImage)
        return preview
    }
    
    private class PreviewSource {
        var type: DetailedMediaFileType
        var url: URL
        var originalData: Data? = nil
        
        init(type: DetailedMediaFileType, url: URL, data: Data? = nil) {
            self.type = type
            self.url = url
            self.type = type
        }
        
        
    }
    
    /// Callback performed on main thread
    private func loadPreview(attachment: NSItemProvider,
                             originalData: Data? = nil,
                             url: URL,
                             type: DetailedMediaFileType,
                             onLoaded: @escaping ((DEUploadImageRepresentation?) -> ()) ) {
        attachment.loadPreviewImage(options: nil, completionHandler: {[weak self] value, error in
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
                else if type == .image, let data = originalData, let image = UIImage.init(data: data) {
                    let optimizedImage = image.limited(bySize: .init(width: 90.0, height: 90.0))
                    let previewRep = self!.buildPreviewRepresentation(original: optimizedImage)
                    DispatchQueue.main.async {
                        onLoaded(previewRep)
                    }
                }
                else if type == .video {
                    let rep = self!.generateVideoPreview(url: url)
                    DispatchQueue.main.async {
                        onLoaded(rep)
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
    
    private func loadImageFromDataDetails(data: Data, onLoaded: @escaping ((DEUploadImageDetails) -> ())) {
        DispatchQueue.global(qos: .background).async {
            let image = UIImage.init(data: data)!
            let size = DEUploadIntegerSize.init(size: image.pixelSize)
            let details = DEUploadImageDetails.init(size: size)
            DispatchQueue.main.async {
                onLoaded(details)
            }
        }
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
