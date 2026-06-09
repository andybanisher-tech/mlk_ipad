//
//  SalesInvoiceGrid.h
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol InvoiceGridDelegate
@end

@interface InvoiceGrid : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
    NSMutableArray		 *dateList;
    NSMutableArray       *dateToLiveInArray;
    
    NSMutableArray		 *custList;
    NSMutableArray		 *custToLiveInArray;
    
    NSMutableArray		 *contractList;
    NSMutableArray       *contractToLiveInArray;
    
    NSMutableArray		 *numList;
    NSMutableArray       *numToLiveInArray;
    
    NSMutableArray		 *actionList;
    NSMutableArray       *actionToLiveInArray;
    
    NSMutableArray		 *channelList;
    NSMutableArray       *channelToLiveInArray;
    
    NSMutableArray		 *amountList;
    NSMutableArray       *amountToLiveInArray;

    NSMutableArray		 *statusList;
    NSMutableArray       *statusToLiveInArray;
    
    UINavigationController *navController;
    
    BOOL isPreInvoice;  
    
    NSString    *custAccount;
    NSString    *salesId;
}

@property(nonatomic,assign) id<InvoiceGridDelegate> delegate;

@property(nonatomic,retain)NSMutableArray *dateList;
@property(nonatomic,retain)NSMutableArray *custList;
@property(nonatomic,retain)NSMutableArray *contractList;
@property(nonatomic,retain)NSMutableArray *numList;
@property(nonatomic,retain)NSMutableArray *actionList;
@property(nonatomic,retain)NSMutableArray *channelList;
@property(nonatomic,retain)NSMutableArray *amountList;
@property(nonatomic,retain)NSMutableArray *statusList;
@property(nonatomic,readwrite) BOOL isPreInvoice;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSString *salesId;
+(void)finalizeStatements;

- (void)createGrid;
- (void)createPreGrid;
- (void)refreshData;

@end
