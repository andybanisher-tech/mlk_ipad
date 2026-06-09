//
//  NewSalesGrid.m
//  MLK
//
//  Created by Rustem Galyamov on 14.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "NewSalesGrid.h"
#import "MyTableCell.h"
#import "SalesLineView.h"
#import "XMLWriter.h"
#import "PutOrdersNewRequest.h"
#import "SalesPdfRequest.h"

#import "ASPPDFReaderViewController.h"

// Andrey
#import "GetOrdersRequest.h"
#import "RWBorderedButton.h"

//Custom Objects
#import "DocumentType.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@interface NewSalesGrid ()
@property (nonatomic, copy) NSString *salesTable;
@property (nonatomic, copy) NSString *salesLineTable;

@end

@implementation NewSalesGrid

@synthesize delegate;
@synthesize custList;
@synthesize salesList;
@synthesize dateList;
@synthesize amountList;
@synthesize numList;
@synthesize channelList;
@synthesize contractList;
@synthesize statusList;
@synthesize num1CList;
@synthesize actionTypeList;
@synthesize customer, amount, num1C;
//@synthesize salesLineView;
@synthesize channelBtn;
@synthesize statusBtn;
@synthesize fchannel, fstatus;

@synthesize fcust, custBtn;
@synthesize fdate, dateBtn;
@synthesize labelSalesTotal;

@synthesize myTableView;
@synthesize deliveryDate;

#define LABEL_TAG 1

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self refreshData];
    [self.navigationController.navigationBar addSubview:labelSalesTotal];
    labelSalesTotal.text = [self totalSalesSum];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self finalizeStatements];
}

- (void)loadView{
    [super loadView];
    
    if (self.isConsult) {
        self.salesTable = @"ConsultSalesTable";
        self.salesLineTable = @"ConsultSalesLine";
    } else {
        self.salesTable = @"SalesTable";
        self.salesLineTable = @"SalesLine";
    }
    
    //NavBar Setup
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];
    
    [self.navigationController.navigationBar addSubview:titleView];
    
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];
    [self.view addSubview:bgImage];
    
    bgImage.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[bgImage.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [bgImage.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [bgImage.topAnchor constraintEqualToAnchor:self.view.topAnchor],
       [bgImage.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    
    //[self selectWithFilters];
    RWBorderedButton *editBtn = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,130,30) title:@"Изменить"];
    [editBtn addTarget:self
                action:@selector(btnEditTapped)
      forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:editBtn];
    barButton.enabled = !self.isConsult;
    editButton = barButton;
    
    UIBarButtonItem *btnRefresh = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:ACImageNameRefresh] style:UIBarButtonItemStylePlain target:self action:@selector(btnRefreshTapped)];
    btnRefresh.enabled = !self.isConsult;
    
    self.navigationItem.rightBarButtonItems = @[editButton, btnRefresh];
    
    labelSalesTotal = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 20)];
    labelSalesTotal.tag = 1;
    labelSalesTotal.backgroundColor = UIColor.clearColor;
    labelSalesTotal.font = [UIFont boldSystemFontOfSize:16];
    labelSalesTotal.adjustsFontSizeToFitWidth = NO;
    labelSalesTotal.textAlignment = NSTextAlignmentLeft;
    labelSalesTotal.textColor = [ASPFunctions colorFromHex:@"f0f0f0"];
    labelSalesTotal.text = [self totalSalesSum];
    labelSalesTotal.highlightedTextColor = [UIColor blackColor];
    
    [self.navigationController.navigationBar addSubview:labelSalesTotal];
    
    UIToolbar *head = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.navigationController.navigationBar.frame), 44.0)];
    head.barTintColor = [UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1];
    head.translucent = NO;
    
    NSMutableArray *btns = [NSMutableArray new];
    
    //create a spacer
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = 10.0;
    
    [btns addObject:spacer];
    
    // create a standard "refresh" button
    RWBorderedButton *customerButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Клиент"];
    [customerButton addTarget:self action:@selector(showCust:)
             forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cust = [[UIBarButtonItem alloc] initWithCustomView:customerButton];
    
    [btns addObject:cust];
    [btns addObject:spacer];
    custBtn = cust;
    
    if (!self.isToday) {
        RWBorderedButton *orderDateButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,120,30) title:@"Дата заказа"];
        [orderDateButton addTarget:self action:@selector(showDate:)
                  forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *date = [[UIBarButtonItem alloc] initWithCustomView:orderDateButton];
        dateBtn = date;
        [btns addObject:date];
        [btns addObject:spacer];
    }
    
    if (!self.isConsult) {
        RWBorderedButton *channelButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,140,30) title:@"Источник заказа"];
        [channelButton addTarget:self action:@selector(showChannel:)
                forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *channel = [[UIBarButtonItem alloc] initWithCustomView:channelButton];
        [btns addObject:channel];
        [btns addObject:spacer];
        channelBtn = channel;
        
        RWBorderedButton *orderStateButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,140,30) title:@"Статус заказа"];
        [orderStateButton addTarget:self action:@selector(showStatus:)
                   forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *status = [[UIBarButtonItem alloc] initWithCustomView:orderStateButton];
        
        [btns addObject:status];
        [btns addObject:spacer];
        statusBtn = status;
    }
    
    [head setItems:btns animated:NO];
    
    [self.view addSubview:head];
    head.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[head.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [head.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [head.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
       [head.heightAnchor constraintEqualToConstant:head.frame.size.height]]];
    
    myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 44.0, 703.0, 620.0)];
    
    myTableView.delegate = self;
    myTableView.dataSource = self;
    
    myTableView.separatorColor = UIColor.clearColor;
    myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [myTableView setBackgroundColor:UIColor.clearColor];
    
    [self.view addSubview:myTableView];
    myTableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[myTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [myTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [myTableView.topAnchor constraintEqualToAnchor:head.bottomAnchor],
       [myTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    
    //Notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshData) name:@"SalesUpdated" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(salesSended:) name:@"SalesSended" object:nil];
}

#pragma mark - Button Actions
- (void)btnEditTapped {
    BOOL editing = !self.editing;
    [self setBarButton:editButton highlighted:editing];
    [self setEditing: editing animated: YES];
}

- (void)btnRefreshTapped {
    GetOrdersRequest *salesRequest = [GetOrdersRequest new];
    salesRequest.removeOld = YES;
    salesRequest.synsSalesLine = NO;
    salesRequest.syncNum1C = @"";
    [salesRequest salesReq];
}

#pragma mark - SalesLineViewDelegate
- (void)userDidSendSales:(NSString *)salesID {
    [self sendSales:salesID salesUUID:nil];
}

#pragma mark - Notifications
- (void)refreshData {
    if (self.tabBarController.selectedIndex == 2) {
        [self selectWithFilters];
        labelSalesTotal.text = [self totalSalesSum];
    }
}

- (void)salesSended:(NSNotification *)notification {
    if (self.tabBarController.selectedIndex == 2) {
        NSDictionary *object = notification.object;
        if ([object[@"salesStatus"] localizedStandardContainsString:@"новый заказ"]) {
            [SVProgressHUD dismiss];
            [AlertWorkerObjc alertWithTitle:@"Изменение реализации невозможно, создать новый заказ?" message:nil buttons:@[@"Да", @"Нет"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
                if (index == 0) {
                    [self sendSales:object[@"salesID"] salesUUID:NSUUID.UUID.UUIDString];
                }
            }];
        } else {
            [SVProgressHUD showInfoWithStatus:object[@"salesStatus"]];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            [self refreshData];
        }
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    /*if (editing == YES)
     self.editButtonItem.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
     else
     self.editButtonItem.tintColor = UIColor.clearColor;*/
    
    [super setEditing: editing animated: animated];
    [myTableView setEditing:editing animated:animated];
    
    NSInteger count = 0;
    
    NSDictionary *statusDict = [statusList objectAtIndex:0];
    NSArray		 *statusArray = [statusDict objectForKey:@"Status"];
    
    for (int i = 0; i < [statusArray count]; i++) {
        NSString     *statusValue = [statusArray objectAtIndex:i];
        
        if ([statusValue isEqualToString:@"Открыт"] | [statusValue isEqualToString:@"Ошибка"])
            count++;
    }
    
    /*if (count > 0)
     self.editButtonItem.enabled = YES;
     else
     self.editButtonItem.enabled = FALSE;*/
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *salesDict = [salesList objectAtIndex:indexPath.section];
    NSArray		 *salesArray = [salesDict objectForKey:@"Sales"];
    NSString     *salesId = [salesArray objectAtIndex:indexPath.row];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([self salesIsOpen:salesId]) {
            [self updateArrays:indexPath];
            
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            [tableView reloadData];
            
            NSInteger count = 0;
            
            NSDictionary *statusDict = [statusList objectAtIndex:0];
            NSArray		 *statusArray = [statusDict objectForKey:@"Status"];
            
            for (int i = 0; i < [statusArray count]; i++) {
                NSString     *statusValue = [statusArray objectAtIndex:i];
                
                if ([statusValue isEqualToString:@"Открыт"] | [statusValue isEqualToString:@"Ошибка"])
                    count++;
            }
            
            //if (count > 0)
            //    self.editButtonItem.enabled = YES;
            //else
            //    self.editButtonItem.enabled = FALSE;
        }
    }
    
    //if (isToday)
    labelSalesTotal.text = [self totalSalesSum];
}

- (BOOL)salesIsOpen:(NSString *)salesId {
    return YES;
#warning - Uncomment later!!!
    //    BOOL isOpen = FALSE;
    //
    //    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
    //    NSString *sqlString = [NSString stringWithFormat:@"select SalesStatus from %@ where SalesId = ? and (SalesStatus == 'Открыт' or SalesStatus == 'Ошибка') and Num1C is NULL", self.salesTable];
    //    const char *sql = sqlString.UTF8String;
    //        sqlite3_stmt *statement;
    //
    //        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    //        {
    //            sqlite3_bind_text(statement, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
    //
    //            if (sqlite3_step(statement) == SQLITE_ROW)
    //                isOpen = YES;
    //        }
    //        sqlite3_finalize(statement);
    //    }
    //    sqlite3_close(database);
    //
    //    NSString *zakaz = [PersistenceWorker load:@"zakaz"];
    //
    //    if (![zakaz isEqualToString:@"1"])
    //        isOpen = NO;
    //
    //    return isOpen;
}

-(NSString*)totalSalesSum{
    NSDictionary *amountDict = [amountList objectAtIndex:0];
    NSArray		 *amountArray = [amountDict objectForKey:@"Amount"];
    NSString     *amountValue;
    double total = 0.0;
    if ([amountArray count] > 0) {
        for (int i=0; i<[amountArray count]; i++) {
            amountValue = [amountArray objectAtIndex:i];
            
            total += [amountValue doubleValue];
        }
    }
    
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%0.2f", total]];
    NSLocale *priceLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru_RU"];
    
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    [currencyFormatter setGroupingSeparator:@" "];
    [currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [currencyFormatter setLocale:priceLocale];
    //NSString *currencyString = [currencyFormatter internationalCurrencySymbol]; // EUR, GBP, USD...
    NSString *format = [currencyFormatter positiveFormat];
    //format = [format stringByReplacingOccurrencesOfString:@"¤" withString:currencyString];
    // ¤ is a placeholder for the currency symbol
    [currencyFormatter setPositiveFormat:format];
    NSString *currString = [currencyFormatter stringFromNumber:price];
    return [NSString stringWithFormat:@"Итого: %@", currString];
}

- (void)updateArrays:(NSIndexPath *)indexPath {
    NSDictionary *custDict = [custList objectAtIndex:indexPath.section];
    NSArray		 *custArray = [custDict objectForKey:@"Cust"];
    
    NSDictionary *salesDict = [salesList objectAtIndex:indexPath.section];
    NSArray		 *salesArray = [salesDict objectForKey:@"Sales"];
    NSString     *salesId = [salesArray objectAtIndex:indexPath.row];
    
    NSDictionary *dateDict = [dateList objectAtIndex:indexPath.section];
    NSArray		 *dateArray = [dateDict objectForKey:@"Date"];
    NSString     *date = [dateArray objectAtIndex:indexPath.row];
    
    NSDictionary *amountDict = [amountList objectAtIndex:indexPath.section];
    NSArray		 *amountArray = [amountDict objectForKey:@"Amount"];
    
    NSDictionary *numDict = [numList objectAtIndex:indexPath.section];
    NSArray		 *numArray = [numDict objectForKey:@"Num"];
    
    NSDictionary *channelDict = [channelList objectAtIndex:indexPath.section];
    NSArray		 *channelArray = [channelDict objectForKey:@"Channel"];
    
    NSDictionary *contractDict = [contractList objectAtIndex:indexPath.section];
    NSArray		 *contractArray = [contractDict objectForKey:@"Contract"];
    
    NSDictionary *statusDict = [statusList objectAtIndex:indexPath.section];
    NSArray		 *statusArray = [statusDict objectForKey:@"Status"];
    
    NSDictionary *cDict = [num1CList objectAtIndex:indexPath.section];
    NSArray		 *cArray = [cDict objectForKey:@"Num1C"];
    
    NSDictionary *actionTypeDict = [actionTypeList objectAtIndex:indexPath.section];
    NSArray		 *actionTypeArray = [actionTypeDict objectForKey:@"actionType"];
    
    NSMutableArray *afterRemCust = [NSMutableArray arrayWithArray:custArray];
    NSMutableArray *afterRemSales = [NSMutableArray arrayWithArray:salesArray];
    NSMutableArray *afterRemDate = [NSMutableArray arrayWithArray:dateArray];
    NSMutableArray *afterRemAmount = [NSMutableArray arrayWithArray:amountArray];
    NSMutableArray *afterRemNum = [NSMutableArray arrayWithArray:numArray];
    NSMutableArray *afterRemChannel = [NSMutableArray arrayWithArray:channelArray];
    NSMutableArray *afterRemContract = [NSMutableArray arrayWithArray:contractArray];
    NSMutableArray *afterRemStatus = [NSMutableArray arrayWithArray:statusArray];
    NSMutableArray *afterRemNum1C = [NSMutableArray arrayWithArray:cArray];
    NSMutableArray *afterRemActionType = [NSMutableArray arrayWithArray:actionTypeArray];
    
    [afterRemCust       removeObjectAtIndex:indexPath.row];
    [afterRemSales      removeObject:salesId];
    [afterRemDate       removeObjectAtIndex:indexPath.row];
    [afterRemAmount     removeObjectAtIndex:indexPath.row];
    [afterRemNum        removeObjectAtIndex:indexPath.row];
    [afterRemChannel    removeObjectAtIndex:indexPath.row];
    [afterRemContract   removeObjectAtIndex:indexPath.row];
    [afterRemStatus     removeObjectAtIndex:indexPath.row];
    [afterRemNum1C      removeObjectAtIndex:indexPath.row];
    [afterRemActionType removeObjectAtIndex:indexPath.row];
    
    NSDictionary *custToLiveInDict = [NSDictionary dictionaryWithObject:afterRemCust forKey:@"Cust"];
    NSDictionary *salesIdNameToLiveInDict = [NSDictionary dictionaryWithObject:afterRemSales forKey:@"Sales"];
    NSDictionary *salesDateToLiveInDict = [NSDictionary dictionaryWithObject:afterRemDate forKey:@"Date"];
    NSDictionary *amountSumToLiveInDict = [NSDictionary dictionaryWithObject:afterRemAmount forKey:@"Amount"];
    NSDictionary *salesNumToLiveInDict = [NSDictionary dictionaryWithObject:afterRemNum forKey:@"Num"];
    NSDictionary *channelTypeToLiveInDict = [NSDictionary dictionaryWithObject:afterRemChannel forKey:@"Channel"];
    NSDictionary *contractIdToLiveInDict = [NSDictionary dictionaryWithObject:afterRemContract forKey:@"Contract"];
    NSDictionary *salesStatusIdToLiveInDict = [NSDictionary dictionaryWithObject:afterRemStatus forKey:@"Status"];
    NSDictionary *num1CToLiveInDict = [NSDictionary dictionaryWithObject:afterRemNum1C forKey:@"Num1C"];
    NSDictionary *actionTypeToLiveInDict = [NSDictionary dictionaryWithObject:afterRemActionType forKey:@"actionType"];
    
    [custList     removeAllObjects];
    [salesList    removeAllObjects];
    [dateList     removeAllObjects];
    [amountList   removeAllObjects];
    [numList      removeAllObjects];
    [channelList  removeAllObjects];
    [contractList removeAllObjects];
    [statusList   removeAllObjects];
    [num1CList    removeAllObjects];
    [actionTypeList removeAllObjects];
    
    [custList     addObject:custToLiveInDict];
    [salesList    addObject:salesIdNameToLiveInDict];
    [dateList     addObject:salesDateToLiveInDict];
    [amountList   addObject:amountSumToLiveInDict];
    [numList      addObject:salesNumToLiveInDict];
    [channelList  addObject:channelTypeToLiveInDict];
    [contractList addObject:contractIdToLiveInDict];
    [statusList   addObject:salesStatusIdToLiveInDict];
    [num1CList    addObject:num1CToLiveInDict];
    [actionTypeList addObject:actionTypeToLiveInDict];
    
    [self removeSales:salesId salesDate:date];
    
    salesId = nil;
    date = nil;
}

- (void)removeSales:(NSString *)salesId salesDate:(NSString *)salesDate {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        sqlite3_stmt *deleteStmt;
        
        NSString *sqlString = [NSString stringWithFormat:@"delete from %@ where SalesId = ? and SalesDate = ?", self.salesTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        
        sqlite3_bind_text(deleteStmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 2, [salesDate UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
        
        sqlite3_stmt *deleteStmt_2;
        
        NSString *sqlString2 = [NSString stringWithFormat:@"delete from %@ where SalesId = ?", self.salesLineTable];
        const char *sql_2 = sqlString2.UTF8String;
        
        sqlite3_prepare_v2(database, sql_2, -1, &deleteStmt_2, NULL);
        
        sqlite3_bind_text(deleteStmt_2, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt_2);
        sqlite3_finalize(deleteStmt_2);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (BOOL)isEndDateSmallerThanCurrent:(NSDate *)checkEndDate {
    NSDate *currentdate = NSDate.date;
    
    NSTimeInterval distanceBetweenDates = [checkEndDate timeIntervalSinceDate:currentdate];
    double secondsInMinute = 60;
    
    NSInteger secondsBetweenDates = distanceBetweenDates / secondsInMinute;
    return secondsBetweenDates <= 0;
}

- (void)selectWithFilters {
    custList = [NSMutableArray new];
    custToLiveInArray = [NSMutableArray array];
    
    salesList = [NSMutableArray new];
    salesToLiveInArray = [NSMutableArray array];
    
    dateList = [NSMutableArray new];
    dateToLiveInArray = [NSMutableArray array];
    
    amountList = [NSMutableArray new];
    amountToLiveInArray = [NSMutableArray array];
    
    numList = [NSMutableArray new];
    numToLiveInArray = [NSMutableArray array];
    
    channelList = [NSMutableArray new];
    channelToLiveInArray = [NSMutableArray array];
    
    contractList = [NSMutableArray new];
    contractToLiveInArray = [NSMutableArray array];
    
    statusList = [NSMutableArray new];
    statusToLiveInArray = [NSMutableArray array];
    
    num1CList = [NSMutableArray new];
    num1CToLiveInArray = [NSMutableArray array];
    
    actionTypeList = [NSMutableArray new];
    actionTypeToLiveInArray = [NSMutableArray array];
    
    deliveryDateList = [NSMutableArray new];
    deliveryDateToLiveInArray = [NSMutableArray array];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate          *date = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select CustAccount, SalesId, SalesDate, AmountSum, SalesNum, ChannelTypeId, ContractId, SalesStatus, Num1C, ActionType, DeliveryDate from %@ where 1=1", self.salesTable];
        const char *sql;
        
        if (self.isToday) {
            sqlString = [NSString stringWithFormat:@"%@ and SalesDate = '%@' and (ChannelTypeId = 'ТП телефон' or ChannelTypeId = 'ТП')", sqlString, strDate];
        }
        if (fcust) {
            sqlString = [NSString stringWithFormat:@"%@ and CustAccount = '%@'", sqlString, fcust];
        }
        if (fdate) {
            sqlString = [NSString stringWithFormat:@"%@ and SalesDate = '%@'", sqlString, fdate];
        }
        if (fchannel) {
            sqlString = [NSString stringWithFormat:@"%@ and ChannelTypeId = '%@'", sqlString, fchannel];
        }
        if (fstatus) {
            sqlString = [NSString stringWithFormat:@"%@ and SalesStatus = '%@'", sqlString, fstatus];
        }
        
        sqlString = [NSString stringWithFormat:@"%@ order by substr(SalesDate,7)||substr(SalesDate,4,2)||substr(SalesDate,1,2) desc, Num1C", sqlString];
        sql = sqlString.UTF8String;
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
            {
                NSString *custAcc = @"null";
                NSString *salesId = @"null";
                NSString *salesDate = @"null";
                NSString *amountSum = @"null";
                NSString *salesNum = @"null";
                NSString *channelType = @"null";
                NSString *contractId = @"null";
                NSString *salesStatus = @"null";
                NSString *custName = @"null";
                NSString *num = @"null";
                NSString *actionType = @"0";
                NSString *deliveryDate = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                const char *sql_1;
                
                sql_1 = "select Name from CustTable where CustAccount = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt) == SQLITE_ROW)
                    {
                        if (sqlite3_column_text(selstmt, 0))
                            custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                    }
                }
                sqlite3_finalize(selstmt);
                
                if (sqlite3_column_text(selectstmt, 1)) {
                    salesId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
             
                if (sqlite3_column_text(selectstmt, 2)) {
                    salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                }
                
                if (sqlite3_column_text(selectstmt, 3)) {
                    amountSum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                }
              
                if (sqlite3_column_text(selectstmt, 4)) {
                    salesNum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                }
                
                if (sqlite3_column_text(selectstmt, 5)) {
                    channelType = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                }
              
                if (sqlite3_column_text(selectstmt, 6)) {
                    contractId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                }
                
                if (sqlite3_column_text(selectstmt, 7)) {
                    salesStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                }
              
                if (sqlite3_column_text(selectstmt, 8)) {
                    num = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                }
                
                if (sqlite3_column_text(selectstmt, 9)) {
                    actionType = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                }
                
                if (sqlite3_column_text(selectstmt, 10)) {
                    deliveryDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                } else {
                    deliveryDate = salesDate.copy;
                }
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                //                NSDate *myDate = [dateFormatter dateFromString: salesDate];
                NSDate *myDate = [dateFormatter dateFromString: deliveryDate];
                if (self.isPending) {
                    if (![self isEndDateSmallerThanCurrent:myDate]) {
                        [custToLiveInArray     addObject:custName];
                        [salesToLiveInArray    addObject:salesId];
                        [dateToLiveInArray     addObject:salesDate];
                        [amountToLiveInArray   addObject:amountSum];
                        [numToLiveInArray      addObject:salesNum];
                        [channelToLiveInArray  addObject:channelType];
                        [contractToLiveInArray addObject:contractId];
                        [statusToLiveInArray   addObject:salesStatus];
                        [num1CToLiveInArray    addObject:num];
                        [actionTypeToLiveInArray   addObject:actionType];
                        [deliveryDateToLiveInArray addObject:deliveryDate];
                    }
                } else {
                    if ([self isEndDateSmallerThanCurrent:myDate]) {
                        [custToLiveInArray     addObject:custName];
                        [salesToLiveInArray    addObject:salesId];
                        [dateToLiveInArray     addObject:salesDate];
                        [amountToLiveInArray   addObject:amountSum];
                        [numToLiveInArray      addObject:salesNum];
                        [channelToLiveInArray  addObject:channelType];
                        [contractToLiveInArray addObject:contractId];
                        [statusToLiveInArray   addObject:salesStatus];
                        [num1CToLiveInArray    addObject:num];
                        [actionTypeToLiveInArray   addObject:actionType];
                        [deliveryDateToLiveInArray addObject:deliveryDate];
                    }
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    NSDictionary *custToLiveInDict = [NSDictionary dictionaryWithObject:custToLiveInArray forKey:@"Cust"];
    NSDictionary *salesIdNameToLiveInDict = [NSDictionary dictionaryWithObject:salesToLiveInArray forKey:@"Sales"];
    NSDictionary *salesDateToLiveInDict = [NSDictionary dictionaryWithObject:dateToLiveInArray forKey:@"Date"];
    NSDictionary *amountSumToLiveInDict = [NSDictionary dictionaryWithObject:amountToLiveInArray forKey:@"Amount"];
    NSDictionary *salesNumToLiveInDict = [NSDictionary dictionaryWithObject:numToLiveInArray forKey:@"Num"];
    NSDictionary *channelTypeToLiveInDict = [NSDictionary dictionaryWithObject:channelToLiveInArray forKey:@"Channel"];
    NSDictionary *contractIdToLiveInDict = [NSDictionary dictionaryWithObject:contractToLiveInArray forKey:@"Contract"];
    NSDictionary *salesStatusIdToLiveInDict = [NSDictionary dictionaryWithObject:statusToLiveInArray forKey:@"Status"];
    NSDictionary *num1CToLiveInDict = [NSDictionary dictionaryWithObject:num1CToLiveInArray forKey:@"Num1C"];
    NSDictionary *actionTypeToLiveInDict = [NSDictionary dictionaryWithObject:actionTypeToLiveInArray forKey:@"actionType"];
    NSDictionary *deliveryDateToLiveInDict = [NSDictionary dictionaryWithObject:deliveryDateToLiveInArray forKey:@"deliveryDate"];
    
    [custList     addObject:custToLiveInDict];
    [salesList    addObject:salesIdNameToLiveInDict];
    [dateList     addObject:salesDateToLiveInDict];
    [amountList   addObject:amountSumToLiveInDict];
    [numList      addObject:salesNumToLiveInDict];
    [channelList  addObject:channelTypeToLiveInDict];
    [contractList addObject:contractIdToLiveInDict];
    [statusList   addObject:salesStatusIdToLiveInDict];
    [num1CList    addObject:num1CToLiveInDict];
    [actionTypeList   addObject:actionTypeToLiveInDict];
    [deliveryDateList addObject:deliveryDateToLiveInDict];
    
    [myTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [salesList count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    NSDictionary *dictionary = [salesList objectAtIndex:section];
    NSArray		 *array = [dictionary objectForKey:@"Sales"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *MyIdentifier = [NSString stringWithFormat:@"MyIdentifier %li", (long)indexPath.row];
    MyTableCell *cell = (MyTableCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    CGFloat rowHeight = 50.f;//tableView.rowHeight;
    
    if (cell == nil) {
        cell = [[MyTableCell alloc] initWithFrame:CGRectZero];
        [cell setBackgroundColor:[ASPFunctions colorFromHex:@"f1f1f1"]];
        [cell addColumn:100];
        [cell addColumn:250];
        [cell addColumn:320];
        [cell addColumn:465];
        [cell addColumn:620];
        
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0, rowHeight - 1.f / UIScreen.mainScreen.scale, tableView.frame.size.width, 1.f / UIScreen.mainScreen.scale)];
        [bottomLine setBackgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground]];
        [cell addSubview:bottomLine];
    }
    
    UILabel *label;
    UIFont *fontSize = [UIFont systemFontOfSize:14.0];
    UIColor *fontColor = [ASPFunctions colorFromHex:@"606164"];
    //NSDictionary *salesDict = [salesList objectAtIndex:indexPath.section];
    //NSArray		 *salesArray = [salesDict objectForKey:@"Sales"];
    //NSString     *salesValue = [salesArray objectAtIndex:indexPath.row];
    
    NSDictionary *salesDict = [num1CList objectAtIndex:indexPath.section];
    NSArray		 *salesArray = [salesDict objectForKey:@"Num1C"];
    NSString     *salesValue = [salesArray objectAtIndex:indexPath.row];
    
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(5.0, 0, 90.0,
                                                        rowHeight)];
    
    label.tag = LABEL_TAG;
    
    label.font = fontSize;
    label.text = salesValue;
    label.textAlignment = NSTextAlignmentCenter;
    
    label.textColor = fontColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:label];
    
    NSDictionary *custDict = [custList objectAtIndex:indexPath.section];
    NSArray		 *custArray = [custDict objectForKey:@"Cust"];
    NSString     *custValue = [custArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(105.0, 0, 170.0,
                                                        rowHeight)];
    label.tag = LABEL_TAG;
    label.font = fontSize;
    label.text = custValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
    [label setNumberOfLines:2];
    [cell.contentView addSubview:label];
    
    NSDictionary *dateDict = [dateList objectAtIndex:indexPath.section];
    NSArray		 *dateArray = [dateDict objectForKey:@"Date"];
    NSString     *dateValue = [dateArray objectAtIndex:indexPath.row];
    
    NSDictionary *deliveryDateDict = [deliveryDateList objectAtIndex:indexPath.section];
    NSArray		 *deliveryDateArray = [deliveryDateDict objectForKey:@"deliveryDate"];
    NSString     *deliveryDateValue = [deliveryDateArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(285.0, 0, 80.0,
                                                        rowHeight)];
    label.tag = LABEL_TAG;
    label.font = fontSize;
    label.text = dateValue;
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = fontColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(370.0, 0, 80.0,
                                                        rowHeight)];
    label.tag = LABEL_TAG;
    label.font = fontSize;
    label.text = deliveryDateValue;
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = fontColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:label];
    
    
    NSDictionary *channelDict = [channelList objectAtIndex:indexPath.section];
    NSArray		 *channelArray = [channelDict objectForKey:@"Channel"];
    NSString     *channelValue = [channelArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(455.0, 0, 85.0,
                                                        rowHeight)];
    label.tag = LABEL_TAG;
    label.font = fontSize;
    label.text = channelValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:label];
    
    NSDictionary *amountDict = [amountList objectAtIndex:indexPath.section];
    NSArray		 *amountArray = [amountDict objectForKey:@"Amount"];
    NSString     *amountValue = [amountArray objectAtIndex:indexPath.row];
    
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:amountValue];
    NSLocale *priceLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru_RU"]; // get the locale from your SKProduct
    
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    [currencyFormatter setGroupingSeparator:@" "];
    [currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [currencyFormatter setLocale:priceLocale];
    //NSString *currencyString = [currencyFormatter internationalCurrencySymbol]; // EUR, GBP, USD...
    NSString *format = [currencyFormatter positiveFormat];
    //format = [format stringByReplacingOccurrencesOfString:@"¤" withString:currencyString];
    // ¤ is a placeholder for the currency symbol
    [currencyFormatter setPositiveFormat:format];
    
    NSString *currString = [currencyFormatter stringFromNumber:price];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(545.0, 0, 85.0,
                                                        rowHeight)];
    label.tag = LABEL_TAG;
    label.font = fontSize;
    label.text = currString;//amountValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:label];
    
    NSDictionary *statusDict = [statusList objectAtIndex:indexPath.section];
    NSArray		 *statusArray = [statusDict objectForKey:@"Status"];
    NSString     *statusValue = [statusArray objectAtIndex:indexPath.row];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(625.0, 0.0, tableView.frame.size.width - 630.0,
                                                      rowHeight)];
    label.tag = LABEL_TAG;
    label.font = fontSize;
    label.text = statusValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:label];
    
    cell.viewToHideOnDeleteState = label;
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *custDict = [custList objectAtIndex:indexPath.section];
    NSArray		 *custArray = [custDict objectForKey:@"Cust"];
    NSString     *custValue = [custArray objectAtIndex:indexPath.row];
    
    NSDictionary *salesDict = [salesList objectAtIndex:indexPath.section];
    NSArray		 *salesArray = [salesDict objectForKey:@"Sales"];
    NSString     *salesID = [salesArray objectAtIndex:indexPath.row];
    
    NSDictionary *amountDict = [amountList objectAtIndex:indexPath.section];
    NSArray		 *amountArray = [amountDict objectForKey:@"Amount"];
    NSString     *amountValue = [amountArray objectAtIndex:indexPath.row];
    
    NSDictionary *numDict = [num1CList objectAtIndex:indexPath.section];
    NSArray		 *numArray = [numDict objectForKey:@"Num1C"];
    NSString     *numValue = [numArray objectAtIndex:indexPath.row];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select DeliveryDate from %@ where SalesId = ?", self.salesTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [salesID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_text(statement, 0))
                {
                    deliveryDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                }
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    customer = custValue;
    amount = amountValue;
    num1C = numValue;
    
    [self viewActionSheetAtIndexPath:indexPath salesID:salesID];
}

- (void)viewActionSheetAtIndexPath:(NSIndexPath *)indexPath salesID:(NSString *)salesID{
    //	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //    NSDate          *currentDate = NSDate.date;
    //
    //    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    //    NSDate *delivDate = [dateFormatter dateFromString:deliveryDate];
    //    currentDate = [dateFormatter dateFromString:[dateFormatter stringFromDate:currentDate]];
    //
    //    NSComparisonResult comparisonResult = [delivDate compare:currentDate];
    //    if ([self salesIsOpen:salesId] && [deliveryDate isEqualToString:[dateFormatter stringFromDate:date]])
    
    NSDictionary *statusDict = [statusList objectAtIndex:0];
    NSArray *statusArray = [statusDict objectForKey:@"Status"];
    NSString *statusValue = [statusArray objectAtIndex:indexPath.row];
    
    NSMutableArray *buttonsArray = [NSMutableArray arrayWithArray:[self documentTypeNames]];
    [buttonsArray addObject:@"Отмена"];
    
    if (!self.isConsult) {
        if (![self isSalesLineExist:salesID]) {
            if ([statusValue isEqualToString:@"Открыт"]) {
                buttonsArray = @[@"Синхронизировать заказ", @"Отмена"].mutableCopy;
            } else {
                [buttonsArray insertObject:@"Синхронизировать заказ" atIndex:0];
            }
        } else {
            if ([statusValue isEqualToString:@"Открыт"] || [statusValue isEqualToString:@"Ошибка"]) {
                buttonsArray = @[@"Строки заказа", @"Отправить", @"Отмена"].mutableCopy;
            } else {
                [buttonsArray insertObject:@"Строки заказа" atIndex:0];
            }
        }
    }
    //    if ([self salesIsOpen:salesId] && (comparisonResult == NSOrderedSame || comparisonResult == NSOrderedDescending) {
    //        buttonsArray = @[@"Строки заказа", @"Отправить", @"Отмена"].mutableCopy;
    //    } else {
    //        if ([self isSalesLineExist:salesId]) {
    //            buttonsArray = @[@"Строки заказа", @"Отмена"].mutableCopy;
    //        } else {
    //            buttonsArray = @[@"Строки заказа", @"Синхронизировать заказ", @"Отмена"].mutableCopy;
    //        }
    //    }
    
    [AlertWorkerObjc actionSheetWithTitle:@"Выберите действие" message:nil sourceView:self.view buttons:buttonsArray tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        
        if ([action.title isEqual:@"Отправить"]) {
            [self sendSales:salesID salesUUID:nil];
        } else if ([action.title isEqual:@"Синхронизировать заказ"]) {
            GetOrdersRequest *salesLineRequest = [GetOrdersRequest new];
            salesLineRequest.synsSalesLine = YES;
            salesLineRequest.syncNum1C = self->num1C;
            
            [salesLineRequest salesLineReq:self->num1C];
        } else if ([action.title isEqual:@"Строки заказа"]) {
            
            SalesLineView *salesLineView = [[SalesLineView alloc] initWithNibName: @"SalesLineView" bundle: nil];
            salesLineView.delegate = self;
            
            salesLineView.isViewPushed = NO;
            salesLineView.customer = self->customer;
            salesLineView.salesId = salesID;
            salesLineView.sumAmount = self->amount;
            salesLineView.num1C = self->num1C;
            salesLineView.isOpen = [self salesIsOpen:salesID];
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:salesLineView];
            
            navController.modalPresentationStyle = UIModalPresentationFullScreen;
            
            dispatch_async(dispatch_get_main_queue(),^() {
                [self.navigationController presentViewController:navController animated:YES completion:nil];
            });
            salesLineView = nil;
            navController = nil;
        } else if ([[self documentTypeNames] containsObject:action.title]) {
            DocumentType *docType = [ASPFunctions firstObjectInArray:[self documentTypes] where:^BOOL(DocumentType *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj.name isEqualToString:action.title];
            }];
            [self requestDocument:docType salesID:salesID];
        }
    }];
}

- (void)getComment:(NSString*)salesId {
    NSString *comment = @"Комментарии отсутствуют";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select Comment from %@ where SalesId = ?", self.salesTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_text(statement, 0))
                    comment = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    if (comment) {
        [AlertWorkerObjc alertWithTitle:@"Комментарий" message:comment];
    }
}

- (NSString *)getSalesUUID:(NSString *)salesID {
    NSString *salesUUID;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select SalesUUID from %@ where SalesId = ?", self.salesTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [salesID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_text(statement, 0))
                    salesUUID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return salesUUID;
}

- (void)sendSales:(NSString *)salesID salesUUID:(nullable NSString *)salesUUID {
    [SVProgressHUD showWithStatus:@"Отправка..."];
    
    XMLWriter* xmlWriter = [XMLWriter new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select SalesDate, StoreID, CustAccount, ContractId, AmountSum, ChannelTypeId, SalesStatus, Comment, SalesUUID, DeliveryDate, CreatedTime, ActionId, FirmId, Merge from %@ where SalesId = ?", self.salesTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [salesID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *salesDate;
                NSString *storeID;
                NSString *custAcc;
                NSString *contractId;
                NSString *amountSum;
                NSString *channelTypeId;
                NSString *salesStatus;
                NSString *comment;
                NSString *uuid = @"";
                NSString *dlvDate;
                NSString *crTime;
                NSString *actionId;
                NSString *f_id;
                NSString *merge;
                
                if (!sqlite3_column_text(selectstmt, 0))
                    salesDate = @"";
                else
                    salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (!sqlite3_column_text(selectstmt, 1)) {
                    storeID = @"";
                } else {
                    storeID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
                
                if (!sqlite3_column_text(selectstmt, 2))
                    custAcc = @"";
                else
                    custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (!sqlite3_column_text(selectstmt, 3))
                    contractId = @"";
                else
                    contractId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (!sqlite3_column_text(selectstmt, 4))
                    amountSum = @"";
                else
                    amountSum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (!sqlite3_column_text(selectstmt, 5))
                    channelTypeId = @"";
                else
                    channelTypeId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (!sqlite3_column_text(selectstmt, 6))
                    salesStatus = @"";
                else
                    salesStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (!sqlite3_column_text(selectstmt, 7))
                    comment = @"";
                else
                    comment = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (salesUUID) {
                    uuid = salesUUID;
                } else if (sqlite3_column_text(selectstmt, 8)) {
                    uuid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                }
                
                if (!sqlite3_column_text(selectstmt, 9))
                    dlvDate = @"";
                else
                    dlvDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if (!sqlite3_column_text(selectstmt, 10))
                    crTime = @"";
                else
                    crTime = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (!sqlite3_column_text(selectstmt, 11))
                    actionId = @"";
                else
                    actionId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                if (!sqlite3_column_text(selectstmt, 12))
                    f_id = @"";
                else
                    f_id = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 12)];
                
                if (!sqlite3_column_text(selectstmt, 13))
                    merge = @"0";
                else
                    merge = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 13)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:SalesNum"];
                [xmlWriter writeCharacters:salesID];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesDate"];
                [xmlWriter writeCharacters:salesDate];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:StoreID"];
                [xmlWriter writeCharacters:storeID];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ContractID"];
                [xmlWriter writeCharacters:contractId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:AmountSum"];
                [xmlWriter writeCharacters:amountSum];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ChannelTypeID"];
                [xmlWriter writeCharacters:channelTypeId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesStatus"];
                [xmlWriter writeCharacters:salesStatus];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Comment"];
                [xmlWriter writeCharacters:comment];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesUUID"];
                [xmlWriter writeCharacters:uuid];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:DeliveryDate"];
                [xmlWriter writeCharacters:dlvDate];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CreatedTime"];
                [xmlWriter writeCharacters:crTime];
                [xmlWriter writeEndElement];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                NSDate *today = NSDate.date;
                [dateFormatter setDateFormat:@"HH:mm:ss"];
                NSString *sendTime = [dateFormatter stringFromDate:today];
                
                [self updateSalesTable:salesID sendTime:sendTime];
                
                [xmlWriter writeStartElement:@"sam:SendTime"];
                [xmlWriter writeCharacters:sendTime];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ActionID"];
                [xmlWriter writeCharacters:actionId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:FirmID"];
                [xmlWriter writeCharacters:f_id];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:NoMerge"];
                [xmlWriter writeCharacters:merge];
                [xmlWriter writeEndElement];
                
                NSString *sqlString = [NSString stringWithFormat:@"select ItemId, Qty, LineAmount, StoreID, isBadProduct from %@ where SalesId = ?", self.salesLineTable];
                const char *sql_1 = sqlString.UTF8String;
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK) {
                    sqlite3_bind_text(selstmt, 1, [salesID UTF8String], -1, SQLITE_TRANSIENT);
                    
                    while (sqlite3_step(selstmt) == SQLITE_ROW) {
                        NSString *itemID = @"null";
                        NSString *qty = @"null";
                        NSString *lineAmount = @"null";
                        NSString *storeID = @"null";
                        NSString *isBadProduct;
                        
                        if (sqlite3_column_text(selstmt, 0))
                            itemID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                        
                        if (sqlite3_column_text(selstmt, 1))
                            qty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 1)];
                        
                        if (sqlite3_column_text(selstmt, 2))
                            lineAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 2)];
                        
                        if (sqlite3_column_text(selstmt, 3))
                            storeID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 3)];
                        
                        if (sqlite3_column_text(selstmt, 4))
                            isBadProduct = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 4)];
                        
                        [xmlWriter writeStartElement:@"sam:SalesLines"];
                        
                        if ([isBadProduct isEqual:@"Y"]) {
                            NSArray *itemIDComponents = [itemID componentsSeparatedByString:@"/"];
                            itemID = itemIDComponents.firstObject;
                        }
                        [xmlWriter writeStartElement:@"sam:ItemID"];
                        [xmlWriter writeCharacters:itemID];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:Qty"];
                        [xmlWriter writeCharacters:qty];
                        [xmlWriter writeEndElement];
                        
                        NSString *price = [NSString stringWithFormat:@"%0.2lf", lineAmount.doubleValue / qty.doubleValue];
                        [xmlWriter writeStartElement:@"sam:Price"];
                        [xmlWriter writeCharacters:price];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:LineAmount"];
                        [xmlWriter writeCharacters:lineAmount];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:StoreID"];
                        [xmlWriter writeCharacters:storeID];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeEndElement];
                        
                        itemID = nil;
                        qty = nil;
                        lineAmount = nil;
                        storeID = nil;
                        isBadProduct = nil;
                    }
                }
                sqlite3_finalize(selstmt);
                
                [xmlWriter writeEndElement];
                
                salesDate = nil;
                storeID = nil;
                custAcc = nil;
                contractId = nil;
                amountSum = nil;
                channelTypeId = nil;
                salesStatus = nil;
                comment = nil;
                uuid = nil;
                dlvDate = nil;
                crTime = nil;
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];
    
    setSalesToServer = [PutOrdersNewRequest new];
    [setSalesToServer sendSales:xml];
    setSalesToServer.isConsult = self.isConsult;
    setSalesToServer.salesId = salesID;
}

- (void)updateSalesTable:(NSString *)salesId sendTime:(NSString*)sendTime {
    NSString *sqlString = [NSString stringWithFormat:@"update %@ Set SendTime = ? where SalesId = ?", self.salesTable];
    const char *sql_2 = sqlString.UTF8String;
    
    sqlite3_stmt *updateStmt;
    
    if (sqlite3_prepare_v2(database, sql_2, -1, &updateStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(updateStmt, 1, [sendTime UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //section text as a label
    UIView *sectionHead = [[UIView alloc] initWithFrame:CGRectMake(0, 20, CGRectGetWidth(tableView.frame), 40.f)];
    [sectionHead setBackgroundColor:[UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1]];
    
    UIView *sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,CGRectGetWidth(tableView.frame),2.f)];
    [sectionHeadView setBackgroundColor:[UIColor colorWithRed:63.0/255.0 green:64.0/255.0 blue:65.0/255.0 alpha:1]];
    
    UIView *top_sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
    [top_sectionHeadView setBackgroundColor:[UIColor blackColor]];
    [sectionHeadView addSubview:top_sectionHeadView];
    
    UIView *bot_sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0,1,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
    [bot_sectionHeadView setBackgroundColor:[UIColor blackColor]];
    [sectionHeadView addSubview:bot_sectionHeadView];
    
    UIView *light_sectionHeadView = [[UIView alloc] initWithFrame:CGRectMake(0,1.5f,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
    [light_sectionHeadView setBackgroundColor:[UIColor colorWithRed:109.0/255.0 green:112.0/255.0 blue:120.0/255.0 alpha:1]];
    [sectionHeadView addSubview:light_sectionHeadView];
    
    [sectionHead addSubview:sectionHeadView];
    
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0,40.f - 1.f/UIScreen.mainScreen.scale,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
    [bottomLine setBackgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground]];
    [sectionHead addSubview:bottomLine];
    
    CGFloat height = 40.f;
    UILabel *label = [[UILabel	alloc] initWithFrame:CGRectMake(5.0, 0, 90.0, height)];
    label.tag = LABEL_TAG;
    UIFont *font = [UIFont boldSystemFontOfSize:16.0];
    UIColor *fontColor = [ASPFunctions colorFromHex:@"f1f1f1"];
    UIColor *bgColor = UIColor.clearColor;
    
    label.font = font;
    label.text = @"№";
    label.textAlignment = NSTextAlignmentCenter;
    
    label.textColor = fontColor;
    label.backgroundColor = bgColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer = label.layer;
    cellLayer.borderColor = [bgColor CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(105.0, 0, 170.0, height)];
    label.tag = LABEL_TAG;
    label.font = font;
    label.text = @"Клиент";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.backgroundColor = bgColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer1 = label.layer;
    cellLayer1.borderColor = [bgColor CGColor];
    cellLayer1.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(285.0, 0, 80.0, height)];
    label.tag = LABEL_TAG;
    label.font = font;
    label.text = @"Дата заказа";
    label.textAlignment = NSTextAlignmentCenter;
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
    [label setNumberOfLines:2];
    label.textColor = fontColor;
    label.backgroundColor = bgColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer3 = label.layer;
    cellLayer3.borderColor = [bgColor CGColor];
    cellLayer3.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(370.0, 0, 80.0, height)];
    label.tag = LABEL_TAG;
    label.font = font;
    label.text = @"Дата решения";
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
    [label setNumberOfLines:2];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.backgroundColor = bgColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(455.0, 0, 85.0, height)];
    label.tag = LABEL_TAG;
    label.font = font;
    label.text = @"Источник";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.backgroundColor = bgColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer5 = label.layer;
    cellLayer5.borderColor = [bgColor CGColor];
    cellLayer5.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(545.0, 0, 85.0, height)];
    label.tag = LABEL_TAG;
    label.font = font;
    label.text = @"Сумма";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.backgroundColor = bgColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer6 = label.layer;
    cellLayer6.borderColor = [bgColor CGColor];
    cellLayer6.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(625.0, 0.0, tableView.frame.size.width - 630.0, height)];
    label.tag = LABEL_TAG;
    label.font = font;
    label.text = @"Статус";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = fontColor;
    label.backgroundColor = bgColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer7 = label.layer;
    cellLayer7.borderColor = [bgColor CGColor];
    cellLayer7.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    return sectionHead;
}

- (void)showCust:(id)sender {
    if (self.presentedViewController) { return; }
        
    CustFilter *custFilter = [CustFilter new];
    custFilter.delegate = self;
    custFilter.isToday = self.isToday;
    custFilter.isPending = self.isPending;
    custFilter.isConsult = self.isConsult;
    
    custFilter.modalPresentationStyle = UIModalPresentationPopover;
    custFilter.popoverPresentationController.barButtonItem = custBtn;
    
    [self presentViewController:custFilter animated:YES completion:nil];
}

- (void)selectCust:(NSString *)cust {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    fcust = cust;
    
    [self selectWithFilters];
    
    labelSalesTotal.text = [self totalSalesSum];
    
    [self setBarButton:custBtn highlighted:fcust!=nil];
}

- (void)showDate:(id)sender {
    if (self.presentedViewController) { return; }
    
    DateFilter *dateFilter = [DateFilter new];
    dateFilter.delegate = self;
    dateFilter.isToday = self.isToday;
    dateFilter.isPending = self.isPending;
    dateFilter.isConsult = self.isConsult;
    
    dateFilter.modalPresentationStyle = UIModalPresentationPopover;
    dateFilter.popoverPresentationController.barButtonItem = dateBtn;
    
    [self presentViewController:dateFilter animated:YES completion:nil];
}

- (void)selectDate:(NSString *)dateStr {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    fdate = dateStr;
    
    [self selectWithFilters];
    
    labelSalesTotal.text = [self totalSalesSum];
    
    [self setBarButton:dateBtn highlighted:fdate!=nil];
}

- (void)showChannel:(id)sender {
    if (self.presentedViewController) { return; }
    
    ChannelFilter *channelFilter = [ChannelFilter new];
    channelFilter.delegate = self;
    channelFilter.isToday = self.isToday;
    channelFilter.isPending = self.isPending;
    
    channelFilter.modalPresentationStyle = UIModalPresentationPopover;
    channelFilter.popoverPresentationController.barButtonItem = channelBtn;
    
    [self presentViewController:channelFilter animated:YES completion:nil];
}

- (void)selectChannel:(NSString *)channel {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    fchannel = channel;
    
    [self selectWithFilters];
    
    //if (isToday)
    labelSalesTotal.text = [self totalSalesSum];
    
    [self setBarButton:channelBtn highlighted:fchannel!=nil];
}

- (void)showStatus:(id)sender {
    if (self.presentedViewController) { return; }
    
    StatusFilter *statusFilter = [StatusFilter new];
    statusFilter.delegate = self;
    statusFilter.isToday = self.isToday;
    statusFilter.isPending = self.isPending;
    
    statusFilter.modalPresentationStyle = UIModalPresentationPopover;
    statusFilter.popoverPresentationController.barButtonItem = statusBtn;
    
    [self presentViewController:statusFilter animated:YES completion:nil];
}

- (void)selectStatus:(NSString *)status {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    fstatus = status;
    
    [self selectWithFilters];
    
    //if (isToday)
    labelSalesTotal.text = [self totalSalesSum];
    
    [self setBarButton:statusBtn highlighted:fstatus!=nil];
}

- (void)clearFilter {
    fcust = nil;
    fdate = nil;
    fchannel = nil;
    fstatus = nil;
    
    [self setBarButton:custBtn highlighted:NO];
    [self setBarButton:dateBtn highlighted:NO];
    [self setBarButton:channelBtn highlighted:NO];
    [self setBarButton:statusBtn highlighted:NO];
    
    
    [self selectWithFilters];
    
    //if (isToday)
    labelSalesTotal.text = [self totalSalesSum];
}

- (void)finalizeStatements {
    if (database)
        sqlite3_close(database);
}

// Andrey +
- (BOOL)isSalesLineExist:(NSString *)salesId {
    BOOL isSales = false;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select ItemId, Qty, Price, LineAmount from %@ where SalesId = ?", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                isSales = YES;
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
        
    } else {
        sqlite3_close(database);
    }
    return isSales;
}

#pragma mark - Networking
- (void)requestDocument:(DocumentType *)docType salesID:(NSString *)salesID {
    NSString *salesUUID = [self getSalesUUID:salesID];
    
    SalesPdfRequest *pdfRequest = [SalesPdfRequest new];
    [pdfRequest requestDocument:docType salesUUID:salesUUID completion:^(NSData * _Nonnull pdfData, NSString * _Nullable errorString) {
        if (errorString) {
            [AlertWorkerObjc alertWithTitle:errorString];
        } else {
            ASPPDFReaderViewController *pdfReaderVC = [[ASPPDFReaderViewController alloc] initWithPdfData:pdfData];
            [self.navigationController presentViewController:pdfReaderVC animated:YES completion:nil];
        }
    }];
}

#pragma mark - Button styling methods
- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}

#pragma mark - ConstData
- (NSArray *)documentTypes {
    return @[
        [[DocumentType alloc] initWithName:@"ТОРГ-12" docID:1],
        [[DocumentType alloc] initWithName:@"Счёт" docID:2],
        [[DocumentType alloc] initWithName:@"Товарный чек" docID:3]
    ];
}

- (NSArray *)documentTypeNames {
    NSMutableArray *names = [NSMutableArray array];
    for (DocumentType *doc in [self documentTypes]) {
        [names addObject:doc.name];
    }
    return names.copy;
}

@end
