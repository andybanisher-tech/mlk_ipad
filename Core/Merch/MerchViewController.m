//
//  MerchViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 13.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MerchViewController.h"
#import "MerchCommentViewController.h"
#import "MerchActionViewController.h"
#import "CameraViewController.h"
#import "MerchTTViewController.h"
#import "PutTTPropertiesValueRequest.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@implementation MerchViewController

@synthesize tableView = _tableView;
@synthesize isViewPushed;
@synthesize merchBtn, commentBtn, actionBtn, ttBtn, title;
@synthesize merchGroupList, merchBrandList, merchGroupNameList, groupStatusList;
@synthesize merchBrandViewController, merchGroupPropViewController;
@synthesize groupIdSelected, brandIdIsSelected;
@synthesize propertyListViewController;
@synthesize groupLabel, brandLabel, selectedDateLabel, selectedAccLabel;
@synthesize custAccount, selectedDate, custName;

/*
 // The designated initializer. Override to perform setup that is required before the view is loaded.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization
 }
 return self;
 }
 */

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    [dateFormatter setDateFormat:dateFormat_dd_MMM_YYYY];
    
    selectedDate = [dateFormatter stringFromDate:date];
    
    selectedDateLabel.text = selectedDate;
    selectedAccLabel.text  = custName;
    
    [self createMerchList];
    
    //NavBar Setup
    self.navigationItem.title = @"Мерчендайзинг - паспорт марки";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];
    
    [self.navigationController.navigationBar addSubview:titleView];
    self.navigationController.navigationBar.barStyle = 1;
    _tableView.orientedTableViewDataSource = self;
    _tableView.delegate = self;
    _tableView.tableViewOrientation = kAGTableViewOrientationVertical;
    
    if (isViewPushed == NO) {
        
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30)
                                                                    title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        self.navigationItem.rightBarButtonItem = barButton;
    }
    
    CALayer *tblLayer = tblView.layer;
    tblLayer.borderColor = [[UIColor blackColor] CGColor];
    tblLayer.borderWidth = 1.0f;
    
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //UIColor *routeTablecolor= [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:128.0/255.0 alpha:1.0];
    
    tblView_2.separatorStyle = UITableViewCellSeparatorStyleNone;
    //UIColor *custTablecolor= [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:128.0/255.0 alpha:1.0];
    
    /*if ([self custInVisit:custAccount] == YES)
     {
     //tblView.userInteractionEnabled   = YES;
     tblView_2.userInteractionEnabled = YES;
     }
     else
     {
     //tblView.userInteractionEnabled   = NO;
     tblView_2.userInteractionEnabled = NO;
     }*/
}

- (void)createMerchList {
    merchGroupList                  = [NSMutableArray new];
    merchGroupToLiveInArray         = [NSMutableArray array];
    
    merchBrandList                  = [NSMutableArray new];
    merchBrandToLiveInArray         = [NSMutableArray array];
    
    merchGroupNameList              = [NSMutableArray new];
    merchGroupNameToLiveInArray     = [NSMutableArray array];
    
    groupStatusList                 = [NSMutableArray new];
    groupStatusToLiveInArray        = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
        NSString *squl = @"select GroupId, BrandId, GroupName from MerchGroupBrands where 1=1 and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == MerchGroupBrands.BrandId) group by GroupId";
        
        sql = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *groupId    = @"null";
                NSString *brandId    = @"null";
                NSString *groupName  = @"null";
                NSString *sendStatus = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    groupId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    brandId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    groupName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                const char *sql_2;
                
                sql_2 = "select SendStatus from GroupImage where GroupId = ? and Date = ? and CustAccount = ?";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt_2, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 2, [selectedDate UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW)
                    {
                        if (sqlite3_column_text(selstmt_2, 0))
                            sendStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                [merchGroupToLiveInArray     addObject:groupId];
                [merchBrandToLiveInArray     addObject:brandId];
                [merchGroupNameToLiveInArray addObject:groupName];
                [groupStatusToLiveInArray    addObject:sendStatus];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    NSDictionary *groupToLiveInDict       = [NSDictionary dictionaryWithObject:merchGroupToLiveInArray forKey:@"groupId"];
    NSDictionary *brandToLiveInDict       = [NSDictionary dictionaryWithObject:merchBrandToLiveInArray forKey:@"brandId"];
    NSDictionary *groupNameToLiveInDict   = [NSDictionary dictionaryWithObject:merchGroupNameToLiveInArray forKey:@"groupName"];
    NSDictionary *groupStatusToLiveInDict = [NSDictionary dictionaryWithObject:groupStatusToLiveInArray forKey:@"sendStatus"];
    
    [merchGroupList     addObject:groupToLiveInDict];
    [merchBrandList     addObject:brandToLiveInDict];
    [merchGroupNameList addObject:groupNameToLiveInDict];
    [groupStatusList    addObject:groupStatusToLiveInDict];
}

- (IBAction)showCalendar:(id)sender {
    if (!self.datePickerVC) {
        self.datePickerVC = [ASPDatePickerViewController new];
        self.datePickerVC.delegate = self;
        self.datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
    }

    if (!self.datePickerVC.presentingViewController) {
        self.datePickerVC.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:self.datePickerVC animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    if (self.datePickerVC.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self datePickerDidCancel];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:dateFormat_dd_MMM_YYYY];
    
    selectedDate = [dateFormatter stringFromDate:date];
    selectedDateLabel.text = selectedDate;
    
    merchGroupPropViewController = nil;
    merchGroupPropViewController = [[MerchGroupPropViewController alloc] init];
    
    merchGroupPropViewController.groupId      = groupIdSelected;
    merchGroupPropViewController.brandId      = brandIdIsSelected;
    merchGroupPropViewController.custAccount  = custAccount;
    merchGroupPropViewController.selectedDate = selectedDate;
    merchGroupPropViewController.custInVisit  = [self custInVisit:custAccount];
    
    [tblView_2 setDataSource:merchGroupPropViewController];
    [tblView_2 setDelegate:merchGroupPropViewController];
    
    merchGroupPropViewController.view = merchGroupPropViewController.tableView;
    
    self.merchGroupPropViewController.delegate = self;
    
    [merchGroupPropViewController refreshData];
    [tblView_2 reloadData];
    
    groupLabel.text = groupIdSelected;
    brandLabel.text = brandIdIsSelected;

    [self.tableView reloadData];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self brandSelected:brandIdIsSelected];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self createMerchList];
    [self.tableView reloadData];
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dictionary = [merchGroupList objectAtIndex:section];
    NSArray		 *array      = [dictionary objectForKey:@"groupId"];
    NSLog(@"%lu", (unsigned long)[array count]);
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)anIndexPath {
    UITableViewCell *result = [aTableView dequeueReusableCellWithIdentifier:@"Reuse"];
    
    NSDictionary	*dictGroup   = [merchGroupNameList objectAtIndex:anIndexPath.section];
    NSArray			*arrayGroup  = [dictGroup objectForKey:@"groupName"];
    NSString        *groupValue  = [arrayGroup objectAtIndex:anIndexPath.row];
    
    NSDictionary	*dictGroupId   = [merchGroupList objectAtIndex:anIndexPath.section];
    NSArray			*arrayGroupId  = [dictGroupId objectForKey:@"groupId"];
    NSString        *groupIdValue  = [arrayGroupId objectAtIndex:anIndexPath.row];
    
    NSDictionary	*dictStatus    = [groupStatusList objectAtIndex:anIndexPath.section];
    NSArray			*arrayStatus   = [dictStatus objectForKey:@"sendStatus"];
    NSString        *statusValue   = [arrayStatus objectAtIndex:anIndexPath.row];
    
    UILabel *label = nil;
    
    if (result == nil) {
        result = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Reuse"];
        
        UIView *selView = [[UIView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(aTableView.frame),85.f)];
        selView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        selView.tag = 13;
        [selView setHidden:YES];
        [result addSubview:selView];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 85)];
        
        label.tag               = 1;
        label.textAlignment		= NSTextAlignmentLeft;
        label.textColor			= [UIColor blackColor];
        label.font				= [UIFont boldSystemFontOfSize:20];
        label.text = groupValue;//[NSString stringWithFormat:@"%d", [indexPath row]];
        
        [result setBackgroundColor:UIColor.clearColor];
        
        
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(
                                                                      0,
                                                                      85.f - 1.f/UIScreen.mainScreen.scale,
                                                                      CGRectGetWidth(aTableView.frame),
                                                                      1.f/UIScreen.mainScreen.scale)
                              ];
        [bottomLine setBackgroundColor:[UIColor blackColor]];
        [result addSubview:bottomLine];
        result.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (! label) {
        label = (UILabel*)[result viewWithTag:1];
        label.text = groupValue;
    }
    
    [result.contentView addSubview:label];
    
    //result.textLabel.text = [NSString stringWithFormat:@"%d", [anIndexPath row]];
    UIButton *addFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    addFriendButton.frame = CGRectMake(17, 12, 36, 36);
    
    if ([self groupHaveTP:groupIdValue] == NO)
        [addFriendButton setImage:[UIImage imageNamed:ACImageNameGrayStar] forState:UIControlStateNormal];
    else
        [addFriendButton setImage:[UIImage imageNamed:ACImageNameYellowStar] forState:UIControlStateNormal];
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    addButton.frame = CGRectMake(17, 77, 36, 36);

    if ([self groupHaveBrand:groupIdValue] == NO)
        [addButton setImage:[UIImage imageNamed:ACImageNameGrayCart] forState:UIControlStateNormal];
    else
        [addButton setImage:[UIImage imageNamed:ACImageNameOrangeCart] forState:UIControlStateNormal];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(17, 24.5f, 36, 36);
    
    UIImage *img;
    
    if ([self groupHaveImage:groupIdValue] == YES) {
        if ([statusValue isEqualToString:@"Sended"]) {
            img = [UIImage imageNamed:ACImageNameWhiteCameraSelected];
        } else {
            img = [UIImage imageNamed:ACImageNameWhiteCamera];
        }
    } else {
        img = [UIImage imageNamed:ACImageNameBlackCamera];
    }
    
    [button setImage:img forState:UIControlStateNormal];
    
    button.tag = anIndexPath.row;
    
    //[result addSubview:button];
    
    [button addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (selectedIndex) {
        UITableViewCell *previousSelected = [tableView cellForRowAtIndexPath:selectedIndex];
        UIView *bg = [previousSelected viewWithTag:13];
        if (bg)
            [bg setHidden:YES];
        UILabel *titleLabel = [previousSelected viewWithTag:1];
        if (titleLabel)
            titleLabel.textColor = [UIColor blackColor];
    }
    
    selectedIndex = indexPath;
    
    UITableViewCell *selected = [tableView cellForRowAtIndexPath:selectedIndex];
    UIView *bg = [selected viewWithTag:13];
    if (bg)
        [bg setHidden:NO];
    UILabel *titleLabel = [selected viewWithTag:1];
    if (titleLabel)
        titleLabel.textColor = UIColor.whiteColor;
    
    NSDictionary	*dictGroup   = [merchGroupList objectAtIndex:indexPath.section];
    NSArray			*arrayGroup  = [dictGroup objectForKey:@"groupId"];
    
    groupIdSelected  = [arrayGroup objectAtIndex:indexPath.row];
    
    merchBrandViewController = nil;
    merchBrandViewController = [[MerchBrandViewController alloc] init];
    
    merchBrandViewController.groupId     = groupIdSelected;
    merchBrandViewController.custAccount = custAccount;
    
    [tblView setDataSource:merchBrandViewController];
    [tblView setDelegate:merchBrandViewController];
    
    merchBrandViewController.view = merchBrandViewController.tableView;
    
    self.merchBrandViewController.delegate = self;
    
    [merchBrandViewController refreshData];
    [tblView reloadData];
    
    merchGroupPropViewController = nil;
    merchGroupPropViewController = [[MerchGroupPropViewController alloc] init];
    
    merchGroupPropViewController.groupId       = groupIdSelected;
    merchGroupPropViewController.brandId       = nil;
    merchGroupPropViewController.custAccount   = custAccount;
    merchGroupPropViewController.selectedDate  = selectedDate;
    merchGroupPropViewController.custInVisit   = [self custInVisit:custAccount];
    
    [tblView_2 setDataSource:merchGroupPropViewController];
    [tblView_2 setDelegate:merchGroupPropViewController];
    
    merchGroupPropViewController.view = merchGroupPropViewController.tableView;
    
    self.merchGroupPropViewController.delegate = self;
    
    [merchGroupPropViewController refreshData];
    [tblView_2 reloadData];
    
    //NSDictionary	*dictGroupName   = [merchGroupNameList objectAtIndex:indexPath.section];
    //NSArray			*arrayGroupName  = [dictGroupName objectForKey:@"groupName"];
    //NSString        *groupNameValue  = [arrayGroupName objectAtIndex:indexPath.row];
    
    groupLabel.text = groupIdSelected;
    brandLabel.text = @"";
}

- (void)elementIsSelected:(NSString *)listElement propId:(NSString *)propId propElementId:(NSString *)propElementId {
    if (merchGroupPropViewController) {
        merchGroupPropViewController.valueForProperty  = listElement;
        merchGroupPropViewController.propElementListId = propElementId;
        [merchGroupPropViewController readValue];
        
        if (propertyListViewController.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
            propertyListViewController = nil;
        }
    }
}

-(IBAction)openComment {
    MerchCommentViewController *fvController = [[MerchCommentViewController alloc] initWithNibName: @"MerchCommentViewController" bundle: nil];
    
    fvController.custAccount = custAccount;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
    
    fvController = nil;
    infoNavController = nil;
}

-(IBAction)openAction {
    MerchActionViewController *fvController = [[MerchActionViewController alloc] init];
    
    fvController.fromMerch = YES;
    fvController.custAccount = custAccount;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
    
    fvController = nil;
    infoNavController = nil;
}

- (IBAction)openTT {
    MerchTTViewController *fvController = [[MerchTTViewController alloc] initWithNibName: @"MerchTTViewController" bundle: nil];
    
    fvController.selectedDate = selectedDate;
    fvController.custAccount  = custAccount;
    fvController.inVisit      = [self custInVisit:custAccount];
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNavController.preferredContentSize = CGSizeMake(540,400);
    [self presentViewController:infoNavController animated:YES completion:nil];
    
    fvController = nil;
    infoNavController = nil;
}

- (void)makePhoto:(NSString *)property{
    if ([self custInVisitPhoto:custAccount]) {
        CameraViewController *fvController = [[CameraViewController alloc] init];
        
        fvController.groupId     = groupIdSelected;
        fvController.brandId     = brandIdIsSelected;
        fvController.propertyId  = property;
        fvController.photoType   = @"mark";
        fvController.custAccount = custAccount;
        fvController.inVisit     = [self custInVisitPhoto:custAccount];
        
        [self presentViewController:fvController animated:YES completion:nil];
        
        fvController = nil;
    } else {
        [AlertWorkerObjc alertWithTitle:@"Для создания фотографии клиент должен быть в режиме посещения"];
    }
}

- (void)takePhoto:(id)sender {
    if ([self custInVisitPhoto:custAccount]) {
        UIButton *btn = sender;
        
        NSDictionary	*dictGroupId   = [merchGroupList objectAtIndex:0];
        NSArray			*arrayGroupId  = [dictGroupId objectForKey:@"groupId"];
        NSString        *groupIdValue  = [arrayGroupId objectAtIndex:btn.tag];
        
        CameraViewController *fvController = [[CameraViewController alloc] init];
        
        fvController.groupId     = groupIdValue;
        fvController.photoType   = @"group";
        fvController.custAccount = custAccount;
        fvController.dateValue   = selectedDate;
        fvController.inVisit     = [self custInVisitPhoto:custAccount];
        
        [self presentViewController:fvController animated:YES completion:nil];
        fvController = nil;
    }
}

- (void)brandSelected:(NSString *)brandId {
    brandIdIsSelected = brandId;
    
    merchGroupPropViewController = nil;
    merchGroupPropViewController = [[MerchGroupPropViewController alloc] init];
    
    merchGroupPropViewController.groupId      = groupIdSelected;
    merchGroupPropViewController.brandId      = brandIdIsSelected;
    merchGroupPropViewController.custAccount  = custAccount;
    merchGroupPropViewController.selectedDate = selectedDate;
    merchGroupPropViewController.custInVisit  = [self custInVisit:custAccount];
    
    [tblView_2 setDataSource:merchGroupPropViewController];
    [tblView_2 setDelegate:merchGroupPropViewController];
    
    merchGroupPropViewController.view = merchGroupPropViewController.tableView;
    
    self.merchGroupPropViewController.delegate = self;
    
    if ([self custInVisit:custAccount])
        [merchGroupPropViewController createTodayPropValue];
    else
        [merchGroupPropViewController refreshData];
    
    [tblView_2 reloadData];
    
    groupLabel.text = groupIdSelected;
    brandLabel.text = brandIdIsSelected;
}

- (void)showList:(UITableViewCell*)cell rowNum:(NSInteger)rowNum propId:(NSString *)propId {
    if (!propertyListViewController) {
        propertyListViewController = [[PropertyListViewController alloc] init];
        propertyListViewController.delegate   = self;
        propertyListViewController.propertyId = propId;
        
        propertyListViewController.modalPresentationStyle = UIModalPresentationPopover;
        propertyListViewController.popoverPresentationController.sourceView = cell;
        propertyListViewController.popoverPresentationController.sourceRect = CGRectMake(cell.bounds.origin.x+422, cell.bounds.origin.y+277+(44*rowNum), cell.bounds.size.width, cell.bounds.size.height);
        
        [self presentViewController:propertyListViewController animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        propertyListViewController = nil;
    }
}

-(BOOL)groupHaveImage:(NSString*)group{
    BOOL have = NO;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Image from GroupImage where GroupId = ? and Date = ? and CustAccount = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [selectedDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_blob(selectstmt, 0))
                {
                    have = YES;
                }
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    return have;
}

-(BOOL)groupHaveBrand:(NSString*)group{
    BOOL have = NO;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select BrandId from MerchGroupBrands where GroupId = ? and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == MerchGroupBrands.BrandId)";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW)
                have = YES;
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    return have;
}

-(BOOL)groupHaveTP:(NSString*)group{
    BOOL have = NO;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sqlIn = "select BrandId, BrandName from BrandMerch where 1 = 1 and exists(select * from MerchGroupBrands where MerchGroupBrands.BrandId == BrandMerch.BrandId and MerchGroupBrands.GroupId == ?) and not exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == BrandMerch.BrandId)";
        
        sqlite3_stmt *selectstmtIn;
        
        if (sqlite3_prepare_v2(database, sqlIn, -1, &selectstmtIn, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmtIn, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmtIn, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmtIn) == SQLITE_ROW)
                have = YES;
        }
        sqlite3_finalize(selectstmtIn);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    return have;
}

-(BOOL)custInVisit:(NSString *)custAcc {
    BOOL visit = YES;//FALSE;
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                visit = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return visit;
}

-(BOOL)custInVisitPhoto:(NSString *)custAcc {
    BOOL visit = FALSE;
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                visit = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return visit;
}


-(IBAction)sendData{
    [AlertWorkerObjc actionSheetWithTitle:nil message:nil sourceView:self.view buttons:@[@"Отправить данные", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            self.putTTPropertiesValue = [PutTTPropertiesValueRequest new];
            self.putTTPropertiesValue.custAccount = self->custAccount;
            [self.putTTPropertiesValue sendTTPropertiesValue];
        }
    }];
}

@end
