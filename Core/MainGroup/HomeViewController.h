//
//  HomeViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//
#import "UIKit/UIKit.h"
#import "GlobalSettingsView.h"
#import "GetCustTableRequest.h"
#import "NoticeViewController.h"
#import "sqlite3.h"

@class M13BadgeView;
@class SyncError;

@interface HomeViewController : UIViewController <UITextFieldDelegate> {
    UINavigationController *infoNavController;
    
    UITextField *alertTextField;
    
    BOOL showSyncProgress;
}

@property(nonatomic, retain) NSString *globalCustAccount;

@property(nonatomic,readwrite) BOOL showSyncProgress;

- (void)checkAuth;

- (void)syncAllData;
- (void)syncRemains;
- (void)sendRoute;
- (void)sendCustForRoute;
- (void)sendSalesToServer;
- (void)updateSalesTable:(NSString *)salesNum sendTime:(NSString*)sendTime;
- (void)sendTTPropertiesValue;
- (void)sendDN:(BOOL)sendGP;
- (void)sendGroupPropertiesValue;
- (void)sendNewCustomer;
- (void)setNoticeCount:(NSInteger)noticeCount;
- (void)runSyncFromOtherView:(NSString *)custAccount;

@end
