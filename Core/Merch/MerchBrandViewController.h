//
//  MerchBrandViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 24.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol BrandForGroupControllerDelegate
- (void)brandSelected:(NSString*)brandId;
@end

@interface MerchBrandViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray  *brandList;
    NSMutableArray  *brandIdList;
    NSMutableArray	*brandInList;
	
    NSString *groupId;
    NSString *custAccount;
    NSIndexPath * selectedIndex;
}

@property(nonatomic,retain)NSMutableArray  *brandList;
@property(nonatomic,retain)NSMutableArray  *brandIdList;
@property(nonatomic,assign) id<BrandForGroupControllerDelegate> delegate;
@property(nonatomic,retain)NSString *groupId;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSMutableArray *brandInList;


- (void)finalizeStatements;
- (void)refreshData;
- (void)brandListCreate;

@end
