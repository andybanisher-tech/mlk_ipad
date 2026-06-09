//
//  CustFilter.h
//  MLK
//
//  Created by Rustem Galyamov on 12.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol CustFilterDelegate
- (void)selectCust:(NSString *)cust;
@end

@interface CustFilter : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray       *custList;
	NSMutableArray       *custToLiveInArray;
    
    NSMutableArray       *custAccList;
	NSMutableArray       *custAccToLiveInArray;
}

@property (nonatomic, retain) NSMutableArray *custList;
@property (nonatomic, retain) NSMutableArray *custAccList;

@property (nonatomic,assign) id<CustFilterDelegate> delegate;

@property (nonatomic, assign) BOOL isToday;
@property (nonatomic, assign) BOOL isPending;
@property (nonatomic, assign) BOOL isConsult;

+ (void)finalizeStatements;

@end
