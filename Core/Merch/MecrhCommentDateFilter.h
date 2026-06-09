//
//  MecrhCommentDateFilter.h
//  MLK
//
//  Created by Rustem Galyamov on 25.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol MecrhCommentDateFilterDelegate
- (void)selectDate:(NSString *)dateStr;
@end

@interface MecrhCommentDateFilter : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray       *dateList;
	NSMutableArray       *dateToLiveInArray;
    
    BOOL                 isToday;
    
    NSString *custAccount;
}

@property(nonatomic,retain)NSMutableArray  *dateList;
@property(nonatomic,assign)id<MecrhCommentDateFilterDelegate> delegate;
@property(nonatomic,readwrite)BOOL isToday;
@property(nonatomic,retain)NSString *custAccount;

+ (void)finalizeStatements;

@end
