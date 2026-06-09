//
//  CustCity.h
//  MLK
//
//  Created by Rustem Galyamov on 02.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol CustCityDelegate <NSObject>

- (void)userDidSelectCities:(NSMutableArray *)cities;

@end

@interface CustCity : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray       *cityList;
	NSMutableArray       *cityToLiveInArray;
    
    BOOL visitPlan;
    BOOL addCust;
    
    BOOL fromTask;
    
    NSString *custAcccount;
    
    id setBtn;
    NSMutableArray *citySelected;
    NSMutableArray *selected;
}
 
@property(nonatomic, retain)NSMutableArray  *cityList;
@property(nonatomic, readwrite)BOOL visitPlan;
@property(nonatomic, readwrite)BOOL addCust;
@property(nonatomic, weak) id<CustCityDelegate> delegate;
@property(nonatomic, readwrite)BOOL fromTask;
@property(nonatomic, retain)NSString *custAcccount;
@property(nonatomic, retain)NSMutableArray *citySelected;
@property(nonatomic, retain)NSMutableArray *selected;
@property(nonatomic, retain)id setBtn;

- (void)cityListCreate;

+ (void)finalizeStatements;

@end

