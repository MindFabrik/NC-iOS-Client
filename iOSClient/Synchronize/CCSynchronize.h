//
//  CCSynchronize.h
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 19/10/16.
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

#import <Foundation/Foundation.h>

#import "CCHud.h"
#import "CCCellMain.h"

@class tableMetadata;

@interface CCSynchronize : NSObject

@property (nonatomic, strong) CCHud *hud;

+ (CCSynchronize *)sharedSynchronize;

@property (nonatomic, strong) NSMutableOrderedSet *foldersInSynchronized;

- (void)readFolder:(NSString *)serverUrl selector:(NSString *)selector;
- (void)readFileForFolder:(NSString *)fileName serverUrl:(NSString *)serverUrl selector:(NSString *)selector;
- (void)readFile:(tableMetadata *)metadata selector:(NSString *)selector;

- (void)verifyChangeMedatas:(NSArray *)allRecordMetadatas serverUrl:(NSString *)serverUrl account:(NSString *)account withDownload:(BOOL)withDownload;

@end
