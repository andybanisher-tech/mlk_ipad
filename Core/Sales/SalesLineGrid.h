//
//  SalesLineGrid.h
//  MLK
//
//  Created by Rustem Galyamov on 03.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol SalesLineDelegate
- (void)gridIsUpdated;
- (UITableView *)getTV;

@end

@interface SalesLineGrid : UITableViewController <UITableViewDelegate,UITableViewDataSource, UITextFieldDelegate> {
	
    NSString             *sumQty;
    NSString             *sumAmount;
    NSString             *salesId;
    
    BOOL isOpen;
    BOOL isNewText;
}

@property(nonatomic,assign) id<SalesLineDelegate> delegate;
@property(nonatomic,readwrite) BOOL isOpen;
@property(nonatomic,readwrite) BOOL isNewText;
@property(nonatomic,retain) NSString *sumQty;
@property(nonatomic,retain) NSString *sumAmount;
@property(nonatomic,retain) NSString *salesId;

- (void)createLineList;
- (NSString *)getSumAmount;
- (NSString *)getSumQty;
- (NSInteger)getCountLine;

- (void)refreshData;
- (void)updateSalesTable;

@end
