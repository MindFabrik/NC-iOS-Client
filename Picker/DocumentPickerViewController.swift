//
//  DocumentPickerViewController.swift
//  Picker
//
//  Created by Marino Faggiana on 27/12/16.
//  Copyright © 2017 TWS. All rights reserved.
//
//  Author Marino Faggiana <m.faggiana@twsweb.it>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


import UIKit

class DocumentPickerViewController: UIDocumentPickerExtensionViewController, CCNetworkingDelegate, OCNetworkingDelegate, BKPasscodeViewControllerDelegate {
    
    // MARK: - Properties
    
    lazy var fileCoordinator: NSFileCoordinator = {
    
        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.purposeIdentifier = self.parameterProviderIdentifier
        return fileCoordinator
        
    }()
    
    var parameterMode: UIDocumentPickerMode?
    var parameterOriginalURL: URL?
    var parameterProviderIdentifier: String!
    var parameterPasscodeCorrect: Bool = false
    
    var recordMetadata = tableMetadata()
    var recordsTableMetadata: [tableMetadata]?
    var titleFolder: String = ""
    
    var activeAccount: String = ""
    var activeUrl: String = ""
    var activeUser: String = ""
    var activeUserID: String = ""
    var activePassword: String = ""
    var directoryUser: String = ""
    
    var serverUrl: String?
    var thumbnailInLoading = [String: IndexPath]()
    var destinationURL: URL?
    
    var passcodeFailedAttempts: UInt = 0
    var passcodeLockUntilDate: Date? = nil
    var passcodeIsPush: Bool = false
    var serverUrlPush: String = ""
    
    var autoUploadFileName = ""
    var autoUploadDirectory = ""
    
    lazy var networkingOperationQueue: OperationQueue = {
        
        var queue = OperationQueue()
        queue.name = k_queue
        queue.maxConcurrentOperationCount = 10
        
        return queue
    }()
    
    var hud : CCHud!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var saveButton: UIBarButtonItem!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let record = NCManageDatabase.sharedInstance.getAccountActive() {
            
            activeAccount = record.account
            activePassword = record.password
            activeUrl = record.url
            activeUser = record.user
            activeUserID = record.userID
            directoryUser = CCUtility.getDirectoryActiveUser(activeUser, activeUrl: activeUrl)
            
            if serverUrl == nil {
                serverUrl = CCUtility.getHomeServerUrlActiveUrl(activeUrl)
            } else {
                self.navigationItem.title = titleFolder
            }
        
        } else {
            
            // Close error no account return nil
            
            let deadlineTime = DispatchTime.now() + 0.1
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                
                let alert = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: NSLocalizedString("_no_active_account_", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default) { action in
                    self.dismissGrantingAccess(to: nil)
                })
                
                self.present(alert, animated: true, completion: nil)
            }

            return
        }
        
        //  MARK: - init Object
        CCNetworking.shared().delegate = self
        hud = CCHud.init(view: self.navigationController?.view)
        
        // Theming
        if (NCBrandOptions.sharedInstance.use_themingColor == true) {
            let tableCapabilities = NCManageDatabase.sharedInstance.getCapabilites()
            if (tableCapabilities != nil) {
                CCGraphics.settingThemingColor(tableCapabilities?.themingColor, themingColorElement: tableCapabilities?.themingColorElement, themingColorText: tableCapabilities?.themingColorText)
            }
        }
        
        // COLOR
        self.navigationController?.navigationBar.barTintColor = NCBrandColor.sharedInstance.brand
        self.navigationController?.navigationBar.tintColor = NCBrandColor.sharedInstance.brandText
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: NCBrandColor.sharedInstance.brandText]
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.tableView.separatorColor = NCBrandColor.sharedInstance.seperator
        self.tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(triggerProgressTask(_:)), name: NSNotification.Name(rawValue: "NotificationProgressTask"), object: nil)
        
        readFolder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
    
        // BUGFIX 2.17 - Change user Nextcloud App
        CCNetworking.shared().settingAccount()
        
        // (save) mode of presentation -> pass variable for pushViewController
        prepareForPresentation(in: parameterMode!)
    
        // String is nil or empty
        guard let passcode = CCUtility.getBlockCode(), !passcode.isEmpty else {
            return
        }
        
        if CCUtility.getOnlyLockDir() == false && parameterPasscodeCorrect == false {
            openBKPasscode(NCBrandOptions.sharedInstance.brand)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // remove all networking operation
        networkingOperationQueue.cancelAllOperations()
        
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Overridden Instance Methods
    
    override func prepareForPresentation(in mode: UIDocumentPickerMode) {
        
        // ------------------> Settings parameter ----------------
        if parameterMode == nil {
            parameterMode = mode
        }
        
        // Variable for exportToService or moveToService
        if parameterOriginalURL == nil && originalURL != nil {
            parameterOriginalURL = originalURL
        }
        
        if parameterProviderIdentifier == nil {
            parameterProviderIdentifier = providerIdentifier
        }
        // -------------------------------------------------------
        
        switch mode {
            
        case .exportToService:
            
            print("Document Picker Mode : exportToService")
            saveButton.title = NSLocalizedString("_save_document_picker_", comment: "") // Save in this position
            
        case .moveToService:
            
            //Show confirmation button
            print("Document Picker Mode : moveToService")
            saveButton.title = NSLocalizedString("_save_document_picker_", comment: "") // Save in this position
            
        case .open:
            
            print("Document Picker Mode : open")
            saveButton.tintColor = UIColor.clear
            
        case .import:
            
            print("Document Picker Mode : import")
            saveButton.tintColor = UIColor.clear
        }
    }

    //  MARK: - Read folder
    
    func readFolder() {
        
        let metadataNet = CCMetadataNet.init(account: activeAccount)!

        metadataNet.action = actionReadFolder
        metadataNet.depth = "1"
        metadataNet.serverUrl = self.serverUrl
        metadataNet.selector = selectorReadFolder
        
        let ocNetworking : OCnetworking = OCnetworking.init(delegate: self, metadataNet: metadataNet, withUser: activeUser, withUserID: activeUserID, withPassword: activePassword, withUrl: activeUrl)
        networkingOperationQueue.addOperation(ocNetworking)
        
        hud.visibleIndeterminateHud()
    }
    
    func readFolderFailure(_ metadataNet: CCMetadataNet!, message: String!, errorCode: Int) {
        
        hud.hideHud()
        
        let alert = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default) { action in
            self.dismissGrantingAccess(to: nil)
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func readFolderSuccess(_ metadataNet: CCMetadataNet!, metadataFolder: tableMetadata?, metadatas: [Any]!) {
        
        // remove all record
        var predicate = NSPredicate(format: "account = %@ AND directoryID = %@ AND session = ''", activeAccount, metadataNet.directoryID!)
        NCManageDatabase.sharedInstance.deleteMetadata(predicate: predicate, clearDateReadDirectoryID: metadataNet.directoryID!)
        
        for metadata in metadatas as! [tableMetadata] {
            
            // Only Directory ?
            if (parameterMode == .moveToService || parameterMode == .exportToService) && metadata.directory == false {
                continue
            }
            
            // Add record
            _ = NCManageDatabase.sharedInstance.addMetadata(metadata)
        }
        
        predicate = NSPredicate(format: "account = %@ AND directoryID = %@", activeAccount, metadataNet.directoryID!)
        recordsTableMetadata = NCManageDatabase.sharedInstance.getMetadatas(predicate: predicate, sorted: "fileName", ascending: true)
        
        autoUploadFileName = NCManageDatabase.sharedInstance.getAccountAutoUploadFileName()
        autoUploadDirectory = NCManageDatabase.sharedInstance.getAccountAutoUploadDirectory(activeUrl)
        
        if (CCUtility.isEnd(toEndEnabled: activeAccount)) {
        }
        
        tableView.reloadData()
        
        hud.hideHud()
    }
    
    //  MARK: - Download Thumbnail
    
    func downloadThumbnailFailure(_ metadataNet: CCMetadataNet!, message: String!, errorCode: Int) {
        NSLog("[LOG] Thumbnail Error \(metadataNet.fileName) \(message) (error \(errorCode))");
    }
    
    func downloadThumbnailSuccess(_ metadataNet: CCMetadataNet!) {
        
        if let indexPath = thumbnailInLoading[metadataNet.fileID] {
            
            let path = "\(directoryUser)/\(metadataNet.fileID!).ico"
            
            if FileManager.default.fileExists(atPath: path) {
                
                if let cell = tableView.cellForRow(at: indexPath) as? recordMetadataCell {
                    cell.fileImageView.image = UIImage(contentsOfFile: path)
                }
            }
        }
    }
    
    func downloadThumbnail(_ metadata : tableMetadata) {
        
        let metadataNet = CCMetadataNet.init(account: activeAccount)!
        
        metadataNet.action = actionDownloadThumbnail
        metadataNet.fileID = metadata.fileID
        metadataNet.fileName = CCUtility.returnFileNamePath(fromFileName: metadata.fileName, serverUrl: self.serverUrl, activeUrl: activeUrl)
        metadataNet.options = "m";
        metadataNet.selector = selectorDownloadThumbnail;
        metadataNet.serverUrl = self.serverUrl
        
        let ocNetworking : OCnetworking = OCnetworking.init(delegate: self, metadataNet: metadataNet, withUser: activeUser, withUserID: activeUserID, withPassword: activePassword, withUrl: activeUrl)
        networkingOperationQueue.addOperation(ocNetworking)
    }

    //  MARK: - Download / Upload
    
    @objc func triggerProgressTask(_ notification: NSNotification) {
        
        let dict = notification.userInfo
        let progress = dict?["progress"] as! Float
        
        hud.progress(progress)
    }
    
    //  MARK: - Download

    func downloadFileSuccessFailure(_ fileName: String!, fileID: String!, serverUrl: String!, selector: String!, selectorPost: String!, errorMessage: String!, errorCode: Int) {
        
        hud.hideHud()
        
        if (errorCode == 0) {
            
            guard let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID == %@", activeAccount, fileID!)) else {
                self.dismissGrantingAccess(to: nil)
                return
            }
            
            recordMetadata = metadata
            
            // Save for PickerFileProvide
            CCUtility.setFileNameExt(metadata.fileName)
            CCUtility.setServerUrlExt(serverUrl)
            
            switch selector {
                
            case selectorLoadFileView :
                
                let sourceFileNamePath = "\(directoryUser)/\(fileID!)"
                let destinationFileNameUrl : URL! = appGroupContainerURL()?.appendingPathComponent(recordMetadata.fileName)
                let destinationFileNamePath = destinationFileNameUrl.path
                
                // Destination Provider
                
                do {
                    try FileManager.default.removeItem(at: destinationFileNameUrl)
                } catch _ {
                    print("file do not exists")
                }
                
                do {
                    try FileManager.default.copyItem(atPath: sourceFileNamePath, toPath: destinationFileNamePath)
                } catch let error as NSError {
                    print(error)
                }
                
                // Dismiss
                
                self.dismissGrantingAccess(to: destinationFileNameUrl)
                
            default :
                
                print("selector : \(selector!)")
                tableView.reloadData()
            }
            
        } else {
            
            if selector == selectorLoadFileView && errorCode != -999 {
                
                let alert = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default) { action in
                    NSLog("[LOG] Download Error \(fileID) \(errorMessage) (error \(errorCode))");
                })
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
 
    //  MARK: - Upload 
    
    func uploadFileSuccessFailure(_ fileName: String!, fileID: String!, assetLocalIdentifier: String!, serverUrl: String!, selector: String!, selectorPost: String!, errorMessage: String!, errorCode: Int) {
        
        hud.hideHud()
        
        if (errorCode == 0) {
            
            dismissGrantingAccess(to: self.destinationURL)
            
        } else {
           
            // remove file
            let predicate = NSPredicate(format: "account = %@ AND fileID == %@", activeAccount, fileID)
            NCManageDatabase.sharedInstance.deleteMetadata(predicate: predicate, clearDateReadDirectoryID: nil)
            
            if errorCode != -999 {
                
                let alert = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default) { action in
                    //self.dismissGrantingAccess(to: nil)
                    NSLog("[LOG] Download Error \(fileID) \(errorMessage) (error \(errorCode))");
                })
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - IBActions

extension DocumentPickerViewController {
    
    @IBAction func saveButtonTapped(_ sender: AnyObject) {
        
        guard let sourceURL = parameterOriginalURL else {
            return
        }
        
        switch parameterMode! {
            
        case .moveToService, .exportToService:
            
            let fileName = sourceURL.lastPathComponent
            let destinationFileNamePath = "\(directoryUser)/\(fileName)"
            
            destinationURL = appGroupContainerURL()?.appendingPathComponent(fileName)
            
            fileCoordinator.coordinate(readingItemAt: sourceURL, options: .withoutChanges, error: nil, byAccessor: { [weak self] newURL in
                
                // copy sourceURL on directoryUser
                do {
                    try FileManager.default.removeItem(atPath: destinationFileNamePath)
                } catch _ {
                    print("file do not exists")
                }
                
                do {
                    try FileManager.default.copyItem(atPath: sourceURL.path, toPath: destinationFileNamePath)
                } catch _ {
                    print("file do not exists")
                    self?.dismissGrantingAccess(to: self?.destinationURL)
                    return
                }
                
                do {
                    try FileManager.default.removeItem(at: (self?.destinationURL)!)
                } catch _ {
                    print("file do not exists")
                }
                
                do {
                    try FileManager.default.copyItem(at: sourceURL, to: (self?.destinationURL)!)
                    
                    let fileSize = (try! FileManager.default.attributesOfItem(atPath: sourceURL.path)[FileAttributeKey.size] as! NSNumber).uint64Value
                    
                    if fileSize == 0 {
                        
                        CCUtility.setFileNameExt(fileName)
                        CCUtility.setServerUrlExt(self!.serverUrl)
                        self?.dismissGrantingAccess(to: self?.destinationURL)
                        
                    } else {
                    
                        // Upload fileName to Cloud
                    
                        CCNetworking.shared().uploadFile(fileName, serverUrl: self!.serverUrl, session: k_upload_session_foreground, taskStatus: Int(k_taskStatusResume), selector: "", selectorPost: "", errorCode: 0, delegate: self)
                        
                        self!.hud.visibleHudTitle(NSLocalizedString("_uploading_", comment: ""), mode: MBProgressHUDMode.determinate, color: NCBrandColor.sharedInstance.brandElement)
                    }
                } catch _ {
                    self?.dismissGrantingAccess(to: self?.destinationURL)
                    print("error copying file")
                }
            })
        
        default:
            dismissGrantingAccess(to: self.destinationURL)
        }
    }
    
    func appGroupContainerURL() -> URL? {
        
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: NCBrandOptions.sharedInstance.capabilitiesGroups) else {
                return nil
        }
        
        let storagePathUrl = groupURL.appendingPathComponent("File Provider Storage")
        let storagePath = storagePathUrl.path
        
        if !FileManager.default.fileExists(atPath: storagePath) {
            do {
                try FileManager.default.createDirectory(atPath: storagePath, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                print("error creating filepath: \(error)")
                return nil
            }
        }
        
        return storagePathUrl
    }
    
    // MARK: - Passcode
    
    func openBKPasscode(_ title : String?) {
        
        let viewController = CCBKPasscode.init()
        
        viewController.delegate = self
        viewController.type = BKPasscodeViewControllerCheckPasscodeType
        viewController.inputViewTitlePassword = true
        
        if CCUtility.getSimplyBlockCode() {
            
            viewController.passcodeStyle = BKPasscodeInputViewNumericPasscodeStyle
            viewController.passcodeInputView.maximumLength = 6
            
        } else {
            
            viewController.passcodeStyle = BKPasscodeInputViewNormalPasscodeStyle
            viewController.passcodeInputView.maximumLength = 64
        }
        
        let touchIDManager = BKTouchIDManager.init(keychainServiceName: k_serviceShareKeyChain)
        touchIDManager?.promptText = NSLocalizedString("_scan_fingerprint_", comment: "")
        viewController.touchIDManager = touchIDManager
        viewController.title = title
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(passcodeViewCloseButtonPressed(sender:)))
        viewController.navigationItem.leftBarButtonItem?.tintColor = UIColor.black
        
        let navController = UINavigationController.init(rootViewController: viewController)
        self.present(navController, animated: true, completion: nil)
    }

    func passcodeViewControllerNumber(ofFailedAttempts aViewController: BKPasscodeViewController!) -> UInt {
        
        return passcodeFailedAttempts
    }
    
    func passcodeViewControllerLock(untilDate aViewController: BKPasscodeViewController!) -> Date! {
        
        return passcodeLockUntilDate
    }
    
    func passcodeViewControllerDidFailAttempt(_ aViewController: BKPasscodeViewController!) {
        
        passcodeFailedAttempts += 1
        
        if passcodeFailedAttempts > 5 {
            
            var timeInterval: TimeInterval = 60
            
            if passcodeFailedAttempts > 6 {
                
                let multiplier = passcodeFailedAttempts - 6
                
                timeInterval = TimeInterval(5 * 60 * multiplier)
                
                if timeInterval > 3600 * 24 {
                    timeInterval = 3600 * 24
                }
            }
            
            passcodeLockUntilDate = Date.init(timeIntervalSinceNow: timeInterval)
        }
    }
    
    func passcodeViewController(_ aViewController: BKPasscodeViewController!, authenticatePasscode aPasscode: String!, resultHandler aResultHandler: ((Bool) -> Void)!) {
        
        if aPasscode == CCUtility.getBlockCode() {
            passcodeLockUntilDate = nil
            passcodeFailedAttempts = 0
            aResultHandler(true)
        } else {
            aResultHandler(false)
        }
    }
    
    public func passcodeViewController(_ aViewController: BKPasscodeViewController!, didFinishWithPasscode aPasscode: String!) {
        
        parameterPasscodeCorrect = true
        aViewController.dismiss(animated: true, completion: nil)
        
        if self.passcodeIsPush == true {
            performSegue()
        }
    }
    
    @objc func passcodeViewCloseButtonPressed(sender :Any) {
        
        dismiss(animated: true, completion: {
            if self.passcodeIsPush == false {
                self.dismissGrantingAccess(to: nil)
            }
        })
    }
}

// MARK: - UITableViewDelegate

extension DocumentPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
         return 50
    }
}

// MARK: - UITableViewDataSource

extension DocumentPickerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return recordsTableMetadata?.count ?? 0
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! recordMetadataCell
        
        cell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0)
        
        guard let metadata = recordsTableMetadata?[(indexPath as NSIndexPath).row] else {
            return cell
        }
        
        // File Image View
        let fileNamePath = "\(directoryUser)/\(metadata.fileID)).ico"
        
        if FileManager.default.fileExists(atPath: fileNamePath) {
            
            cell.fileImageView.image = UIImage(contentsOfFile: fileNamePath)
            
        } else {
            
            if metadata.directory {
                
                if (metadata.e2eEncrypted) {
                    cell.fileImageView.image = CCGraphics.changeThemingColorImage(UIImage(named: "folderEncrypted"), color: NCBrandColor.sharedInstance.brandElement)
                } else if (metadata.fileName == autoUploadFileName && serverUrl == autoUploadDirectory) {
                    cell.fileImageView.image = CCGraphics.changeThemingColorImage(UIImage(named: "folderphotocamera"), color: NCBrandColor.sharedInstance.brandElement)
                } else {
                    cell.fileImageView.image = CCGraphics.changeThemingColorImage(UIImage(named: "folder"), color: NCBrandColor.sharedInstance.brandElement)
                }
                
            } else {
                
                cell.fileImageView.image = UIImage(named: (metadata.iconName))
                if (metadata.thumbnailExists) {
                    
                    downloadThumbnail(metadata)
                    thumbnailInLoading[metadata.fileID] = indexPath
                }
            }
        }
        
        // File Name
        cell.fileName.text = metadata.fileNameView
        
        // Status Image View
        let lockServerUrl = CCUtility.stringAppendServerUrl(self.serverUrl!, addFileName: metadata.fileName)
                
        let tableDirectory = NCManageDatabase.sharedInstance.getTableDirectory(predicate:NSPredicate(format: "account = %@ AND serverUrl = %@", activeAccount, lockServerUrl!))
        if tableDirectory != nil {
            if metadata.directory &&  (tableDirectory?.lock)! && (CCUtility.getBlockCode() != nil) {
                cell.StatusImageView.image = UIImage(named: "passcode")
            } else {
                cell.StatusImageView.image = nil
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let metadata = recordsTableMetadata?[(indexPath as NSIndexPath).row]

        tableView.deselectRow(at: indexPath, animated: true)
        
        recordMetadata = metadata!

        if metadata!.directory == false {
            
            // Delete old record metadata and file
            do {
                try FileManager.default.removeItem(atPath: "\(directoryUser)/\(metadata!.fileID)")
            } catch _ {
            }
            do {
                try FileManager.default.removeItem(atPath: "\(directoryUser)/\(metadata!.fileID).ico")
            } catch {
            }
            
            CCNetworking.shared().downloadFile(metadata?.fileName, fileID: metadata?.fileID, serverUrl: self.serverUrl, selector: selectorLoadFileView, selectorPost: nil, session: k_download_session_foreground, taskStatus: Int(k_taskStatusResume), delegate: self)

            hud.visibleHudTitle(NSLocalizedString("_loading_", comment: ""), mode: MBProgressHUDMode.determinate, color: NCBrandColor.sharedInstance.brandElement)
            
        } else {
            
            // E2EE DENIED
            if (metadata?.e2eEncrypted == true) {
                return
            }
        
            serverUrlPush = CCUtility.stringAppendServerUrl(self.serverUrl!, addFileName: recordMetadata.fileName)

            var passcode: String? = CCUtility.getBlockCode()
            if passcode == nil {
                passcode = ""
            }
        
            let tableDirectory = NCManageDatabase.sharedInstance.getTableDirectory(predicate:NSPredicate(format: "account = %@ AND serverUrl = %@", activeAccount, serverUrlPush))
            
            if tableDirectory != nil {
                
                if (tableDirectory?.lock)! && (passcode?.count)! > 0 {
                    
                    self.passcodeIsPush = true
                    openBKPasscode(recordMetadata.fileName)
                    
                } else {
                    performSegue()
                }
                
            } else {
                performSegue()
            }
        }
    }
    
    func performSegue() {
        
        let nextViewController = self.storyboard?.instantiateViewController(withIdentifier: "DocumentPickerViewController") as! DocumentPickerViewController
        
        nextViewController.parameterMode = parameterMode
        nextViewController.parameterOriginalURL = parameterOriginalURL
        nextViewController.parameterProviderIdentifier = parameterProviderIdentifier
        nextViewController.parameterPasscodeCorrect = parameterPasscodeCorrect
        nextViewController.serverUrl = serverUrlPush
        nextViewController.titleFolder = recordMetadata.fileName
        
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}

// MARK: - Class UITableViewCell

class recordMetadataCell: UITableViewCell {
    
    @IBOutlet weak var fileImageView: UIImageView!
    @IBOutlet weak var StatusImageView: UIImageView!
    @IBOutlet weak var fileName : UILabel!
}
