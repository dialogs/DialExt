//
//  DESharedDialogsViewController.swift
//  DialExt
//
//  Created by Vladlex on 03/10/2017.
//  Copyright (c) 2017 Vladlex. All rights reserved.
//

import UIKit
import MobileCoreServices

public protocol DESharedDialogsViewControllerPresenter {
    
    func shouldShowDialog(_ dialog: AppSharedDialog) -> Bool
    
    func isSelectionAllowedForDialog(_ dialog: AppSharedDialog) -> Bool
    
}


public protocol DESharedDialogsViewControllerHidingResponsible {
    func hideExtensionWithCompletionHandler(completion:(()->())?)
}

public protocol DESharedDialogsViewControllerExtensionContextProvider {
    func extensionContextForSharedDialogsViewController(_ viewController: DESharedDialogsViewController) -> NSExtensionContext?
}

public class DEDefaultSharedDialogsViewControllerPresenter: DESharedDialogsViewControllerPresenter {
    
    public func shouldShowDialog(_ dialog: AppSharedDialog) -> Bool {
        return true
    }
    
    public func isSelectionAllowedForDialog(_ dialog: AppSharedDialog) -> Bool {
        return !dialog.isReadOnly
    }
}

open class DESharedDialogsViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    
    static public func createFromDefaultStoryboard(config: DESharedDataConfig) -> DESharedDialogsViewController {
        let bundle = Bundle.dialExtResourcesBundle
        let storyboard = UIStoryboard.loadFirstFound(name: "DESharedDialogsViewController", bundles: [bundle])!
        let controller = storyboard.instantiateInitialViewController() as! DESharedDialogsViewController
        controller.config = config
        return controller
    }
    
    var dialogs: [AppSharedDialog] = [] {
        didSet {
            updatePresentedDialogs()
        }
    }
    
    private var config: DESharedDataConfig!
    
    /// Dialogs to presented (filtered by search if any search in progress)
    var presentedDialogs: [AppSharedDialog] = [] {
        didSet {
            if presentedDialogs != oldValue {
                self.tableView.reloadData()
            }
        }
    }
    
    /// Variable available for testing. If *YES* then controller does nothing after loading the view.
    internal var debug_stopsAtViewDidLoad: Bool = false
    
    private enum Content: Equatable {
        case idle
        case dialogs
        case noDialogs

        private var typeId: Int {
            switch self {
            case .idle: return 0
            case .dialogs: return 1
            case .noDialogs: return 3
            }
        }
        
        public static func ==(lhs: Content, rhs: Content) -> Bool {
            return lhs.typeId == rhs.typeId
        }
    }
    
    private var content: Content = .idle {
        didSet {
            if content != oldValue {
                updateContentRepresentation(oldContent: oldValue)
            }
        }
    }
    
    public var onDidFinish:(()->())? = nil
    
    public var manager: DESharedDialogsManager!
    
    public var avatarProvider: DEAvatarImageProvidable!
    
    public var uploader: DEExtensionItemUploader!
    
    public var multipleSelectionAllowed: Bool = false
    
    public var extensionContextProvider: DESharedDialogsViewControllerExtensionContextProvider? = nil
    
    public var hideResponsible: DESharedDialogsViewControllerHidingResponsible? = nil
    
    private var providedContext: NSExtensionContext! {
        guard let context = extensionContextProvider?.extensionContextForSharedDialogsViewController(self) else {
            return nil
        }
        return context
    }
    
    private var hasSelectedDialogs: Bool = false {
        didSet {
            if hasSelectedDialogs != oldValue {
                updateBottomPanelVisibility()
            }
        }
    }
    
    private var selectedDialogIds: Set<AppSharedDialog.Id> = Set() {
        didSet {
            updateBottomPanelContent()
            self.hasSelectedDialogs = selectedDialogIds.count > 0
        }
    }
    
    private var selectedDialogs: [AppSharedDialog] {
        return self.dialogs.filter({selectedDialogIds.contains($0.id)})
    }
    
    public var presenter: DESharedDialogsViewControllerPresenter? = DEDefaultSharedDialogsViewControllerPresenter.init()
    
    private var image: UIImage? = {
        let bundle = Bundle(for: DESharedDialogsViewController.self)
        let image = UIImage(named: "gp_chat", in: bundle, compatibleWith: nil)
        return image
    }()
    
    private var searchController: UISearchController = {
        let controller = UISearchController.init(searchResultsController: nil)
        return controller
    }()
    
    private var isSearching: Bool {
        guard let text = searchController.searchBar.text else {
            return false
        }
        return !text.isEmpty
    }
    
    @IBOutlet public private(set) var tableView: UITableView!
    
    @IBOutlet public private(set) var sendView: UIView!
    
    @IBOutlet public private(set) var recipientsLabel: UILabel!
    
    @IBOutlet public private(set) var contentView: UIView!
    
    @IBOutlet private var sendViewLineSeparatorHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private var contentBottomConstraint: NSLayoutConstraint!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        guard !debug_stopsAtViewDidLoad else {
            return
        }
        
        guard config != nil else {
            fatalError("No shared data config set")
        }
        
        if self.manager == nil {
            self.manager = DESharedDialogsManager.init(sharedDataConfig: self.config)
        }
        
        if self.uploader == nil {
            let keychain = DEKeychainDataProvider.init()
            let authProvider = keychain.shared(groupName: self.config.keychainGroup)
            let fileUploader = DEUploader.init(apiUrl: self.config.endpointUploadMethodURLs.first!)
            self.uploader = DEExtensionItemUploader.init(fileUploader: fileUploader, authProvider: authProvider)
        }
        
        if self.avatarProvider == nil {
            let provider = DEAvatarImageProvider.init(localLoader: .createWithContainerGroupId(config.appGroup))
            self.avatarProvider = provider
        }
        
        self.manager.dataLoader.onDidChangeState = { [weak self] state in
            withExtendedLifetime(self){
                guard self != nil else { return }
                self!.handleDialogsState(state)
            }
        }
        
        self.manager.dataLoader.start()
        
        searchController.searchResultsUpdater = self
        self.tableView.tableHeaderView = searchController.searchBar
        self.definesPresentationContext = true
        self.searchController.dimsBackgroundDuringPresentation = false
        
        sendViewLineSeparatorHeightConstraint.constant = 1.0 / UIScreen.main.scale
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                target: self,
                                                                action: #selector(close(sender:)))
        
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(forName: Notification.Name.KeyboardListenerDidDetectEvent,
                                               object: KeyboardListener.shared,
                                               queue: nil) { [unowned self] (notification) in
                                                let event = notification.userInfo![KeyboardListener.eventUserInfoKey] as! KeyboardEvent
                                                self.view.animateKeyboardEvent(event, bottomConstraint: self.contentBottomConstraint)
        }
        
        self.uploader.onDidChangeProgress = { [unowned self] progress in
            if let alert = self.alert {
                let message = DELocalizable.alertUploadProgress(progress: progress)
                alert.message = message
            }
        }
        
        self.uploader.onDidFinish = { [unowned self] success, error in
            self.handleFilesUploadingFinished(success: success, error: error)
        }
    }
    
    public func resetDialogs(_ dialogs: [AppSharedDialog]) {
        self.dialogs = dialogs
    }
    
    @objc private func close(sender: AnyObject) {
        self.onDidFinish?()
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction private func sendAction(_ sender: AnyObject) {
        uploadFiles()
    }
    
    private var alert: UIAlertController? = nil
    
    private func dismissAlert() {
        self.alert?.dismiss(animated: true, completion: { [unowned self] in
            self.alert = nil
        })
    }
    
    private func handleFilesUploadingFinished(success: Bool, error:Error? ) {
        let finish: (() -> ()) = {
            if success {
                self.providedContext.completeRequest(returningItems: nil, completionHandler: nil)
            }
            else {
                let contextError = error ?? NSError.init(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
                self.providedContext.cancelRequest(withError: contextError)
            }
        }
        if let hider = self.hideResponsible {
            hider.hideExtensionWithCompletionHandler(completion: { 
                finish()
            })
            
        }
        else {
            finish()
        }
    }
    
    private func uploadFiles() {
        guard let context = self.extensionContextProvider?.extensionContextForSharedDialogsViewController(self),
            let items = context.inputItems as? [NSExtensionItem] else {
                return
        }
        
        let alert = UIAlertController.init(title: DELocalize(.alertUploadTitle),
                                           message: DELocalize(.alertUploadPreparing),
                                           preferredStyle: .alert)
        let cancelAction = UIAlertAction.init(title: DELocalize(.alertCancel), style: .cancel) { _ in
            self.cancel()
        }
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true) {
            let task = DEUploadTask(items: items, dialogs: self.selectedDialogs)
            self.uploader.upload(task: task)
        }
        self.alert = alert
    }
    
    private func cancel() {
        self.uploader.cancel()
    }
    
    private func handleDialogsState(_ state: DESharedDialogsDataLoader.DataState) {
        switch state {
        case let .failured(error):
            self.handleDialogLoadingFailure(error: error)
        case .loaded:
            self.dialogs = self.manager.dataLoader.context!.dialogs.filter({self.isSelectionAllowed(for: $0)})
            if self.dialogs.count > 0 {
                self.content = .dialogs
            }
            else {
                self.content = .noDialogs
            }
        default:
            break
        }
    }
    
    private func handleDialogLoadingFailure(error: Error?) {
        guard let context = self.extensionContextProvider?.extensionContextForSharedDialogsViewController(self) else {
            fatalError("No extension context providen")
        }
        
        context.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func updateContentRepresentation(oldContent: Content) {
        switch content {
        case .dialogs:
            dismissNoDialogsPlaceholderViewController()
            
        case .noDialogs:
            presentNoDialogsPlaceholderViewController()
            
        default: break
        }
    }
    
    
    private var noDialogsViewController: DEPlaceholderViewController? = nil
    
    private func presentNoDialogsPlaceholderViewController() {
        let placeholderViewController = DEPlaceholderViewController.fromStoryboard()
        let configurator = DEPlaceholderViewController.BasicConfigurator(preconfig: .noDialogs())
        placeholderViewController.configure(configurator)
        
        self.addChildViewController(placeholderViewController)
        self.view.addSubview(placeholderViewController.view)
        NSLayoutConstraint.activate(NSLayoutConstraint.de_wrappingView(placeholderViewController.view))
        placeholderViewController.didMove(toParentViewController: self)
    }
    
    private func dismissNoDialogsPlaceholderViewController() {
        if let viewController = noDialogsViewController {
            viewController.willMove(toParentViewController: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
        }
    }
    
    
    private func updatePresentedDialogs() {
        if self.isSearching {
            let query = self.searchController.searchBar.text!.lowercased()
            self.presentedDialogs = self.dialogs.filter({ isSearchTestPassingDialog($0, query: query)})
        }
        else {
            self.presentedDialogs = dialogs
        }
    }
    
    private func isSearchTestPassingDialog(_ dialog: AppSharedDialog, query: String) -> Bool {
        return dialog.title.lowercased().contains(query)
    }
    
    public func updateSearchResults(for searchController: UISearchController) {
        updatePresentedDialogs()
    }
    
    private func shouldShowDialog(_ dialog: AppSharedDialog) -> Bool {
        guard let presenter = self.presenter else {
            return true
        }
        return presenter.shouldShowDialog(dialog)
    }
    
    private func isSelectionAllowed(for dialog: AppSharedDialog) -> Bool {
        guard let presenter = self.presenter else {
            return true
        }
        return presenter.isSelectionAllowedForDialog(dialog)
    }
    
    private func dialog(at: IndexPath) -> AppSharedDialog? {
        if at.row < presentedDialogs.count {
            return self.presentedDialogs[at.row]
        }
        return nil
    }
    
    private func isSelectionAllowed(at indexPath: IndexPath) -> Bool {
        let dialog = self.dialog(at: indexPath)!
        return isSelectionAllowed(for: dialog)
    }
    
    private func loadImage(dialog: AppSharedDialog) -> UIImage? {
        return self.avatarProvider!.provideImage(dialog: dialog) { [unowned self] (image, isPlaceholder) in
            self.updateAvatarForDialog(dialog, image: image)
        }
    }
    
    private func updateAvatarForDialog(_ dialog: AppSharedDialog, image: UIImage?) {
        updateCell(forDialogId: dialog.id) { (cell) in
            self.updateAvatarInCell(cell, image: image)
        }
    }
    
    private func updateCell(forDialogId id: AppSharedDialog.Id, code:((DEDialogCell)->()) ) {
        if let index = self.presentedDialogs.index(where: { $0.id == id }) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? DEDialogCell {
                code(cell)
            }
        }
        
    }
    
    private func unselectDialogs(with ids: [AppSharedDialog.Id], animated: Bool = false) {
        for id in ids {
            self.updateCell(forDialogId: id, code: { (cell) in
                var state = cell.selectionState
                state.selected = false
                cell.setSelectionState(state, animated: animated)
            })
        }
    }
    
    private func updateSelectedDialogs(dialogId: AppSharedDialog.Id, selected: Bool) {
        if selected {
            if self.multipleSelectionAllowed {
                selectedDialogIds.insert(dialogId)
            }
            else {
                let unselectedDialogIds = Array(self.selectedDialogIds)
                unselectDialogs(with: unselectedDialogIds)
                selectedDialogIds = [dialogId]
            }
        }
        else {
            selectedDialogIds.remove(dialogId)
        }
    }
    
    private func updateBottomPanelVisibility() {
        let shouldBeShown = self.hasSelectedDialogs
        let options: UIViewAnimationOptions = [UIViewAnimationOptions.curveEaseInOut,
                                               UIViewAnimationOptions.beginFromCurrentState]
        UIView.animate(withDuration: 0.15, delay: 0.0, options: options, animations: {
            self.sendView.isHidden = !shouldBeShown
        }, completion: nil)
    }
    
    private func updateBottomPanelContent() {
        let dialogTitles: [String] = selectedDialogs.map({$0.title})
        let title = dialogTitles.joined(separator: ", ")
        recipientsLabel.text = title
    }
    
    private func updateAvatarInCell(_ cell: DEDialogCell, image: UIImage?) {
        cell.avatarView.image = image
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presentedDialogs.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52.0
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? DEDialogCell {
            var state = cell.selectionState
            state.selected = !state.selected
            cell.setSelectionState(state)
            updateSelectedDialogs(dialogId: self.presentedDialogs[indexPath.row].id, selected: state.selected)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DEDialogCell", for: indexPath) as! DEDialogCell
        let dialog = self.presentedDialogs[indexPath.row]
        cell.nameLabel.text = dialog.title
        
        let names: [String] = dialog.uids.flatMap({ id in
            if let context = self.manager.dataLoader.context,
                let user = context.users.first(where: {$0.id == id}) {
                return user.name
            }
            return nil
        })
        
        cell.statusLabel.text = names.joined(separator: ", ")
        cell.statusLabelContainer.isHidden = !dialog.isGroup
        
        var selectionState = cell.selectionState
        selectionState.selected = self.selectedDialogIds.contains(dialog.id)
        cell.setSelectionState(selectionState, animated: false)
        
        cell.avatarView.image = self.avatarProvider.provideImage(dialog: dialog, completion: { (image, placeholder) in
        })
        
        let avatarViewSide = min(cell.avatarView.frame.size.width, cell.avatarView.frame.size.height)
        cell.avatarView.layer.cornerRadius = avatarViewSide / 2.0
        cell.avatarView.layer.masksToBounds = true
        
        cell.avatarView.image = self.loadImage(dialog: dialog)
        
        return cell
    }
}
