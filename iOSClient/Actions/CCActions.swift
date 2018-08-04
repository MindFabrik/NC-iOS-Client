//
//  CCActions.swift
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 06/02/17.
//  Copyright (c) 2017 TWS. All rights reserved.
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

import Foundation

@objc protocol CCActionsDeleteDelegate {
    
    func deleteFileOrFolderSuccessFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger)
}

@objc protocol CCActionsRenameDelegate {

    func renameSuccess(_ metadataNet: CCMetadataNet)
    func renameMoveFileOrFolderFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger)
}

@objc protocol CCActionsSearchDelegate {
    
    func searchSuccess(_ metadataNet: CCMetadataNet, metadatas: [Any])
    func searchFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger)
}

@objc protocol CCActionsDownloadThumbnailDelegate {
    
    func downloadThumbnailSuccess(_ metadataNet: CCMetadataNet)
}

@objc protocol CCActionsSettingFavoriteDelegate {
    
    func settingFavoriteSuccess(_ metadataNet: CCMetadataNet)
    func settingFavoriteFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger)
}

@objc protocol CCActionsListingFavoritesDelegate {
    
    func listingFavoritesSuccess(_ metadataNet: CCMetadataNet, metadatas: [Any])
    func listingFavoritesFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger)
}

class CCActions: NSObject {
    
    //MARK: Shared Instance
    
    @objc static let sharedInstance: CCActions = {
        let instance = CCActions()
        return instance
    }()
    
    //MARK: Local Variable
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //MARK: Init
    
    override init() {
    }
    
    // --------------------------------------------------------------------------------------------
    // MARK: Delete File or Folder
    // --------------------------------------------------------------------------------------------

    @objc func deleteFileOrFolder(_ metadata: tableMetadata,delegate: AnyObject, hud: CCHud?, hudTitled: String?) {
                
        guard let serverUrl = NCManageDatabase.sharedInstance.getServerUrl(metadata.directoryID) else {
            return
        }
        
        let metadataNet: CCMetadataNet = CCMetadataNet.init(account: appDelegate.activeAccount)

        // fix CCActions.swift line 88 2.17.2 (00005)
        if (serverUrl == "") {
            appDelegate.messageNotification("_delete_", description: "_file_not_found_reload_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.error, errorCode: 0)
            return
        }
        
        guard let tableDirectory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", self.appDelegate.activeAccount, serverUrl)) else {
            return
        }
        
        DispatchQueue.global().async {
        
            // E2EE LOCK
            let tableE2eEncryption = NCManageDatabase.sharedInstance.getE2eEncryption(predicate: NSPredicate(format: "account = %@ AND fileNameIdentifier = %@", self.appDelegate.activeAccount, metadata.fileName))
            if tableE2eEncryption != nil {
                let error = NCNetworkingSync.sharedManager().lockEnd(toEndFolderEncrypted: self.appDelegate.activeUser, userID: self.appDelegate.activeUserID, password: self.appDelegate.activePassword, url: self.appDelegate.activeUrl, serverUrl:serverUrl, fileID: tableDirectory.fileID)
                if error != nil {
                    DispatchQueue.main.async {
                        self.appDelegate.messageNotification("_delete_", description: error!.localizedDescription, visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.error, errorCode: 0)
                    }
                    return;
                }
            }
        
            metadataNet.action = actionDeleteFileDirectory
            metadataNet.delegate = delegate
            metadataNet.directory = metadata.directory
            metadataNet.directoryID = metadata.directoryID
            metadataNet.fileID = metadata.fileID
            metadataNet.fileName = metadata.fileName
            metadataNet.fileNameView = metadata.fileNameView
            metadataNet.selector = selectorDelete
            metadataNet.serverUrl = serverUrl
        
            self.appDelegate.addNetworkingOperationQueue(self.appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
            
            if hud != nil  {
                DispatchQueue.main.async {
                    hud?.visibleHudTitle(hudTitled, mode: MBProgressHUDMode.indeterminate, color: nil)
                }
            }
        }
    }
    
    @objc func deleteFileOrFolderSuccessFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger) {

        if (errorCode == 0) {
        
            let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "fileID == %@", metadataNet.fileID))
        
            if let metadata = metadata {
                self.deleteFile(metadata: metadata, serverUrl: metadataNet.serverUrl)
            }
        
            guard let tableDirectory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", self.appDelegate.activeAccount, metadataNet.serverUrl)) else {
                self.deleteFileOrFolderSuccessFailure(metadataNet, message: "Internal error, tableDirectory not found", errorCode: 0)
                return
            }
        
            // E2EE Rebuild and send Metadata
            if tableDirectory.e2eEncrypted {

                DispatchQueue.global().async {
                    
                    // Send Metadata
                    let error = NCNetworkingSync.sharedManager().rebuildAndSendEndToEndMetadata(onServerUrl: metadataNet.serverUrl, account: self.appDelegate.activeAccount, user: self.appDelegate.activeUser, userID: self.appDelegate.activeUserID, password: self.appDelegate.activePassword, url: self.appDelegate.activeUrl) as NSError?
                    
                    DispatchQueue.main.async {
                        if (error == nil) {
                            metadataNet.delegate?.deleteFileOrFolderSuccessFailure(metadataNet, message: "", errorCode: 0)
                        } else {
                            self.deleteFileOrFolderSuccessFailure(metadataNet, message: error!.localizedDescription as NSString, errorCode: error!.code)
                        }
                    }
                }
            
            } else {
                metadataNet.delegate?.deleteFileOrFolderSuccessFailure(metadataNet, message: "", errorCode: 0)
            }
        } else {
            
            if errorCode == 404 {
                
                let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "fileID == %@", metadataNet.fileID))
                
                if metadata != nil {
                    self.deleteFile(metadata: metadata!, serverUrl: metadataNet.serverUrl)
                }
            }
            
            if message.length > 0 {
                
                appDelegate.messageNotification("_delete_", description: message as String, visible: true, delay:TimeInterval(k_dismissAfterSecond), type:TWMessageBarMessageType.error, errorCode: errorCode)
            }
            
            metadataNet.delegate?.deleteFileOrFolderSuccessFailure(metadataNet, message: message, errorCode: errorCode)
        }
    }
    
    // --------------------------------------------------------------------------------------------
    // MARK: Rename File or Folder
    // --------------------------------------------------------------------------------------------
    
    @objc func renameFileOrFolder(_ metadata: tableMetadata, fileName: String, delegate: AnyObject) {

        let metadataNet: CCMetadataNet = CCMetadataNet.init(account: appDelegate.activeAccount)
        
        let fileName = CCUtility.removeForbiddenCharactersServer(fileName)!
        
        guard let serverUrl = NCManageDatabase.sharedInstance.getServerUrl(metadata.directoryID) else {
            return
        }
        
        if fileName.count == 0 {
            return
        }
        
        if metadata.fileNameView == fileName {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
        
            // Verify if exists the fileName TO
            var items: NSArray?
        
            guard NCNetworkingSync.sharedManager().readFile("\(String(describing: serverUrl))/\(fileName)", user: self.appDelegate.activeUser, userID: self.appDelegate.activeUserID, password: self.appDelegate.activePassword, items: &items) != nil else {
                
                DispatchQueue.main.async {
                    
                    let alertController = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: NSLocalizedString("_file_already_exists_", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                        (result : UIAlertAction) -> Void in
                    }
                
                    alertController.addAction(okAction)
                
                    delegate.present(alertController, animated: true, completion: nil)
                }
                
                return;
            }
        
            metadataNet.action = actionMoveFileOrFolder
            metadataNet.delegate = delegate
            metadataNet.fileID = metadata.fileID
            metadataNet.fileName = metadata.fileName
            metadataNet.fileNameTo = fileName
            metadataNet.fileNameView = metadata.fileNameView
            metadataNet.selector = selectorRename
            metadataNet.serverUrl = serverUrl
            metadataNet.serverUrlTo = serverUrl
            
            self.appDelegate.addNetworkingOperationQueue(self.appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
        }
    }
    
    @objc func renameSuccess(_ metadataNet: CCMetadataNet) {
        
        let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "fileID = %@", metadataNet.fileID))
        
        if metadata?.directory == true {
            
            let directory = CCUtility.stringAppendServerUrl(metadataNet.serverUrl, addFileName: metadataNet.fileName)
            let directoryTo = CCUtility.stringAppendServerUrl(metadataNet.serverUrl, addFileName: metadataNet.fileNameTo)
            
            guard let directoryTable = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "serverUrl = %@", directory!)) else {
                
                metadataNet.delegate?.renameMoveFileOrFolderFailure(metadataNet, message: "Internal error, ServerUrl not found" as NSString, errorCode: 0)
                return
            }
            
            NCManageDatabase.sharedInstance.setDirectory(serverUrl: directory!, serverUrlTo: directoryTo!, etag: nil, fileID: nil, encrypted: directoryTable.e2eEncrypted)
            
        } else {
            
            NCManageDatabase.sharedInstance.setLocalFile(fileID: metadataNet.fileID, date: nil, exifDate: nil, exifLatitude: nil, exifLongitude: nil, fileName: metadataNet.fileNameTo)
        }
        
        metadataNet.delegate?.renameSuccess(metadataNet)
    }
    
    @objc func renameMoveFileOrFolderFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger) {
        
        if message.length > 0 {
            
            var title : String = ""
            
            if metadataNet.selector == selectorRename {
                
                title = "_delete_"
            }
            
            if metadataNet.selector == selectorMove {
                
                title = "_move_"
            }
            
            appDelegate.messageNotification(title, description: message as String, visible: true, delay:TimeInterval(k_dismissAfterSecond), type:TWMessageBarMessageType.error, errorCode: errorCode)
        }
        
        metadataNet.delegate?.renameMoveFileOrFolderFailure(metadataNet, message: message as NSString, errorCode: errorCode)
    }
    
    // --------------------------------------------------------------------------------------------
    // MARK: Search
    // --------------------------------------------------------------------------------------------
    
    @objc func search(_ serverUrl: String, fileName: String, depth: String, date: Date?, selector: String, delegate: AnyObject) {
        
        guard let directoryID = NCManageDatabase.sharedInstance.getDirectoryID(serverUrl) else {
            return
        }
        
        // Search DAV API
            
        let metadataNet: CCMetadataNet = CCMetadataNet.init(account: appDelegate.activeAccount)
        
        metadataNet.action = actionSearch
        metadataNet.date = date
        metadataNet.delegate = delegate
        metadataNet.directoryID = directoryID
        metadataNet.fileName = fileName
        metadataNet.depth = depth
        metadataNet.priority = Operation.QueuePriority.high.rawValue
        metadataNet.selector = selector
        metadataNet.serverUrl = serverUrl

        appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
    }
    
    @objc func searchSuccess(_ metadataNet: CCMetadataNet, metadatas: [tableMetadata]) {
        
        metadataNet.delegate?.searchSuccess(metadataNet, metadatas: metadatas)
    }
    
    @objc func searchFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger) {
        
        metadataNet.delegate?.searchFailure(metadataNet, message: message, errorCode: errorCode)
    }
    
    // --------------------------------------------------------------------------------------------
    // MARK: Download Tumbnail
    // --------------------------------------------------------------------------------------------

    @objc func downloadTumbnail(_ metadata: tableMetadata, delegate: AnyObject) {
        
        let metadataNet: CCMetadataNet = CCMetadataNet.init(account: appDelegate.activeAccount)
        
        guard let serverUrl = NCManageDatabase.sharedInstance.getServerUrl(metadata.directoryID) else {
            return
        }
        
        metadataNet.action = actionDownloadThumbnail
        metadataNet.delegate = delegate
        metadataNet.fileID = metadata.fileID
        metadataNet.fileName = CCUtility.returnFileNamePath(fromFileName: metadata.fileName, serverUrl: serverUrl, activeUrl: appDelegate.activeUrl)
        metadataNet.fileNameView = metadata.fileNameView
        metadataNet.options = "m"
        metadataNet.priority = Operation.QueuePriority.low.rawValue
        metadataNet.selector = selectorDownloadThumbnail;
        metadataNet.serverUrl = serverUrl;

        appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
    }

    @objc func downloadThumbnailSuccess(_ metadataNet: CCMetadataNet) {
        
        metadataNet.delegate?.downloadThumbnailSuccess(metadataNet)
    }
    
    @objc func downloadThumbnailFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger) {
        
        NSLog("[LOG] Thumbnail Error \(metadataNet.fileName!) \(message) error %\(errorCode))")
    }

    // --------------------------------------------------------------------------------------------
    // MARK: Setting Favorite
    // --------------------------------------------------------------------------------------------
    
    @objc func settingFavorite(_ metadata: tableMetadata, favorite: Bool, delegate: AnyObject) {
        
        let metadataNet: CCMetadataNet = CCMetadataNet.init(account: appDelegate.activeAccount)
        
        guard let serverUrl = NCManageDatabase.sharedInstance.getServerUrl(metadata.directoryID) else {
            return
        }
                
        metadataNet.action = actionSettingFavorite
        metadataNet.delegate = delegate
        metadataNet.fileID = metadata.fileID
        metadataNet.fileName = CCUtility.returnFileNamePath(fromFileName: metadata.fileName, serverUrl: serverUrl, activeUrl: appDelegate.activeUrl)
        metadataNet.options = "\(favorite)"
        metadataNet.selector = selectorAddFavorite
        metadataNet.serverUrl = serverUrl;
        
        appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
    }
    
    @objc func settingFavoriteSuccess(_ metadataNet: CCMetadataNet) {
        
        metadataNet.delegate?.settingFavoriteSuccess(metadataNet)
    }
    
    @objc func settingFavoriteFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger) {
        
        appDelegate.messageNotification("_favorites_", description: message as String, visible: true, delay:TimeInterval(k_dismissAfterSecond), type:TWMessageBarMessageType.error, errorCode: errorCode)

        metadataNet.delegate?.settingFavoriteFailure(metadataNet, message: message, errorCode: errorCode)
    }

    // --------------------------------------------------------------------------------------------
    // MARK: Linsting Favorites
    // --------------------------------------------------------------------------------------------
    
    @objc func listingFavorites(_ serverUrl: String, delegate: AnyObject) {
        
        let metadataNet: CCMetadataNet = CCMetadataNet.init(account: appDelegate.activeAccount)
        
        metadataNet.action = actionListingFavorites
        metadataNet.delegate = delegate
        metadataNet.serverUrl = serverUrl
        
        appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
    }
    
    @objc func listingFavoritesSuccess(_ metadataNet: CCMetadataNet, metadatas: [tableMetadata]) {
        
        metadataNet.delegate?.listingFavoritesSuccess(metadataNet, metadatas: metadatas)
    }
    
    @objc func listingFavoritesFailure(_ metadataNet: CCMetadataNet, message: NSString, errorCode: NSInteger) {
        
        metadataNet.delegate?.listingFavoritesFailure(metadataNet, message: message, errorCode: errorCode)
    }
    
    // --------------------------------------------------------------------------------------------
    // MARK: Utility
    // --------------------------------------------------------------------------------------------
    
    @objc func deleteFile(metadata: tableMetadata, serverUrl: String) {
        
        let fileNamePath = appDelegate.directoryUser + "/" + metadata.fileID
        
        do {
            try FileManager.default.removeItem(atPath: fileNamePath)
        } catch {
            // handle error
        }
        do {
            try FileManager.default.removeItem(atPath: fileNamePath + ".ico")
        } catch {
            // handle error
        }
        
        if metadata.directory {
            let dirForDelete = CCUtility.stringAppendServerUrl(serverUrl, addFileName: metadata.fileName)
            NCManageDatabase.sharedInstance.deleteDirectoryAndSubDirectory(serverUrl: dirForDelete!)
        }
        
        NCManageDatabase.sharedInstance.deleteLocalFile(predicate: NSPredicate(format: "fileID == %@", metadata.fileID))
        NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "fileID == %@", metadata.fileID), clearDateReadDirectoryID: nil)
        // E2EE (if exists the record)
        NCManageDatabase.sharedInstance.deleteE2eEncryption(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@ AND fileNameIdentifier = %@", metadata.account, serverUrl, metadata.fileName))
    }
}




