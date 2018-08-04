//
//  NCBrandColor.swift
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 24/04/17.
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

import UIKit

class NCBrandColor: NSObject {

    @objc static let sharedInstance: NCBrandColor = {
        let instance = NCBrandColor()
        return instance
    }()

    // Color
    @objc public let customer:              UIColor = UIColor(red:0.580, green:0.278, blue:0.090, alpha:1.0)    // BLU NC : #d30018
    @objc public var customerText:          UIColor = .white
    
    @objc public var brand:                 UIColor                                                                                 // don't touch me
    @objc public var brandElement:          UIColor                                                                                 // don't touch me
    @objc public var brandText:             UIColor                                                                                 // don't touch me

    @objc public var connectionNo:          UIColor = UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    @objc public var encrypted:             UIColor = .red
    @objc public var backgroundView:        UIColor = .white
    @objc public var textView:              UIColor = .black
    @objc public var seperator:             UIColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    @objc public var tabBar:                UIColor = .white
    @objc public var transferBackground:    UIColor = UIColor(red: 178.0/255.0, green: 244.0/255.0, blue: 258.0/255.0, alpha: 0.1)
    @objc public let nextcloud:             UIColor = UIColor(red: 0.0/255.0, green: 130.0/255.0, blue: 201.0/255.0, alpha: 1.0)

    override init() {
        self.brand = self.customer
        self.brandElement = self.customer
        self.brandText = self.customerText
    }
    
    // Color modify
    @objc public func getColorSelectBackgrond() -> UIColor {
        return self.brand.withAlphaComponent(0.1)
    }
}

@objc class NCBrandOptions: NSObject {
    
    @objc static let sharedInstance: NCBrandOptions = {
        let instance = NCBrandOptions()
        return instance
    }()
    
    @objc public let brand:                           String = "MFDev Cloud"
    @objc public let mailMe:                          String = "support@mindfabrik.de"
    @objc public let textCopyrightNextcloudiOS:       String = "MFDev Cloud for iOS %@ © 2018 MindFabrik."
    @objc public let textCopyrightNextcloudServer:    String = "Cloud Server %@"
    @objc public let loginBaseUrl:                    String = "https://server.com"
    @objc public let pushNotificationServer:          String = "https://push-notifications.nextcloud.com"
    @objc public let linkLoginProvider:               String = "https://nextcloud.com/providers"
    @objc public let textLoginProvider:               String = "_login_bottom_label_"
    @objc public let middlewarePingUrl:               String = ""
    @objc public let webLoginAutenticationProtocol:   String = "nc://"                                          // example "abc://"
    // Personalized
    @objc public let webCloseViewProtocolPersonalized:String = ""                                               // example "abc://change/plan"      Don't touch me !!
    @objc public let folderBrandAutoUpload:           String = ""                                               // example "_auto_upload_folder_"   Don't touch me !!

    // Auto Upload default folder
    @objc public var folderDefaultAutoUpload:         String = "Photos"
    
    // Capabilities Group
    @objc public let capabilitiesGroups:              String = "group.de.mindfabrik.mfdev.crypto-cloud"
    
    // Options
    @objc public let use_login_web_personalized:      Bool = false                                              // Don't touch me !!
    @objc public let use_firebase:                    Bool = false
    @objc public let use_default_auto_upload:         Bool = false
    @objc public let use_themingColor:                Bool = true
    @objc public let use_themingBackground:           Bool = true
    @objc public let use_middlewarePing:              Bool = false
    @objc public let use_storeLocalAutoUploadAll:     Bool = false
    
    @objc public let disable_intro:                   Bool = true
    @objc public let disable_linkLoginProvider:       Bool = true
    @objc public let disable_request_login_url:       Bool = true
    @objc public let disable_multiaccount:            Bool = true
    @objc public let disable_manage_account:          Bool = true
    @objc public let disable_more_external_site:      Bool = true
    
    // MindFabrik Options:
    @objc public let mindfabrik_force_lockfeature:    Bool = true
    
    override init() {
        
        if folderBrandAutoUpload != "" {
            
            self.folderDefaultAutoUpload = self.folderBrandAutoUpload
        }
    }
}

