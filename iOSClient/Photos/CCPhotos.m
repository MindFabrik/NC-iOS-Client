//
//  CCPhotos.m
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 29/07/15.
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

#import "CCPhotos.h"
#import "AppDelegate.h"
#import "CCManageAutoUpload.h"
#import "TOScrollBar.h"
#import "NCBridgeSwift.h"

@interface CCPhotos () <CCActionsDeleteDelegate, CCActionsDownloadThumbnailDelegate>
{
    AppDelegate *appDelegate;

    tableMetadata *_metadata;

    BOOL _cellEditing;
    NSMutableArray *_queueMetadatas;
    NSMutableArray *_selectedMetadatas;
    NSUInteger _numSelectedMetadatas;
    
    NSDate *_dateReadDataSource;
    CCSectionDataSourceMetadata *_sectionDataSource;
    
    CCHud *_hud;
    
    TOScrollBar *_scrollBar;
}
@end

@implementation CCPhotos

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Init =====
#pragma --------------------------------------------------------------------------------------------

-  (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])  {
        
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerProgressTask:) name:@"NotificationProgressTask" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTheming) name:@"changeTheming" object:nil];
        
        appDelegate.activePhotos = self;
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    
    return self;
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== View =====
#pragma --------------------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _queueMetadatas = [[NSMutableArray alloc] init];
    _selectedMetadatas = [[NSMutableArray alloc] init];
    _hud = [[CCHud alloc] initWithView:[[[UIApplication sharedApplication] delegate] window]];
    
    // empty Data Source
    self.collectionView.emptyDataSetDelegate = self;
    self.collectionView.emptyDataSetSource = self;

    // scroll bar
    _scrollBar = [TOScrollBar new];
    [self.collectionView to_addScrollBar:_scrollBar];
    
    _scrollBar.handleTintColor = [NCBrandColor sharedInstance].brand;
    _scrollBar.handleWidth = 20;
    _scrollBar.handleMinimiumHeight = 20;
    _scrollBar.trackWidth = 0;
    _scrollBar.edgeInset = 12;
}

// Apparirà
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Color
    [appDelegate aspectNavigationControllerBar:self.navigationController.navigationBar online:[appDelegate.reachability isReachable] hidden:NO];
    [appDelegate aspectTabBar:self.tabBarController.tabBar hidden:NO];
    
    // Plus Button
    [appDelegate plusButtonVisibile:true];

    
    [self reloadDatasource];
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    
    self.collectionView.contentInset = self.view.safeAreaInsets;
}

- (void)changeTheming
{
    if (self.isViewLoaded && self.view.window)
        [appDelegate changeTheming:self];
    
    _scrollBar.handleTintColor = [NCBrandColor sharedInstance].brand;
    [self.collectionView reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Before rotation
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        if (self.view.frame.size.width == ([[UIScreen mainScreen] bounds].size.width*([[UIScreen mainScreen] bounds].size.width<[[UIScreen mainScreen] bounds].size.height))+([[UIScreen mainScreen] bounds].size.height*([[UIScreen mainScreen] bounds].size.width>[[UIScreen mainScreen] bounds].size.height))) {
            
            // Portrait
            
        } else {
            
            // Landscape
        }
        
    }];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Gestione Grafica Window =====
#pragma --------------------------------------------------------------------------------------------

- (void)setUINavigationBarDefault
{
    [appDelegate aspectNavigationControllerBar:self.navigationController.navigationBar online:[appDelegate.reachability isReachable] hidden:NO];
    
    // select
    UIImage *icon = [UIImage imageNamed:@"seleziona"];
    UIBarButtonItem *buttonSelect = [[UIBarButtonItem alloc] initWithImage:icon style:UIBarButtonItemStylePlain target:self action:@selector(collectionSelectYES)];
    
    if ([_sectionDataSource.allRecordsDataSource count] > 0) {
        
        self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:buttonSelect, nil];
        
    } else {
        
        self.navigationItem.rightBarButtonItems = nil;
    }
    
    self.navigationItem.leftBarButtonItem = nil;
    
    // Title
    self.navigationItem.title = NSLocalizedString(@"_photo_camera_", nil);
}

- (void)setUINavigationBarSelected
{
    UIImage *icon;
    
    icon = [UIImage imageNamed:@"deleteSelectedFiles"];
    UIBarButtonItem *buttonDelete = [[UIBarButtonItem alloc] initWithImage:icon style:UIBarButtonItemStylePlain target:self action:@selector(deleteSelectedFiles)];
    
    icon = [UIImage imageNamed:@"openSelectedFiles"];
    UIBarButtonItem *buttonOpenWith = [[UIBarButtonItem alloc] initWithImage:icon style:UIBarButtonItemStylePlain target:self action:@selector(openSelectedFiles)];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"_cancel_", nil) style:UIBarButtonItemStylePlain target:self action:@selector(reloadCollection)];
    
    self.navigationItem.leftBarButtonItem = leftButton;
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:buttonDelete, buttonOpenWith, nil];
    
    // Title
    self.navigationItem.title = [NSString stringWithFormat:@"%@ : %lu / %lu", NSLocalizedString(@"_selected_", nil), (unsigned long)[_selectedMetadatas count], (unsigned long)[_sectionDataSource.allRecordsDataSource count]];
}

- (void)collectionSelect:(BOOL)edit
{
    [self.collectionView setAllowsMultipleSelection:edit];
    
    _cellEditing = edit;
    
    if (edit)
        [self setUINavigationBarSelected];
    else
        [self setUINavigationBarDefault];
}

- (void)collectionSelectYES
{
    [self collectionSelect:YES];
}

- (void)cellSelect:(BOOL)select indexPath:(NSIndexPath *)indexPath metadata:(tableMetadata *)metadata
{
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    UIVisualEffectView *effect = [cell viewWithTag:200];
    UIImageView *checked = [cell viewWithTag:300];
    
    if (select) {
        effect.hidden = NO;
        effect.alpha = 0.4;
        checked.hidden = NO;
        [_selectedMetadatas addObject:metadata];
        
    } else {
        effect.hidden = YES;
        checked.hidden = YES;
        [_selectedMetadatas removeObject:metadata];
    }
    
    // Title
    self.navigationItem.title = [NSString stringWithFormat:@"%@ : %lu / %lu", NSLocalizedString(@"_selected_", nil), (unsigned long)[_selectedMetadatas count], (unsigned long)[_sectionDataSource.allRecordsDataSource count]];
}

- (void)scrollToTop
{
    [self.collectionView setContentOffset:CGPointMake(0, - self.collectionView.contentInset.top) animated:NO];
}

- (void)getGeoLocationForSection:(NSInteger)section
{
    NSString *addLocation = @"";
    
    NSArray *fileIDsForKey = [_sectionDataSource.sectionArrayRow objectForKey:[_sectionDataSource.sections objectAtIndex:section]];
    
    for (NSString *fileID in fileIDsForKey) {
    
        tableLocalFile *localFile = [[NCManageDatabase sharedInstance] getTableLocalFileWithPredicate:[NSPredicate predicateWithFormat:@"fileID = %@", fileID]];
    
        if ([localFile.exifLatitude floatValue] > 0 || [localFile.exifLongitude floatValue] > 0) {
        
            NSString *location = [[NCManageDatabase sharedInstance] getLocationFromGeoLatitude:localFile.exifLatitude longitude:localFile.exifLongitude];
            
            addLocation = [NSString stringWithFormat:@"%@, %@", addLocation, location];
        
        }
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ==== DZNEmptyDataSetSource Methods ====
#pragma --------------------------------------------------------------------------------------------

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [NCBrandColor sharedInstance].backgroundView;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [CCGraphics changeThemingColorImage:[UIImage imageNamed:@"photosNoRecord"] color:[NCBrandColor sharedInstance].brandElement];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = [NSString stringWithFormat:@"\n%@", NSLocalizedString(@"_tutorial_photo_view_", nil)];
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:20.0f], NSForegroundColorAttributeName:[UIColor lightGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    NSString *text;
    tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];
    
    if (account.autoUpload)
        text = [NSString stringWithFormat:@"%@", @"\n\n\n\n"];
    else
        text = [NSString stringWithFormat:@"\n%@\n", NSLocalizedString(@"_tutorial_autoupload_view_", nil)];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0], NSForegroundColorAttributeName: [UIColor lightGrayColor], NSParagraphStyleAttributeName: paragraph};

    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)buttonImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    tableAccount *account = [[NCManageDatabase sharedInstance] getAccountActive];
            
    if (!account.autoUpload) {
    
        UIImage *buttonImage = [CCGraphics changeThemingColorImage:[UIImage imageNamed:@"button1000x200"] color:[NCBrandColor sharedInstance].brandElement];
        
        return [CCGraphics drawText:NSLocalizedString(@"_activate_autoupload_", nil) inImage:buttonImage colorText:[UIColor whiteColor] sizeOfFont:26];
        
    } else return nil;
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{    
    CCManageAutoUpload *viewController = [[CCManageAutoUpload alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [navigationController setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== openSelectedFiles =====
#pragma--------------------------------------------------------------------------------------------

- (void)openSelectedFiles
{
    NSMutableArray *dataToShare = [[NSMutableArray alloc] init];
    
    for (tableMetadata *metadata in _selectedMetadatas) {
    
        NSString *fileNamePath = [NSTemporaryDirectory() stringByAppendingString:metadata.fileName];
        
        [[NSFileManager defaultManager] linkItemAtPath:[NSString stringWithFormat:@"%@/%@", appDelegate.directoryUser, metadata.fileID] toPath:fileNamePath error:nil];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileNamePath]) {
            
            if ([metadata.typeFile isEqualToString: k_metadataTypeFile_image]) {
                
                NSData *data = [NSData dataWithData:UIImageJPEGRepresentation([UIImage imageWithContentsOfFile:fileNamePath], 0.9)];
                [dataToShare addObject:data];
            }
            
            if ([metadata.typeFile isEqualToString: k_metadataTypeFile_video]) {
                
                [dataToShare addObject:[NSURL fileURLWithPath:fileNamePath]];
            }
        }
    }
    
    if ([dataToShare count] > 0) {
        
        UIActivityViewController* activityViewController = [[UIActivityViewController alloc] initWithActivityItems:dataToShare applicationActivities:nil];
        
        // iPad
        activityViewController.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
        
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [self presentViewController:activityViewController animated:YES completion:^{
            
            [activityViewController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                
                self.navigationItem.leftBarButtonItem.enabled = YES;
                self.navigationItem.rightBarButtonItem.enabled = YES;
                
                if (completed) {
                    
                    [self performSelector:@selector(reloadCollection) withObject:nil];
                }
            }];
        }];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Download =====
#pragma--------------------------------------------------------------------------------------------

- (void)downloadFileSuccessFailure:(NSString *)fileName fileID:(NSString *)fileID serverUrl:(NSString *)serverUrl selector:(NSString *)selector selectorPost:(NSString *)selectorPost errorMessage:(NSString *)errorMessage errorCode:(NSInteger)errorCode
{
    if (errorCode == 0) {
        
        NSIndexPath *indexPath;
        BOOL existsIcon = NO;
        
        if (fileID) {
            existsIcon = [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@.ico", appDelegate.directoryUser, fileID]];
            indexPath = [_sectionDataSource.fileIDIndexPath objectForKey:fileID];
        }
        
        if ([self indexPathIsValid:indexPath] && existsIcon) {
            
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            
            if (cell) {
                UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
                UIVisualEffectView *effect = [cell viewWithTag:200];
                UIImageView *checked = [cell viewWithTag:300];
                
                imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.ico", appDelegate.directoryUser, fileID]];
                effect.hidden = YES;
                checked.hidden = YES;
            }
        }
        
    } else {
        
        [appDelegate messageNotification:@"_download_selected_files_" description:@"_error_download_photobrowser_" visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeError errorCode:errorCode];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Delete =====
#pragma--------------------------------------------------------------------------------------------

- (void)deleteFileOrFolderSuccessFailure:(CCMetadataNet *)metadataNet message:(NSString *)message errorCode:(NSInteger)errorCode
{
    [_queueMetadatas removeObject:metadataNet.selector];
    
    if ([_queueMetadatas count] == 0) {
        
        [_hud hideHud];

        if ([_selectedMetadatas count] > 0) {
            
            [_selectedMetadatas removeObjectAtIndex:0];
            
            if ([_selectedMetadatas count] > 0) {
                
                [self deleteFileOrFolder:[_selectedMetadatas objectAtIndex:0] numFile:[_selectedMetadatas count] ofFile:_numSelectedMetadatas];
                
            } else {
                
                [self reloadDatasourceForced];
            }
            
        } else {
            
            [self reloadDatasourceForced];
        }
    }
}

- (void)deleteFileOrFolder:(tableMetadata *)metadata numFile:(NSInteger)numFile ofFile:(NSInteger)ofFile
{
    [_queueMetadatas addObject:selectorDelete];
    
    [[CCActions sharedInstance] deleteFileOrFolder:metadata delegate:self hud:_hud hudTitled:[NSString stringWithFormat:NSLocalizedString(@"_delete_file_n_", nil), ofFile - numFile + 1, ofFile]];
}

- (void)deleteSelectedFiles
{
    [_queueMetadatas removeAllObjects];
    
    _numSelectedMetadatas = [_selectedMetadatas count];
    
    if ([_selectedMetadatas count] == 0)
        return;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_delete_", nil)
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *action) {
                                                           [self deleteFileOrFolder:[_selectedMetadatas objectAtIndex:0] numFile:[_selectedMetadatas count] ofFile:_numSelectedMetadatas];
                                                       }]];
    
    [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_cancel_", nil)
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action) {
                                                           [alertController dismissViewControllerAnimated:YES completion:nil];
                                                       }]];
    
    alertController.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [alertController.view layoutIfNeeded];
    
    [self presentViewController:alertController animated:YES completion:NULL];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ==== Download Thumbnail Delegate ====
#pragma --------------------------------------------------------------------------------------------

- (void)downloadThumbnailSuccess:(CCMetadataNet *)metadataNet
{
    // Check Active Account
    if (![metadataNet.account isEqualToString:appDelegate.activeAccount])
        return;
    
    NSIndexPath *indexPath = [_sectionDataSource.fileIDIndexPath objectForKey:metadataNet.fileID];
    
    if ([self indexPathIsValid:indexPath]) {
    
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@.ico", appDelegate.directoryUser, metadataNet.fileID]])
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

- (void)triggerProgressTask:(NSNotification *)notification
{
    //NSDictionary *dict = notification.userInfo;
    //float progress = [[dict valueForKey:@"progress"] floatValue];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ==== Collection ====
#pragma --------------------------------------------------------------------------------------------

- (void)reloadDatasourceForced
{
    [CCSectionMetadata removeAllObjectsSectionDataSource:_sectionDataSource];
    _dateReadDataSource = nil;
    [self reloadDatasource];
}

- (void)reloadDatasource
{    
    // test
    if (appDelegate.activeAccount.length == 0)
        return;
    
    _directoryStartDatasource = [[NCManageDatabase sharedInstance] getAccountAutoUploadPath:appDelegate.activeUrl];
    NSDate *dateDateRecordDirectory = nil;
    
    NSArray *directories = [[NCManageDatabase sharedInstance] getTablesDirectoryWithPredicate:[NSPredicate predicateWithFormat:@"account = %@ AND serverUrl BEGINSWITH %@", appDelegate.activeAccount, _directoryStartDatasource] sorted:@"dateReadDirectory" ascending:false];
    if ([directories count] > 0) {
        tableDirectory *directory = [directories objectAtIndex:0];
        dateDateRecordDirectory = directory.dateReadDirectory;
    }
    
    if ([dateDateRecordDirectory compare:_dateReadDataSource] == NSOrderedDescending || dateDateRecordDirectory == nil || _dateReadDataSource == nil) {

        NSLog(@"[LOG] Photos rebuild Data Source serverUrl : %@", _directoryStartDatasource);

        _dateReadDataSource = [NSDate date];
        NSArray *results = [[NCManageDatabase sharedInstance] getTableMetadatasPhotosWithServerUrl:_directoryStartDatasource];
        _sectionDataSource = [CCSectionMetadata creataDataSourseSectionMetadata:results listProgressMetadata:nil e2eEncryptions:nil groupByField:@"date" activeAccount:appDelegate.activeAccount];
        
        [self reloadCollection];
    }
}

- (void)reloadCollection
{
    [self.collectionView reloadData];
        
    [_selectedMetadatas removeAllObjects];
    [self collectionSelect:NO];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{    
    return [[_sectionDataSource.sectionArrayRow allKeys] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[_sectionDataSource.sectionArrayRow objectForKey:[_sectionDataSource.sections objectAtIndex:section]] count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIInterfaceOrientation orientationOnLunch = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientationOnLunch == UIInterfaceOrientationPortrait)
        return CGSizeMake(collectionView.frame.size.width / 5.1f, collectionView.frame.size.width / 5.1f);
    else
        return CGSizeMake(collectionView.frame.size.width / 7.1f, collectionView.frame.size.width / 7.1f);
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if ([_sectionDataSource.sections count] - 1 == section)
        return CGSizeMake(collectionView.frame.size.width, 50);
    
    return CGSizeZero;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        
        //headerView.backgroundColor = COLOR_GROUPBY_BAR_NO_BLUR;
        
        [self getGeoLocationForSection:indexPath.section];
        
        UILabel *titleLabel = (UILabel *)[headerView viewWithTag:100];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.text = [CCUtility getTitleSectionDate:[_sectionDataSource.sections objectAtIndex:indexPath.section]];

        return headerView;
    }
    
    if (kind == UICollectionElementKindSectionFooter) {
        
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"footer" forIndexPath:indexPath];
        
        UILabel *titleLabel = (UILabel *)[footerView viewWithTag:100];
        titleLabel.textColor = [UIColor grayColor];
        titleLabel.text = [NSString stringWithFormat:@"%lu %@, %lu %@", (long)_sectionDataSource.image, NSLocalizedString(@"photo", nil), (long)_sectionDataSource.video, NSLocalizedString(@"_video_", nil)];
        
        return footerView;
    }
    
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
    UIVisualEffectView *effect = [cell viewWithTag:200];

    UIImageView *checked = [cell viewWithTag:300];
    checked.image = [UIImage imageNamed:@"checked"];

    NSArray *metadatasForKey = [_sectionDataSource.sectionArrayRow objectForKey:[_sectionDataSource.sections objectAtIndex:indexPath.section]];
    
    if ([metadatasForKey count] > indexPath.row) {
        
        NSString *fileID = [metadatasForKey objectAtIndex:indexPath.row];
        tableMetadata *metadata = [_sectionDataSource.allRecordsDataSource objectForKey:fileID];
    
        // Image
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@.ico", appDelegate.directoryUser, metadata.fileID]]) {
        
            // insert Image
            imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.ico", appDelegate.directoryUser, metadata.fileID]];
        
        } else {
        
            // Thumbnail not present
            imageView.image = [UIImage imageNamed:@"file_photo"];
        
            if (metadata.thumbnailExists)
                [[CCActions sharedInstance] downloadTumbnail:metadata delegate:self];
        }
    
        // Cheched
        if (cell.selected) {
            checked.hidden = NO;
            effect.hidden = NO;
            effect.alpha = 0.4;
        } else {
            checked.hidden = YES;
            effect.hidden = YES;
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *metadatasForKey = [_sectionDataSource.sectionArrayRow objectForKey:[_sectionDataSource.sections objectAtIndex:indexPath.section]];
    
    if ([metadatasForKey count] > indexPath.row) {
        
        NSString *fileID = [metadatasForKey objectAtIndex:indexPath.row];
        _metadata = [_sectionDataSource.allRecordsDataSource objectForKey:fileID];
        
        if (_cellEditing) {
        
            [self cellSelect:YES indexPath:indexPath metadata:_metadata];
        
        } else {
        
            if ([self shouldPerformSegue])
                [self performSegueWithIdentifier:@"segueDetail" sender:self];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_cellEditing == NO)
        return;
    
    NSArray *metadatasForKey = [_sectionDataSource.sectionArrayRow objectForKey:[_sectionDataSource.sections objectAtIndex:indexPath.section]];
    
    if ([metadatasForKey count] > indexPath.row) {
        
        NSString *fileID = [metadatasForKey objectAtIndex:indexPath.row];
        _metadata = [_sectionDataSource.allRecordsDataSource objectForKey:fileID];
        
        [self cellSelect:NO indexPath:indexPath metadata:_metadata];
    }
}

- (BOOL)indexPathIsValid:(NSIndexPath *)indexPath
{
    if (!indexPath)
        return NO;
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    NSInteger lastSectionIndex = [self numberOfSectionsInCollectionView:self.collectionView] - 1;
    
    if (section > lastSectionIndex || lastSectionIndex < 0)
        return NO;
    
    NSInteger rowCount = [self.collectionView numberOfItemsInSection:indexPath.section] - 1;
    
    if (rowCount < 0)
        return NO;
    
    return row <= rowCount;
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== Navigation ====
#pragma --------------------------------------------------------------------------------------------

- (BOOL)shouldPerformSegue
{
    // Test
    
    // Background ? exit
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
        return NO;
    
    // Not in first plain ? exit
    if (self.view.window == NO)
        return NO;
    
    // Collapsed but in first plain in detail exit
    if (self.splitViewController.isCollapsed)
        if (self.detailViewController.isViewLoaded && self.detailViewController.view.window)
            return NO;
    
    // ok perform segue
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    id controller = segue.destinationViewController;
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = controller;
        self.detailViewController = (CCDetail *)navigationController.topViewController;
    } else {
        self.detailViewController = segue.destinationViewController;
    }
    
    NSMutableArray *allRecordsDataSourceImagesVideos = [[NSMutableArray alloc] init];
    for (NSString *fileID in _sectionDataSource.allEtag) {
        tableMetadata *metadata = [_sectionDataSource.allRecordsDataSource objectForKey:fileID];
        if ([metadata.typeFile isEqualToString: k_metadataTypeFile_image] || [metadata.typeFile isEqualToString: k_metadataTypeFile_video])
            [allRecordsDataSourceImagesVideos addObject:metadata];
    }
    
    self.detailViewController.dataSourceImagesVideos = allRecordsDataSourceImagesVideos;
    self.detailViewController.metadataDetail = _metadata;
    self.detailViewController.dateFilterQuery = _metadata.date;
    
    [self.detailViewController setTitle:_metadata.fileName];
}

@end
