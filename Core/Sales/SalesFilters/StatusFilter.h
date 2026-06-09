//
//  StatusFilter.h
//  MLK
//
//  Created by Rustem Galyamov on 15.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol StatusFilterDelegate
- (void)selectStatus:(NSString *)status;
@end

@interface StatusFilter : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray       *statusList;
	NSMutableArray       *statusToLiveInArray;
    
    BOOL                 isToday;
    BOOL                 isPending;
}

@property(nonatomic,retain)NSMutableArray  *statusList;

@property(nonatomic,assign) id<StatusFilterDelegate> delegate;

@property(nonatomic,readwrite)BOOL isToday;
@property(nonatomic,readwrite)BOOL isPending;
+ (void)finalizeStatements;

@end
