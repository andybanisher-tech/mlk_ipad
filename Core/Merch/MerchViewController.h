//
//  MerchViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 13.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "AGOrientedTableView.h"
#import "MerchCommentViewController.h"
#import "MerchActionViewController.h"
#import "CameraViewController.h"
#import "sqlite3.h"
#import "MerchBrandViewController.h"
#import "MerchGroupPropViewController.h"
#import "PropertyListViewController.h"
#import "MerchTTViewController.h"
#import "SendMerchData.h"
#import "PutTTPropertiesValueRequest.h"
#import "RWBorderedButton.h"

#import "ASPDatePickerViewController.h"

@class MerchCommentViewController;
@class MerchActionViewController;
@class CameraViewController;
@class MerchBrandViewController;
@class MerchGroupPropViewController;
@class MerchTTViewController;

@interface MerchViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, BrandForGroupControllerDelegate, GroupPropControllerDelegate,PropertyListDelegate, ASPDatePickerViewControllerDelegate> {
    AGOrientedTableView *_tableView;
    
    BOOL isViewPushed;
    
    UIButton    *merchBtn;
    UIButton    *commentBtn;
    UIButton    *actionBtn;
    UIButton    *ttBtn;
    
    UINavigationController *infoNavController;
    
    IBOutlet UITableView *tblView;
    IBOutlet UITableView *tblView_2;
    
    NSMutableArray		 *merchGroupList;
    NSMutableArray		 *merchGroupToLiveInArray;
    
    NSMutableArray		 *merchBrandList;
    NSMutableArray		 *merchBrandToLiveInArray;
    
    NSMutableArray		 *merchGroupNameList;
    NSMutableArray		 *merchGroupNameToLiveInArray;
    
    NSMutableArray		 *groupStatusList;
    NSMutableArray		 *groupStatusToLiveInArray;
    
    NSString             *groupIdSelected;
    NSString             *brandIdIsSelected;
    
    PropertyListViewController  *propertyListViewController;
    
    IBOutlet UILabel *groupLabel;
    IBOutlet UILabel *brandLabel;
    IBOutlet UILabel *selectedDateLabel;
    IBOutlet UILabel *selectedAccLabel;
    
    NSString *custAccount;
    NSString *custName;
    NSString *selectedDate;

    SendMerchData           *sendMerchData;
    NSIndexPath *selectedIndex;
}

@property(retain)IBOutlet AGOrientedTableView *tableView;
@property(nonatomic,readwrite) BOOL isViewPushed;
@property(nonatomic,retain)IBOutlet UIButton *merchBtn;
@property(nonatomic,retain)IBOutlet UIButton *commentBtn;
@property(nonatomic,retain)IBOutlet UIButton *actionBtn;
@property(nonatomic,retain)IBOutlet UIButton *ttBtn;
@property(nonatomic,retain)NSMutableArray *merchGroupList;
@property(nonatomic,retain)NSMutableArray *merchBrandList;
@property(nonatomic,retain)NSMutableArray *merchGroupNameList;
@property(nonatomic,retain)NSMutableArray *groupStatusList;
@property(nonatomic,retain)IBOutlet MerchBrandViewController *merchBrandViewController;
@property(nonatomic,retain)IBOutlet MerchGroupPropViewController *merchGroupPropViewController;
@property(nonatomic,retain)NSString *groupIdSelected;
@property(nonatomic,retain)NSString *brandIdIsSelected;
@property(nonatomic,retain)PropertyListViewController *propertyListViewController;
@property(nonatomic,retain)UILabel *groupLabel;
@property(nonatomic,retain)UILabel *brandLabel;
@property(nonatomic,retain)UILabel *selectedDateLabel;
@property(nonatomic,retain)UILabel *selectedAccLabel;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSString *custName;
@property(nonatomic,retain)NSString *selectedDate;

@property (nonatomic, strong) PutTTPropertiesValueRequest *putTTPropertiesValue;

@property (nonatomic, strong) ASPDatePickerViewController *datePickerVC;

-(IBAction)openComment;
-(IBAction)openTT;
- (void)createMerchList;
- (void)brandSelected:(NSString*)brandId;
- (void)showList:(UITableViewCell*)cell rowNum:(NSInteger)rowNum propId:(NSString *)propId;
- (void)elementIsSelected:(NSString *)listElement propId:(NSString *)propId propElementId:(NSString *)propElementId;
- (void)makePhoto:(NSString *)property;
- (void)takePhoto:(id)sender;
-(BOOL)groupHaveImage:(NSString*)group;
-(BOOL)custInVisit:(NSString *)custAcc;
-(IBAction)sendData;
-(BOOL)groupHaveBrand:(NSString*)group;
-(BOOL)groupHaveTP:(NSString*)group;
-(BOOL)custInVisitPhoto:(NSString *)custAcc;
@end
