//
//  GroupView.h
//  MLK
//
//  Created by Rustem Galyamov on 28.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol GroupDelegate
- (void)markIsSelected:(NSString *)brand;
- (void)groupIsSelected:(NSString *)groupId;
@end

@interface GroupView : UITableViewController <UITableViewDelegate,UITableViewDataSource>
@property(nonatomic, weak) id<GroupDelegate> delegate;

@property (nonatomic, strong) NSArray *requiredGroupIDsArray;
@property (nonatomic, strong) NSMutableArray *groupsArray;

@property(copy, nonatomic) NSString *selectedBrandID;
@property(copy, nonatomic) NSString *selectedGroupID;

@property(nonatomic, readwrite) BOOL isViewPushed;

- (void)cancel_Clicked:(id)sender;
@end

