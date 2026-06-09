//
//  NewSalesGrid.h
//  MLK
//
//  Created by Rustem Galyamov on 14.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "PutOrdersNewRequest.h"
#import "SalesLineView.h"
#import "CustFilter.h"
#import "DateFilter.h"
#import "ChannelFilter.h"
#import "StatusFilter.h"

@protocol NewSalesGridDelegate
@end

@class SalesLineView;

@interface NewSalesGrid : UIViewController <UITableViewDelegate,UITableViewDataSource, CustFilterDelegate, DateFilterDelegate, ChannelFilterDelegate, StatusFilterDelegate, SalesLineViewDelegate> {
    NSMutableArray		 *custList;
    NSMutableArray		 *custToLiveInArray;
    
    NSMutableArray		 *salesList;
    NSMutableArray       *salesToLiveInArray;
    
    NSMutableArray		 *dateList;
    NSMutableArray       *dateToLiveInArray;
    
    NSMutableArray		 *amountList;
    NSMutableArray       *amountToLiveInArray;
    
    NSMutableArray		 *numList;
    NSMutableArray       *numToLiveInArray;
    
    NSMutableArray		 *channelList;
    NSMutableArray       *channelToLiveInArray;
    
    NSMutableArray		 *contractList;
    NSMutableArray       *contractToLiveInArray;
    
    NSMutableArray		 *statusList;
    NSMutableArray       *statusToLiveInArray;
    
    NSMutableArray		 *num1CList;
    NSMutableArray       *num1CToLiveInArray;
    
    NSMutableArray		 *actionTypeList;
    NSMutableArray       *actionTypeToLiveInArray;

    NSMutableArray		 *deliveryDateList;
    NSMutableArray       *deliveryDateToLiveInArray;
    
    NSString             *customer;
    NSString             *amount;
    NSString             *num1C;
    NSString             *deliveryDate;
    
    PutOrdersNewRequest     *setSalesToServer;
    
    NSString *fcust;
    NSString *fdate;
    NSString *fchannel;
    NSString *fstatus;
    
    id custBtn;
    id dateBtn;
    id channelBtn;
    id statusBtn;
    
    UITableView          *myTableView;
    
    UILabel *labelSalesTotal;
    UIBarButtonItem *editButton;
}

@property (nonatomic, assign) id<NewSalesGridDelegate> delegate;
  
@property (nonatomic, assign) BOOL isToday;
@property (nonatomic, assign) BOOL isPending;
@property (nonatomic, assign) BOOL isConsult;
@property (nonatomic, retain) NSMutableArray *custList;
@property (nonatomic, retain) NSMutableArray *salesList;
@property (nonatomic, retain) NSMutableArray *dateList;
@property (nonatomic, retain) NSMutableArray *amountList;
@property (nonatomic, retain) NSMutableArray *numList;
@property (nonatomic, retain) NSMutableArray *channelList;
@property (nonatomic, retain) NSMutableArray *contractList;
@property (nonatomic, retain) NSMutableArray *statusList;
@property (nonatomic, retain) NSMutableArray *num1CList;
@property (nonatomic, retain) NSMutableArray *actionTypeList;
@property (nonatomic, retain) NSString *deliveryDate;
@property (nonatomic, retain) NSString *customer;
@property (nonatomic, retain) NSString *amount;
@property (nonatomic, retain) NSString *num1C;

@property(nonatomic,retain)NSString *fcust;
@property(nonatomic,retain)NSString *fdate;
@property(nonatomic,retain)NSString *fchannel;
@property(nonatomic,retain)NSString *fstatus;

@property(nonatomic,retain)id custBtn;
@property(nonatomic,retain)id dateBtn;
@property(nonatomic,retain)id channelBtn;
@property(nonatomic,retain)id statusBtn;

@property(nonatomic,retain)UILabel *labelSalesTotal;

@property(nonatomic,retain)UITableView *myTableView;

- (void)finalizeStatements;
- (void)refreshData;

- (void)updateArrays:(NSIndexPath *)indexPath;
- (void)removeSales:(NSString *)salesId salesDate:(NSString *)salesDate;
- (void)showCust:(id)sender;
- (void)showDate:(id)sender;
- (void)showChannel:(id)sender;
- (void)showStatus:(id)sender;
- (void)clearFilter;

- (void)selectCust:(NSString *)cust;
- (void)selectDate:(NSString *)dateStr;
- (void)selectChannel:(NSString *)channel;
- (void)selectStatus:(NSString *)status;

- (void)selectWithFilters;
-(BOOL)salesIsOpen:(NSString *)salesId;
- (void)updateSalesTable:(NSString *)salesId sendTime:(NSString*)sendTime;
-(NSString*)totalSalesSum;
- (void)getComment:(NSString*)salesId;

@end
