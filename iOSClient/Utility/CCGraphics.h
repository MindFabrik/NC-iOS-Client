//
//  CCGraphics.h
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 04/02/16.
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#import "CCGlobal.h"

@interface CCGraphics : NSObject

+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

+ (UIImage *)createNewImageFrom:(NSString *)fileName directoryUser:(NSString *)directoryUser fileNameTo:(NSString *)fileNameTo extension:(NSString *)extension size:(NSString *)size imageForUpload:(BOOL)imageForUpload typeFile:(NSString *)typeFile writePreview:(BOOL)writePreview optimizedFileName:(BOOL)optimizedFileName;

+ (void)saveIcoWithEtag:(NSString *)fileID image:(UIImage *)image writeToFile:(NSString *)writeToFile copy:(BOOL)copy move:(BOOL)move fromPath:(NSString *)fromPath toPath:(NSString *)toPath;

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)targetSize;
+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)targetSize isAspectRation:(BOOL)aspect;

+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (UIImage *)changeThemingColorImage:(UIImage *)image color:(UIColor *)color;

+ (UIImage*)drawText:(NSString*)text inImage:(UIImage*)image colorText:(UIColor *)colorText sizeOfFont:(CGFloat)sizeOfFont;

+ (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur toSize:(CGSize)toSize;

+ (BOOL)isLight:(UIColor *)color;

+ (UIImage *)generateSinglePixelImageWithColor:(UIColor *)color;

+ (void)addImageToTitle:(NSString *)title colorTitle:(UIColor *)colorTitle imageTitle:(UIImage *)imageTitle navigationItem:(UINavigationItem *)navigationItem;

+ (void)settingThemingColor:(NSString *)themingColor themingColorElement:(NSString *)themingColorElement themingColorText:(NSString *)themingColorText;

@end

@interface CCAvatar : UIImageView

- (id)initWithImage:(UIImage *)image borderColor:(UIColor*)borderColor borderWidth:(float)borderWidth;

@end
