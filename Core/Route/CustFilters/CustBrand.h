//
//  CustBrand.h
//  MLK
//
//  Created by Rustem Galyamov on 05.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"

#import "sqlite3.h"

@protocol CustBrandDelegate <NSObject>

- (void)userDidSelectBrand:(NSMutableArray *)brandArray;

@end

@interface CustBrand : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray       *brandList;
	NSMutableArray       *brandToLiveInArray;
    
    NSMutableArray       *brandIdList;
	NSMutableArray       *brandIdToLiveInArray;
    
    BOOL visitPlan;
    BOOL addCust;
    id                      setBtn;
    NSMutableArray          *brandSelected;
    NSMutableArray          *selected;
    
}
@property(nonatomic,retain)NSMutableArray  *brandList;
@property(nonatomic,retain)NSMutableArray  *brandIdList;
@property(nonatomic,readwrite)BOOL visitPlan;
@property(nonatomic,readwrite)BOOL addCust;
@property(nonatomic,assign) id<CustBrandDelegate> delegate;
@property(nonatomic,retain)NSMutableArray *brandSelected;
@property(nonatomic,retain)NSMutableArray *selected;
@property(nonatomic,retain)id setBtn;

- (void)brandCreate;

+ (void)finalizeStatements;

@end

