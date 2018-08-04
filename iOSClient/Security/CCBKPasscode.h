//
//  CCBKPasscode.h
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 07/11/14.
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

#import "BKPasscodeViewController.h"
#import "BKPasscodeInputView.h"

typedef enum : NSUInteger {
    CCBKPasscodeFromLockScreen,
    CCBKPasscodeFromPasscode,
    CCBKPasscodeFromInit,
    CCBKPasscodeFromLockDirectory,
    CCBKPasscodeFromDisactivateDirectory,
    CCBKPasscodeFromStartEncryption,
    CCBKPasscodeFromCheckPassphrase,
    CCBKPasscodeFromRemoveEncryption,
    CCBKPasscodeFromSettingsPasscode,
    CCBKPasscodeFromSimply
} CCBKPasscodeTypeFrom;

@class CCBKPasscode;

@interface CCBKPasscode : BKPasscodeViewController <BKPasscodeInputViewDelegate, BKTouchIDSwitchViewDelegate, BKPasscodeFieldImageSource>

+ (id)sharedInstance;

@property (nonatomic) CCBKPasscodeTypeFrom fromType;
@property (nonatomic, assign) int numberInstance;

@end
