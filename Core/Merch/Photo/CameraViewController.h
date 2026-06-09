//
//  CameraViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 22.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "sqlite3.h"

#define kTTPhotoSaved @"TTPhotoSaved"

@interface CameraViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    UIToolbar *toolbar;
    UIImageView *imageView;
    IBOutlet UILabel *label;
    BOOL newMedia;
    
    BOOL isViewPushed;
    BOOL isFirstLoadOfTheView;
    
    NSString *photoType;
    NSString *groupId;
    NSString *brandId;
    NSString *propertyId;
    NSString *dateValue;
    NSString *custAccount;
    
    NSString *taskId;
    NSString *taskResult;
    
    BOOL inVisit;
    
    BOOL fromTask;
}

@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,readwrite)BOOL isFirstLoadOfTheView;
@property(nonatomic,readwrite)BOOL inVisit;
@property(nonatomic,retain)IBOutlet UIImageView *imageView;
@property(nonatomic,retain)IBOutlet UIToolbar *toolbar;
@property(nonatomic,retain)NSString *photoType;
@property(nonatomic,retain)NSString *groupId;
@property(nonatomic,retain)NSString *brandId;
@property(nonatomic,retain)NSString *propertyId;
@property(nonatomic,retain)NSString *dateValue;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)IBOutlet UILabel *label;
@property(nonatomic,retain)NSString *taskId;
@property(nonatomic,retain)NSString *taskResult;
@property(nonatomic,readwrite)BOOL fromTask;

@property(nonatomic,retain)UIImagePickerController *imagePickerViewController;

-(IBAction)useCamera:(id)sender;
-(IBAction)useCameraRoll:(id)sender;
- (void)cancel_Clicked:(id)sender;
- (void)useCameraOnLaunch;
- (void)saveGroupImage:(UIImage*)image;
-(UIImage *)getGroupImage:(NSString *)strDate;
- (void)saveBrandImage:(NSString*)valueDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property image:(UIImage*)image;
-(UIImage *)getBrandImage:(NSString *)strDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property;
- (void)saveTTImage:(NSString*)valueDate property:(NSString*)property image:(UIImage*)image;
-(UIImage *)getTTImage:(NSString *)strDate property:(NSString*)property;

@end
