import Foundation
import MobileCoreServices

/**
 * Class responsible for preparing items for uploading.
 * It includes fetching datas from url, generating previews, transforming datas and building uplodadable items.
 */
public protocol DEUploadShareExtensionItemPreparing: class {
    func prepare(items: [NSExtensionItem],
                 completion: @escaping ((_ preparedItems: [DEUploadPreparedItem]?, _ error: Error?) -> ()))
}

public struct DEUploadImageInfo {
    
    var data: Data
    
    var size: CGSize
    
    var mimeType: String
    
    public init(data: Data, size: CGSize, mimeType: String) {
        self.data = data
        self.size = size
        self.mimeType = mimeType
    }
}


public protocol DEUploadShareExtensionItemPreparingPreviewMakable {
    func previewData(forOriginalPreview preview: UIImage, item: NSExtensionItem, attachment: NSItemProvider) -> DEUploadImageInfo
}

// TODO: Wrap into operation, make cancellable.
public class DEUploadShareExtensionItemPreparer: DEUploadShareExtensionItemPreparing {
    
    public struct Config {
        
        /// Items to load limit. If limits is reached – other items ignored.
        var uploadableItemsLimit: Int = 1
        
        var allowEscortMessages: Bool = true
        
        /// FIXME: Turn on!
        var previewsNeeded: Bool = false
        
        public init() {
            // do nothing
        }
    }
    
    var config: Config = Config.init()
    
    let previewMaker: DEUploadShareExtensionItemPreparingPreviewMakable?
    
    public init(previewMaker: DEUploadShareExtensionItemPreparingPreviewMakable? = nil) {
        self.previewMaker = previewMaker
    }
    
    public func prepare(items: [NSExtensionItem], completion: @escaping (([DEUploadPreparedItem]?, Error?) -> ())) {
        
        var finished = false
        var preparedItems: [DEUploadPreparedItem] = []
        
        let group = DispatchGroup.init()
        for item in items {
            group.enter()
            prepareItem(item, onPrepared: { (item, error) in
                guard !finished else { return }
                if let preparedItem = item {
                    preparedItems.append(preparedItem)
                }
                else {
                    finished = true
                    completion(nil, error)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            if !finished {
                completion(preparedItems, nil)
            }
        }
    }
    
    private typealias OnPrepared = ((DEUploadPreparedItem?, Error?) -> ())
    
    private func prepareItem(_ item: NSExtensionItem, onPrepared: @escaping OnPrepared) {
        
        let finish: OnPrepared = { item, error in
            DispatchQueue.main.async {
                onPrepared(item, error)
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            if let sharingUrl = item.sharingUrl {
                let preparedItem = DEUploadPreparedItem.init(content: .url(sharingUrl.url))
                finish(preparedItem, nil)
                return
            }
            
            var mediaAttachment: NSItemProvider? = nil
            
            mediaAttachment = item.videoAttachments.first
           
            if mediaAttachment == nil {
                mediaAttachment = item.imageAttachments.first
            }
            
            if mediaAttachment == nil {
                mediaAttachment = item.attachmentsWithTypeIdentifier(kUTTypeContent as String).first
            }
            
            if let attachment = mediaAttachment {
                self.loadMediaFile(item: item,
                                   attachment: attachment,
                                   previewNeeded: self.config.previewsNeeded,
                                   onLoaded: { (mediaFile, error) in
                                    if let file = mediaFile {
                                        let uploadItem = DEUploadPreparedItem.init(content: .mediaFile(file))
                                        finish(uploadItem, nil)
                                    }
                                    else {
                                        finish(nil, error)
                                    }
                                    
                })
                return
            }
            
            if let abstractDataAttachment = item.firstFoundDataRepresentableAttachment {
                abstractDataAttachment.loadAndRepresentData(options: nil, completionHandler: { (data, error) in
                    if let itemData = data {
                        let preparedItem = DEUploadPreparedItem.init(content: .bytes(itemData))
                        finish(preparedItem, nil)
                    }
                    else {
                        finish(nil, error)
                    }
                })
                return
            }
            
            finish(nil, DEUploadError.unrecognizableExtensionItem)
        }
        
    }
    
    private typealias DataRep = DEUploadPreparedItem.HttpRequestFormDataRepresentation
    
    private func loadMediaFile(item: NSExtensionItem,
                               attachment: NSItemProvider,
                               previewNeeded: Bool = true,
                               onLoaded: @escaping ((DEUploadPreparedItem.MediaFile?, Error?) -> ())) {
        loadDataRepresentation(item: item, attachment: attachment) { [weak self] (rep, error) in
            if let fileRep = rep {
                if !previewNeeded {
                    let mediaFile = DEUploadPreparedItem.MediaFile.init(file: fileRep, preview: nil)
                    onLoaded(mediaFile, nil)
                }
                else {
                    withExtendedLifetime(self, {
                        self?.loadPreview(item: item, attachment: attachment, onFinish: { [weak self] (rep, error) in
                            guard self != nil else { return }
                            
                            let mediaFile = DEUploadPreparedItem.MediaFile.init(file: fileRep, preview: rep)
                            onLoaded(mediaFile, nil)
                        })
                    })
                }
            }
            else {
                onLoaded(nil, error)
            }
        }
    }
    
    private func loadDataRepresentation(item: NSExtensionItem,
                                        attachment: NSItemProvider,
                                        previewNeeded: Bool = true,
                                        onFinish:@escaping ((DataRep?, Error?)->())) {
        let mimeType = attachment.supposedMimeType!
        let fileExt = attachment.supposedFileExtension
        
        attachment.loadAndRepresentData(options: nil) { (itemData, error) in
            if let data = itemData {
                let rep = DataRep.init(mimeType: mimeType, data: data, fileExtension: fileExt)
                onFinish(rep, nil)
            }
            else {
                onFinish(nil, error)
            }
        }
    }
    
    private func loadPreview(item: NSExtensionItem, attachment: NSItemProvider, onFinish: @escaping((DataRep?, Error?) -> ())) {
        attachment.loadPreviewImage(options: nil) { [weak self] (itemImage, error) in
            withOptionalExtendedLifetime(self, body: {
                if let image = itemImage as? UIImage {
                    let previewInfo = self!.preview(original: image, item: item, attachment: attachment)
                    let mimeType = previewInfo.mimeType
                    let rep = DataRep.init(mimeType: mimeType, data: previewInfo.data, fileExtension: nil)
                    rep.size = previewInfo.size
                    onFinish(rep, nil)
                }
                else {
                    onFinish(nil, error)
                }
            })
        }
    }
    
    private func defaultPreview(original: UIImage, item: NSExtensionItem, attachment: NSItemProvider) -> DEUploadImageInfo {
        
        let limitedImage = original.limited(byPixelsCount: 90 * 90)
        
        let size = limitedImage.pixelSize
        let data = UIImageJPEGRepresentation(limitedImage, 0.55)!
        
        return DEUploadImageInfo.init(data: data, size: size, mimeType: kUTTypeJPEG as String)
    }
    
    private func preview(original: UIImage, item: NSExtensionItem, attachment: NSItemProvider) -> DEUploadImageInfo {
        guard let maker = self.previewMaker else {
            return defaultPreview(original: original, item: item, attachment:attachment)
        }
        return maker.previewData(forOriginalPreview: original, item: item, attachment: attachment)
    }
    
}
