//
//  DateFilter.h
//  MLK
//
//  Created by Rustem Galyamov on 14.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol DateFilterDelegate
- (void)selectDate:(NSString *)dateStr;
@end

@interface DateFilter : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray       *dateList;
	NSMutableArray       *dateToLiveInArray;
}

@property(nonatomic,retain)NSMutableArray  *dateList;

@property(nonatomic,assign) id<DateFilterDelegate> delegate;

@property (nonatomic, assign) BOOL isToday;
@property (nonatomic, assign) BOOL isPending;
@property (nonatomic, assign) BOOL isConsult;

+ (void)finalizeStatements;

@end
