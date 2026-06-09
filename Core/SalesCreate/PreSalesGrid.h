//
//  PreSalesGrid.h
//  MLK
//
//  Created by Rustem Galyamov on 25.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "PutOrdersNewRequest.h"

@protocol PreSalesGridDelegate
- (void)gridIsUpdated;
- (UITableView *)getTV;

@end

@interface PreSalesGrid : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
    NSString             *sumQty;
    NSString             *sumAmount;
    NSString             *custAccount;
    NSString             *comment;
    NSString             *deliveryDate;
    NSString             *storeID;
    NSString             *firmId;
    NSString             *firmName;
    NSString             *firmMarkup;
    
    PutOrdersNewRequest     *setSalesToServer;

    UITextField          *myFirstFocusField;
    
    BOOL                 sendSales;
    
    NSString             *actionCheckAmount;
    NSString             *actionCheckQty;
    NSString             *actId;
    
    BOOL isNewText;
}

@property (nonatomic,assign) id<PreSalesGridDelegate> delegate;
@property (nonatomic,readwrite) BOOL sendSales;
@property (nonatomic,retain) NSString       *sumQty;
@property (nonatomic,retain) NSString       *sumAmount;
@property (nonatomic,retain) NSString       *custAccount;
@property (nonatomic,retain) NSString       *comment;
@property (nonatomic,retain) NSString       *deliveryDate;
@property (nonatomic,retain) NSString       *storeID;
@property (nonatomic,retain) NSMutableArray *availList;
@property (nonatomic,retain) NSString       *actionCheckAmount;
@property (nonatomic,retain) NSString       *actionCheckQty;
@property (nonatomic,retain) NSString       *actId;
@property (nonatomic,retain) NSString       *firmId;
@property (nonatomic,retain) NSString       *firmName;
@property (nonatomic,retain) NSString       *firmMarkup;
@property (nonatomic,readwrite)BOOL isNewText;
 
@property (nonatomic, assign) BOOL isConsult;

- (void)createLineList;
-(NSString *)getSumAmount;
-(NSString *)getSumQty;
- (void)updateArrays:(NSIndexPath *)indexPath;
- (void)createSalesFromTmp:(NSString *)salesId merge:(BOOL)mergeSale;
- (void)sendSales:(NSString *)salesId;
-(BOOL)custInVisit:(NSString *)custAcc date:(NSString *)strDate;
+(void)finalizeStatements;
- (void)refreshData;
-(BOOL)noSalesLine;
-(NSString *)getActionId;
-(NSString *)getActionType;
- (void)getCheckParam:(NSString *)a_Id;
-(NSString*)getCheckedAmount;
-(NSString*)getCheckedQty;
- (void)fillCheckParms;

- (NSInteger)getCountLine;
- (NSString *)getStoreID;
- (NSString *)getFirmID;
- (NSString *)getFirmName;
- (NSString *)getFirmMarkup;

@end

