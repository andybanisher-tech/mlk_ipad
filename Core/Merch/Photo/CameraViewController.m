//
//  CameraViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 22.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "CameraViewController.h"
#import "FilesStorageWorker.h"
#import "UniformTypeIdentifiers/UniformTypeIdentifiers.h"

@implementation CameraViewController

static sqlite3 *database = nil;

@synthesize imageView, toolbar, isViewPushed, isFirstLoadOfTheView, inVisit;
@synthesize photoType, groupId, brandId, propertyId, dateValue, custAccount;
@synthesize label;
@synthesize taskId, fromTask, taskResult;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithTitle:@"Камера" style:UIBarButtonItemStylePlain target:self action:@selector(useCamera:)];
    
    if (! fromTask)
        cameraButton.enabled = inVisit;
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStyleDone  target:self action:@selector(cancel_Clicked:)];
    
    barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
    
    NSArray *items = [NSArray arrayWithObjects: barButton, cameraButton, /*cameraRollButton,*/ nil];
    
    [toolbar setItems:items animated:NO];
    
    //[cameraRollButton release];
    
    [super viewDidLoad];
    
    isFirstLoadOfTheView = YES;
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate;
    
    if (dateValue)
        strDate = dateValue;
    else
        strDate = [dateFormatter stringFromDate:date];
    
    UIImage *image;
    if ([photoType isEqualToString:@"group"]) {
        image = [self getGroupImage:strDate];
    }
    
    if ([photoType isEqualToString:@"mark"]) {
        image = [self getBrandImage:strDate group:groupId brandId:brandId property:propertyId];
    }
    
    if ([photoType isEqualToString:@"tt"]) {
        image = [self getTTImage:strDate property:propertyId];
    }

    if (fromTask) {
        NSData *imgData = [FilesStorageWorker getFileWithName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
        if (imgData) {
            image = [UIImage imageWithData:imgData];
        }
    }
    
    imageView.image = image;
    imageView.frame = self.view.bounds;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.userInteractionEnabled = YES;
    imageView.multipleTouchEnabled = YES;
    
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)useCameraOnLaunch {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        imagePicker.delegate = self;
        
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        imagePicker.mediaTypes = @[UTTypeImage.identifier];
        
        imagePicker.allowsEditing = NO;
        
        [self presentViewController:imagePicker animated:YES completion:nil];
        
        newMedia = YES;
    }
    
    isFirstLoadOfTheView = FALSE;
}

-(IBAction)useCamera:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        imagePicker.delegate = self;
        
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        imagePicker.mediaTypes = @[UTTypeImage.identifier];
        
        imagePicker.allowsEditing = NO;
        
        [self presentViewController:imagePicker animated:YES completion:nil];
        
        newMedia = YES;
    }
}

- (IBAction)useCameraRoll:(id)sender {
    if (!self.imagePickerViewController) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
            self.imagePickerViewController = [[UIImagePickerController alloc] init];
            self.imagePickerViewController.delegate = self;
            self.imagePickerViewController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.imagePickerViewController.mediaTypes = @[UTTypeImage.identifier];
            self.imagePickerViewController.allowsEditing = NO;
            
            self.imagePickerViewController.modalPresentationStyle = UIModalPresentationPopover;
            self.imagePickerViewController.popoverPresentationController.barButtonItem = sender;
            self.imagePickerViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
            
            [self presentViewController: self.imagePickerViewController animated:YES completion:nil];
            
            newMedia = NO;
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        self.imagePickerViewController = nil;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerViewController = nil;
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
        if (newMedia)
            [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([mediaType isEqualToString:UTTypeImage.identifier]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        imageView.image = image;
        
        if (! fromTask) {
            if ([photoType isEqualToString:@"group"])
                [self saveGroupImage:image];
            
            if ([photoType isEqualToString:@"mark"]) {
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                NSDate          *date           = NSDate.date;
                
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                NSString *strDate = [dateFormatter stringFromDate:date];
                
                [self saveBrandImage:strDate group:groupId brandId:brandId property:propertyId image:image];
            }
            
            if ([photoType isEqualToString:@"tt"]) {
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                NSDate          *date           = NSDate.date;
                
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                NSString *strDate = [dateFormatter stringFromDate:date];
                
                [self saveTTImage:strDate property:propertyId image:image];
            }
        } else {
            [self saveTaskImage:image];
        }
    }
}

- (void)saveTaskImage:(UIImage *)image {
    CGRect rect = CGRectMake(0.0, 0.0, 960.0, 720.0);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imgData = UIImageJPEGRepresentation(newImage, 0.0);
  
    [FilesStorageWorker saveFile:imgData fileName:[NSString stringWithFormat:@"%@_%@", taskId, custAccount] atPath:[FilesStorageWorker taskImagesPath]];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"refreshAfterPhoto" object:nil];
}

- (void)image:(UIImage *)image imagefinishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        [AlertWorkerObjc alertWithTitle:@"Save failed" message:@"Failed to save image"];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveGroupImage:(UIImage*)image {
    CGRect rect = CGRectMake(0, 0, 960, 720);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imgData = UIImageJPEGRepresentation(newImage, 0.0);
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_2;
        
        sql_2 = "select GroupId from GroupImage where GroupId = ? and CustAccount = ? and Date = ?";
        
        sqlite3_stmt *selstmt_2;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_2, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
                const char *sql_3 = "update GroupImage Set Image = ?, SendStatus = ? where GroupId = ? and CustAccount = ? and Date = ?";
                
                sqlite3_stmt *updateStmt;
                
                if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK)
                {
                    //sqlite3_bind_text(updateStmt, 1, [value UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_blob(updateStmt, 1, [imgData bytes], (int)[imgData length], NULL);
                    sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 3, [groupId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 5, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_step(updateStmt);
                    sqlite3_finalize(updateStmt);
                }
            } else {
                char *sErrMsg;
                sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
                
                static sqlite3_stmt *addStmt;
                
                const char *sql = "insert or ignore into GroupImage (GroupId, Date, Image, CustAccount, SendStatus) Values(?, ?, ?, ?, ?)";
                
                if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                sqlite3_bind_text(addStmt, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_blob(addStmt, 3, [imgData bytes], (int)[imgData length], NULL);
                sqlite3_bind_text(addStmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(addStmt) != SQLITE_DONE)
                {
                    NSLog(@"Commit Failed!");
                }
                
                sqlite3_finalize(addStmt);
                sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
                sqlite3_close(database);
            }
        }
        sqlite3_finalize(selstmt_2);
    } else
        sqlite3_close(database);
}


-(UIImage *)getGroupImage:(NSString *)strDate {
    UIImage *image = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Image from GroupImage where GroupId = ? and Date = ? and CustAccount = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSData *imgData = nil;
                
                if (sqlite3_column_blob(selectstmt, 0))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 0) length:sqlite3_column_bytes(selectstmt, 0)];
                    
                    image = [UIImage imageWithData:imgData];
                }
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    return image;
}

- (void)saveBrandImage:(NSString*)valueDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property image:(UIImage*)image {
    CGRect rect = CGRectMake(0, 0, 960, 720);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imgData = UIImageJPEGRepresentation(newImage, 0.0);
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_2;
        
        sql_2 = "select Value from PropertiesValue where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date = ?";
        
        sqlite3_stmt *selstmt_2;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_2, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 2, [brand UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 5, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
                const char *sql_3 = "update PropertiesValue Set Image = ?, SendStatus = ? where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date = ?";
                
                sqlite3_stmt *updateStmt;
                
                if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK)
                {
                    //sqlite3_bind_text(updateStmt, 1, [value UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_blob(updateStmt, 1, [imgData bytes], (int)[imgData length], NULL);
                    sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 3, [group UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 4, [brand UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 5, [property UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 6, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 7, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_step(updateStmt);
                    sqlite3_finalize(updateStmt);
                }
            } else {
                char *sErrMsg;
                sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
                
                static sqlite3_stmt *addStmt;
                
                const char *sql = "insert or ignore into PropertiesValue (GroupId, BrandId, PropertyId, Value, Date, CustAccount, Image, SendStatus, ElementListId) Values(?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                sqlite3_bind_text(addStmt, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [brand UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [@"image" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 6, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_blob(addStmt, 7, [imgData bytes], (int)[imgData length], NULL);
                sqlite3_bind_text(addStmt, 8, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 9, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(addStmt) != SQLITE_DONE)
                {
                    NSLog(@"Commit Failed!");
                }
                
                sqlite3_finalize(addStmt);
                sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
                sqlite3_close(database);
            }
        }
        sqlite3_finalize(selstmt_2);
    } else
        sqlite3_close(database);
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"BrandImageSaved" object:nil];
}

-(UIImage *)getBrandImage:(NSString *)strDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property{
    UIImage *image = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Image from PropertiesValue where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [brand UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 5, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSData *imgData = nil;
                
                if (sqlite3_column_blob(selectstmt, 0))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 0) length:sqlite3_column_bytes(selectstmt, 0)];
                    
                    image = [UIImage imageWithData:imgData];
                }
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    return image;
}

- (void)saveTTImage:(NSString*)valueDate property:(NSString*)property image:(UIImage*)image {
    NSDate          *date       = NSDate.date;
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString     = [timeFormat stringFromDate:date];
    NSString *dateTimeString = [NSString stringWithFormat:@"%@ %@", valueDate, timeString];
    
    CGRect rect = CGRectMake(0, 0, 960, 720);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imgData = UIImageJPEGRepresentation(newImage, 0.0);
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_2;
        
        sql_2 = "select Value from TTPropertiesValue where PropertyId = ? and CustAccount = ? and Date = ?";
        
        sqlite3_stmt *selstmt_2;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_2, 1, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 3, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
                const char *sql_3 = "update TTPropertiesValue Set Image = ?, SendStatus = ?, CreatedDateTime = ? where PropertyId = ? and CustAccount = ? and Date = ?";
                
                sqlite3_stmt *updateStmt;
                
                if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK)
                {
                    //sqlite3_bind_text(updateStmt, 1, [value UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_blob(updateStmt, 1, [imgData bytes], (int)[imgData length], NULL);
                    sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 3, [dateTimeString UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 4, [property UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 5, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 6, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_step(updateStmt);
                    sqlite3_finalize(updateStmt);
                }
            } else {
                const char *sql_2;
                NSString   *ttid;
                
                sql_2 = "select TTId from CustTable where CustAccount = ?";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt_2, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW)
                    {
                        if (sqlite3_column_text(selstmt_2, 0))
                            ttid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                char *sErrMsg;
                sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
                
                static sqlite3_stmt *addStmt;
                
                const char *sql = "insert or ignore into TTPropertiesValue (PropertyId, Value, Date, CustAccount, Image, SendStatus, ttId, ElementListId, CreatedDateTime) Values(?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                sqlite3_bind_text(addStmt, 1, [property UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [@"image" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_blob(addStmt, 5, [imgData bytes], (int)[imgData length], NULL);
                sqlite3_bind_text(addStmt, 6, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 7, [ttid UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 8, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 9, [dateTimeString UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(addStmt) != SQLITE_DONE)
                {
                    NSLog(@"Commit Failed!");
                }
                
                sqlite3_finalize(addStmt);
                sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
                sqlite3_close(database);
            }
        }
        sqlite3_finalize(selstmt_2);
    } else
        sqlite3_close(database);
    [NSNotificationCenter.defaultCenter postNotificationName:kTTPhotoSaved object:nil];
}

-(UIImage *)getTTImage:(NSString *)strDate property:(NSString*)property{
    UIImage *image = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Image from TTPropertiesValue where PropertyId = ? and CustAccount = ? and Date = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSData *imgData = nil;
                
                if (sqlite3_column_blob(selectstmt, 0))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 0) length:sqlite3_column_bytes(selectstmt, 0)];
                    
                    image = [UIImage imageWithData:imgData];
                }
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    return image;
    
}

@end
