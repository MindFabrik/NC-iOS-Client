//
//  CCGraphics.h
//  Nextcloud
//
//  Created by Marino Faggiana on 04/02/16.
//  Copyright (c) 2016 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#import "CCGlobal.h"

@interface CCGraphics : NSObject

+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

+ (void)createNewImageFrom:(NSString *)fileName ocId:(NSString *)ocId etag:(NSString *)etag typeFile:(NSString *)typeFile;
+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)targetSize isAspectRation:(BOOL)aspect;

+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (UIImage *)changeThemingColorImage:(UIImage *)image multiplier:(NSInteger)multiplier color:(UIColor *)color;
+ (UIImage *)changeThemingColorImage:(UIImage *)image width:(CGFloat)width height:(CGFloat)height color:(UIColor *)color;

+ (UIImage*)drawText:(NSString*)text inImage:(UIImage*)image colorText:(UIColor *)colorText sizeOfFont:(CGFloat)sizeOfFont;

+ (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur toSize:(CGSize)toSize;

+ (BOOL)isLight:(UIColor *)color;

+ (UIImage *)generateSinglePixelImageWithColor:(UIColor *)color;

+ (void)addImageToTitle:(NSString *)title colorTitle:(UIColor *)colorTitle imageTitle:(UIImage *)imageTitle imageRight:(BOOL)imageRight navigationItem:(UINavigationItem *)navigationItem;

+ (void)settingThemingColor:(NSString *)themingColor themingColorElement:(NSString *)themingColorElement themingColorText:(NSString *)themingColorText;

@end

@interface CCAvatar : UIImageView

- (id)initWithImage:(UIImage *)image borderColor:(UIColor*)borderColor borderWidth:(float)borderWidth;

@end
