//
//  ChannelFilter.h
//  MLK
//
//  Created by Rustem Galyamov on 14.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol ChannelFilterDelegate
- (void)selectChannel:(NSString *)channel;
@end

@interface ChannelFilter : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray       *channelList;
	NSMutableArray       *channelToLiveInArray;
    
    BOOL                 isToday;
    BOOL                 isPending;
}

@property(nonatomic,retain)NSMutableArray  *channelList;

@property(nonatomic,assign) id<ChannelFilterDelegate> delegate;

@property(nonatomic,readwrite)BOOL isToday;
@property(nonatomic,readwrite)BOOL isPending;
+ (void)finalizeStatements;

@end
