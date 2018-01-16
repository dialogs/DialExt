import Foundation
import MobileCoreServices

/**
 Class responsible for preparing items for uploading.
 It includes fetching datas from url, generating previews, transforming datas and building uplodadable items.
 Speaking shortly, implenter should do following things:
 - define type of extension item content
 - load extension item data
 - generate preview
 - generate specified info depending on type of extension item (duration for video, size for image and so on)
 - assembly all info into `prepared item` entries
 */
public protocol DEUploadShareExtensionItemPreparing: class {
    func prepare(items: [NSExtensionItem],
                 completion: @escaping ((_ preparedItems: [DEUploadPreparedItem]?, _ error: Error?) -> ()))
}

public protocol DEUploadShareExtensionItemPreparingPreviewMakable {
    func previewData(forOriginalPreview preview: UIImage, item: NSExtensionItem, attachment: NSItemProvider) -> DEUploadImageRepresentation
}


public class DEUploadShareExtensionItemPreparer: DEUploadShareExtensionItemPreparing {
    
    public struct Config {
        
        /// Items to load limit. If limits is reached – other items ignored.
        var uploadableItemsLimit: Int = 1
        
        var allowEscortMessages: Bool = true
        
        var previewsNeeded: Bool = true
        
        public init() {
            // do nothing
        }
    }
    
    var config: Config = Config.init()
    
    let previewMaker: DEUploadShareExtensionItemPreparingPreviewMakable?
    
    deinit {
        self.queue.cancelAllOperations()
    }
    
    private let queue: OperationQueue = {
        let queue = OperationQueue.init()
        queue.qualityOfService = .userInitiated
        queue.name = "im.dlg.extension.item.preparer"
        return queue
    }()
    
    public init(previewMaker: DEUploadShareExtensionItemPreparingPreviewMakable? = nil) {
        self.previewMaker = previewMaker
    }
    
    public func prepare(items: [NSExtensionItem], completion: @escaping (([DEUploadPreparedItem]?, Error?) -> ())) {
        let operation = DEUploadPrepareItemListOperation.init(items: items)
        operation.onDidFinish = { [weak self] result in
            guard self != nil else {
                return
            }
            switch result {
            case let .success(preparedItems): completion(preparedItems!, nil)
            case let .failure(error): completion(nil, error)
            default: return
            }
        }
        self.queue.addOperation(operation)
    }
}
