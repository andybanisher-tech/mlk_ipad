//
//  CustItemMarkView.h
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "GroupView.h"

@protocol CustItemMarkDelegate
- (void)markIsSelected:(NSString *)brand;
- (void)groupIsSelected:(NSString *)groupId;
@end

@interface CustItemMarkView : UITableViewController <UITableViewDelegate,UITableViewDataSource, GroupDelegate> {
    
    UINavigationController *infoNavController;

    NSInteger selectedIndex;
}

@property(nonatomic, weak) id<CustItemMarkDelegate> delegate;

@property (nonatomic, strong) NSArray *requiredBrandIDsArray;
@property (nonatomic, strong) NSArray *requiredGroupIDsArray;

@property (nonatomic, strong) NSMutableArray *brandsArray;

@property(copy, nonatomic) NSString *custAccount;
@property(copy, nonatomic) NSString *selectedBrandID;
@property(copy, nonatomic) NSString *selectedGroupID;
@property(copy, nonatomic) NSString *filterByStatusDN;

- (void)groupIsSelected:(NSString *)groupId;
- (void)markIsSelected:(NSString *)brand;

@end
