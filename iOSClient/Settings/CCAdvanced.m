//
//  CCManageHelp.m
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 06/11/15.
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

#import "CCAdvanced.h"
#import "CCUtility.h"
#import "AppDelegate.h"
#import "NCBridgeSwift.h"

@interface CCAdvanced ()
{
    AppDelegate *appDelegate;
}
@end

@implementation CCAdvanced

-(id)init
{
    XLFormDescriptor *form ;
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTheming) name:@"changeTheming" object:nil];
    
    form = [XLFormDescriptor formDescriptorWithTitle:NSLocalizedString(@"_advanced_", nil)];

    // Section ACTIVITY -------------------------------------------------
    
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"_activity_", nil)];
    [form addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"activityVerboseHigh" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"_help_activity_verbose_", nil)];
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [row.cellConfig setObject:[UIImage imageNamed:@"settingsActivityHigh"] forKey:@"imageView.image"];
    if ([CCUtility getActivityVerboseHigh]) row.value = @"1";
    else row.value = @"0";
    [section addFormRow:row];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"sendMailActivity" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_help_activity_mail_", nil)];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:[UIColor blackColor] forKey:@"textLabel.textColor"];
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [row.cellConfig setObject:[UIImage imageNamed:@"settingsSendActivity"] forKey:@"imageView.image"];
    row.action.formSelector = @selector(sendMail:);
    [section addFormRow:row];

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"clearActivityLog" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_help_activity_clear_", nil)];
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [row.cellConfig setObject:[UIColor blackColor] forKey:@"textLabel.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:[UIImage imageNamed:@"settingsClearActivity"] forKey:@"imageView.image"];
    row.action.formSelector = @selector(clearActivity:);
    [section addFormRow:row];
    
    // Section OTTIMIZATIONS -------------------------------------------------
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section.footerTitle = NSLocalizedString(@"_optimized_photos_how_", nil);
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"optimizedphoto" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"_optimized_photos_", nil)];
    if ([CCUtility getOptimizedPhoto]) row.value = @"1";
    else row.value = @"0";
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section.footerTitle = NSLocalizedString(@"_upload_del_photos_how_", nil);
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"uploadremovephoto" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"_upload_del_photos_", nil)];
    if ([CCUtility getUploadAndRemovePhoto]) row.value = @"1";
    else row.value = @"0";
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [section addFormRow:row];

    // Section HIDDEN FILES -------------------------------------------------

    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"showHiddenFiles" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"_show_hidden_files_", nil)];
    if ([CCUtility getShowHiddenFiles]) row.value = @"1";
    else row.value = @"0";
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [section addFormRow:row];
    
    // Format Compatibility
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    section.footerTitle = NSLocalizedString(@"_format_compatibility_footer_", nil);

    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"formatCompatibility" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"_format_compatibility_", nil)];
    if ([CCUtility getFormatCompatibility]) row.value = @"1";
    else row.value = @"0";
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [section addFormRow:row];
    
    // Section CLEAR CACHE -------------------------------------------------
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // Clear cache
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"azzeracache" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_clear_cache_no_size_", nil)];
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [row.cellConfig setObject:[UIColor blackColor] forKey:@"textLabel.textColor"];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:[UIImage imageNamed:@"settingsClearCache"] forKey:@"imageView.image"];
    row.action.formSelector = @selector(clearCache:);
    [section addFormRow:row];

    // Section EXIT --------------------------------------------------------
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // Exit
    row = [XLFormRowDescriptor formRowDescriptorWithTag:@"esci" rowType:XLFormRowDescriptorTypeButton title:NSLocalizedString(@"_exit_", nil)];
    [row.cellConfig setObject:@(NSTextAlignmentLeft) forKey:@"textLabel.textAlignment"];
    [row.cellConfig setObject:[UIColor redColor] forKey:@"textLabel.textColor"];
    [row.cellConfig setObject:[UIFont systemFontOfSize:15.0]forKey:@"textLabel.font"];
    [row.cellConfig setObject:[UIImage imageNamed:@"settingsExit"] forKey:@"imageView.image"];
    row.action.formSelector = @selector(exitNextcloud:);
    [section addFormRow:row];

    return [super initWithForm:form];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _hud = [[CCHud alloc] initWithView:[[[UIApplication sharedApplication] delegate] window]];
}

// Apparirà
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = [NCBrandColor sharedInstance].backgroundView;
    self.tableView.showsVerticalScrollIndicator = NO;

    // Color
    [appDelegate aspectNavigationControllerBar:self.navigationController.navigationBar online:[appDelegate.reachability isReachable] hidden:NO];
    [appDelegate aspectTabBar:self.tabBarController.tabBar hidden:NO];
    
    [self recalculateSize];
}

- (void)changeTheming
{
    if (self.isViewLoaded && self.view.window)
        [appDelegate changeTheming:self];
}

- (void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{
    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    
    if ([rowDescriptor.tag isEqualToString:@"activityVerboseHigh"]) {
        
        [CCUtility setActivityVerboseHigh:[[rowDescriptor.value valueData] boolValue]];
        
        // Clear Date read Activity for force reload datasource
        appDelegate.activeActivity.storeDateFirstActivity = nil;
    }
    
    if ([rowDescriptor.tag isEqualToString:@"optimizedphoto"]) {
        
        [CCUtility setOptimizedPhoto:[[rowDescriptor.value valueData] boolValue]];
    }
    
    if ([rowDescriptor.tag isEqualToString:@"uploadremovephoto"]) {
        
        [CCUtility setUploadAndRemovePhoto:[[rowDescriptor.value valueData] boolValue]];
    }
    
    if ([rowDescriptor.tag isEqualToString:@"showHiddenFiles"]) {
        
        [CCUtility setShowHiddenFiles:[[rowDescriptor.value valueData] boolValue]];
        
        // force reload
        [[NCManageDatabase sharedInstance] setClearAllDateReadDirectory];
    }
    
    if ([rowDescriptor.tag isEqualToString:@"formatCompatibility"]) {
        
        [CCUtility setFormatCompatibility:[[rowDescriptor.value valueData] boolValue]];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark === Mail ===
#pragma --------------------------------------------------------------------------------------------

- (void) mailComposeController:(MFMailComposeViewController *)vc didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            [appDelegate messageNotification:@"_info_" description:@"_mail_deleted_" visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeSuccess errorCode: error.code];
            break;
        case MFMailComposeResultSaved:
            [appDelegate messageNotification:@"_info_" description:@"_mail_saved_" visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeSuccess errorCode: error.code];
            break;
        case MFMailComposeResultSent:
            [appDelegate messageNotification:@"_info_" description:@"_mail_sent_" visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeSuccess errorCode: error.code];
            break;
        case MFMailComposeResultFailed: {
            NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"_mail_failure_", nil), [error localizedDescription]];
            [appDelegate messageNotification:@"_error_" description:msg visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeError errorCode: error.code];
        }
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)sendMail:(XLFormRowDescriptor *)sender
{
    [self deselectFormRow:sender];
    
    // Email Subject
    NSString *emailTitle = NSLocalizedString(@"_information_req_", nil);
    // Email Content
    NSString *messageBody;
    // File Attachment
    NSString *fileAttachment = @"";
    // Email Recipents
    NSArray *toRecipents;
    
    NSArray *activities = [[NCManageDatabase sharedInstance] getActivityWithPredicate:[NSPredicate predicateWithFormat:@"account = %@", appDelegate.activeAccount]];
    
    if ([activities count] == 0) {
        
        [appDelegate messageNotification:@"_info_" description:@"No activity found" visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeInfo errorCode:0];
        return;
    }
    
    for (tableActivity *activity in activities) {
        
        NSString *date, *type, *actionFile, *note;
        
        date = [[NSDateFormatter localizedStringFromDate:activity.date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle] stringByPaddingToLength:22 withString:@" " startingAtIndex:0];
        
        if ([activity.type isEqual: k_activityTypeInfo])    type = @"Info   ";
        if ([activity.type isEqual: k_activityTypeSuccess]) type = @"Success";
        if ([activity.type isEqual: k_activityTypeFailure]) type = @"Failure";
        
        actionFile = [[NSString stringWithFormat:@"%@ %@", activity.action, activity.file] stringByPaddingToLength:100 withString:@" " startingAtIndex:0];
        
        if (activity.idActivity == 0) note = [NSString stringWithFormat:@"%@ Selector: %@", activity.note, activity.selector];
        else note = activity.note;
        note = [note stringByPaddingToLength:200 withString:@" " startingAtIndex:0];
        
        fileAttachment = [fileAttachment stringByAppendingString:[NSString stringWithFormat:@"| %@ | %@ | %@ | %@ |\n", date, type, actionFile, note]];
    }
    
    messageBody = [NSString stringWithFormat:@"\n\n\n%@ Version %@ (%@)", [NCBrandOptions sharedInstance].brand, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSError *error;
    
    // fix CCAdvanced.m line 276 2.17.2 (00005)
    if ([fileAttachment writeToFile:[documentsDirectory stringByAppendingPathComponent:@"activity.txt"] atomically:YES encoding:NSUTF8StringEncoding error:&error] && [MFMailComposeViewController canSendMail]) {
        
        toRecipents = [NSArray arrayWithObject:[NCBrandOptions sharedInstance].mailMe];
        
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = self;
        [mc setSubject:emailTitle];
        [mc setMessageBody:messageBody isHTML:NO];
        [mc setToRecipients:toRecipents];
        
        NSData *noteData = [NSData dataWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"activity.txt"]];
        [mc addAttachmentData:noteData mimeType:@"text/plain" fileName:@"activity.txt"];
        
        // Present mail view controller on screen
        [self presentViewController:mc animated:YES completion:NULL];
        
    } else {
        
        [appDelegate messageNotification:@"_error_" description:@"Impossible create file body" visible:YES delay:k_dismissAfterSecond type:TWMessageBarMessageTypeError errorCode:0];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark === Clear Activity ===
#pragma --------------------------------------------------------------------------------------------

- (void)clearActivity:(XLFormRowDescriptor *)sender
{
    [self deselectFormRow:sender];
    
    [[NCManageDatabase sharedInstance] clearTable:[tableActivity class] account:appDelegate.activeAccount];
        
    [appDelegate.activeActivity reloadDatasource];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark === Clear Cache ===
#pragma --------------------------------------------------------------------------------------------

- (void)removeAllFiles:(BOOL)removeIco
{
    [appDelegate maintenanceMode:YES];
    
    [self.hud visibleHudTitle:NSLocalizedString(@"_remove_cache_", nil) mode:MBProgressHUDModeIndeterminate color:nil];
    
    [[NCManageDatabase sharedInstance] clearTable:[tableQueueDownload class] account:appDelegate.activeAccount];
    [[NCManageDatabase sharedInstance] clearTable:[tableQueueUpload class] account:appDelegate.activeAccount];
    
    [appDelegate.netQueue cancelAllOperations];
    [[CCNetworking sharedNetworking] settingSessionsDownload:YES upload:YES taskStatus:k_taskStatusCancel activeAccount:appDelegate.activeAccount activeUser:appDelegate.activeUser activeUrl:appDelegate.activeUrl];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0];
        
        [[NCManageDatabase sharedInstance] clearTable:[tableActivity class] account:appDelegate.activeAccount];
        [[NCManageDatabase sharedInstance] clearTable:[tableCapabilities class] account:appDelegate.activeAccount];
        [[NCManageDatabase sharedInstance] clearTable:[tableDirectory class] account:appDelegate.activeAccount];
        [[NCManageDatabase sharedInstance] clearTable:[tableE2eEncryption class] account:appDelegate.activeAccount];
        [[NCManageDatabase sharedInstance] clearTable:[tableExternalSites class] account:appDelegate.activeAccount];
        [[NCManageDatabase sharedInstance] clearTable:[tableGPS class] account:nil];
        [[NCManageDatabase sharedInstance] clearTable:[tableLocalFile class] account:appDelegate.activeAccount];
        [[NCManageDatabase sharedInstance] clearTable:[tableMetadata class] account:appDelegate.activeAccount];
        [[NCManageDatabase sharedInstance] clearTable:[tablePhotoLibrary class] account:appDelegate.activeAccount];
        [[NCManageDatabase sharedInstance] clearTable:[tableShare class] account:appDelegate.activeAccount];
        
        [[NCAutoUpload sharedInstance] alignPhotoLibrary];
        
        [self emptyUserDirectoryUser:appDelegate.activeUser url:appDelegate.activeUrl removeIco:removeIco];
        
        [self emptyLocalDirectory];
        
        NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
        for (NSString *file in tmpDirectory)
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
        
        [self recalculateSize];
        
        [appDelegate maintenanceMode:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Close HUD
            [self.hud hideHud];
            // Inizialized home
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"initializeMain" object:nil];
        });
    });
}

- (void)clearCache:(XLFormRowDescriptor *)sender
{
    [self deselectFormRow:sender];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"_want_delete_cache_", nil) preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"_want_delete_thumbnails_", nil) preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_yes_", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               [self removeAllFiles:YES];
                                                           }]];
        
        [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_no_", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               [self removeAllFiles:NO];
                                                           }]];
        
        [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_cancel_", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            // iPhone
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            // iPad
            // Change Rect to position Popover
            UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:alertController];
            [popup presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:[self.form indexPathOfFormRow:sender]] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }]];

    [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_cancel_", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // iPhone
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        // iPad
        // Change Rect to position Popover
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:alertController];
        [popup presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:[self.form indexPathOfFormRow:sender]] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)recalculateSize
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        self.form.delegate = nil;
        
        XLFormRowDescriptor *rowAzzeraCache = [self.form formRowWithTag:@"azzeracache"];
        
        NSString *size = [CCUtility transformedSize:[[self getUserDirectorySize] longValue]];
        rowAzzeraCache.title = [NSString stringWithFormat:NSLocalizedString(@"_clear_cache_", nil), size];
        //rowAzzeraCache.title = NSLocalizedString(@"_clear_cache_no_size_", nil);
        
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        
        self.form.delegate = self;
    });
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark == Exit Nextcloud ==
#pragma --------------------------------------------------------------------------------------------

- (void)exitNextcloud:(XLFormRowDescriptor *)sender
{
    [self deselectFormRow:sender];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"_want_exit_", nil) preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        [self.hud visibleIndeterminateHud];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
            
            [appDelegate.netQueue cancelAllOperations];
            [[CCNetworking sharedNetworking] settingSessionsDownload:YES upload:YES taskStatus:k_taskStatusCancel activeAccount:appDelegate.activeAccount activeUser:appDelegate.activeUser activeUrl:appDelegate.activeUrl];
            
            [[NSURLCache sharedURLCache] setMemoryCapacity:0];
            [[NSURLCache sharedURLCache] setDiskCapacity:0];
            
            [[CCNetworking sharedNetworking] invalidateAndCancelAllSession];
                        
            [[NCManageDatabase sharedInstance] removeDB];
            
            [CCUtility deleteAllChainStore];
            
            [self emptyDocumentsDirectory];
            
            [self emptyLibraryDirectory];
            
            [self emptyGroupApplicationSupport];
            
            NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
            for (NSString *file in tmpDirectory)
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
            
            [self.hud hideHud];
            
            exit(0);
        });
    }]];
    
    [alertController addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"_cancel_", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // iPhone
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        // iPad
        // Change Rect to position Popover
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:alertController];
        [popup presentPopoverFromRect:[self.tableView rectForRowAtIndexPath:[self.form indexPathOfFormRow:sender]] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark == Utility ==
#pragma --------------------------------------------------------------------------------------------

- (void)emptyGroupApplicationSupport
{
    NSString *file;
    NSURL *dirGroup = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[NCBrandOptions sharedInstance].capabilitiesGroups];
    NSString *dirIniziale = [[dirGroup URLByAppendingPathComponent:appApplicationSupport] path];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dirIniziale];
    
    while (file = [enumerator nextObject])
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", dirIniziale, file] error:nil];
}

- (void)emptyLibraryDirectory
{
    NSString *file;
    NSString *dirIniziale;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    dirIniziale = [paths objectAtIndex:0];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dirIniziale];
    
    while (file = [enumerator nextObject])
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", dirIniziale, file] error:nil];
}

- (void)emptyDocumentsDirectory
{
    NSString *file;
    NSString *dirIniziale;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    dirIniziale = [paths objectAtIndex:0];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dirIniziale];
    
    while (file = [enumerator nextObject])
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", dirIniziale, file] error:nil];
}

- (void)emptyUserDirectoryUser:(NSString *)user url:(NSString *)url removeIco:(BOOL)removeIco
{
    NSString *file;
    NSString *dirIniziale;
    
    dirIniziale = [CCUtility getDirectoryActiveUser:user activeUrl:url];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dirIniziale];
    
    while (file = [enumerator nextObject]) {
        
        NSString *ext = [[file pathExtension] lowercaseString];
        
        // Do not remove ICO
        if ([ext isEqualToString:@"ico"] && !removeIco)
            continue;
        
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", dirIniziale, file] error:nil];
    }
}

- (void)emptyLocalDirectory
{
    NSString *file;
    NSString *dirIniziale;
    
    dirIniziale = [CCUtility getDirectoryLocal];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dirIniziale];
    
    while (file = [enumerator nextObject])
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", dirIniziale, file] error:nil];
}

- (NSNumber *)getUserDirectorySize
{
    NSString *directoryUser = [CCUtility getDirectoryActiveUser:appDelegate.activeUser activeUrl:appDelegate.activeUrl];
    NSURL *directoryURL = [NSURL fileURLWithPath:directoryUser];
    unsigned long long count = 0;
    NSNumber *value = nil;
    
    if (! directoryURL) return 0;
    
    // Get dimension Document
    for (NSURL *url in [[NSFileManager defaultManager] enumeratorAtURL:directoryURL includingPropertiesForKeys:@[NSURLFileSizeKey] options:0 errorHandler:NULL]) {
        if ([url getResourceValue:&value forKey:NSURLFileSizeKey error:nil]) {
            count += [value longLongValue];
        } else {
            return nil;
        }
    }
    
    return @(count);
}

@end
