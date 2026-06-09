//
//  SalesInvoiceGrid.m
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "InvoiceGrid.h"
#import "MyTableCell.h"

static sqlite3 *database = nil;

@implementation InvoiceGrid

@synthesize delegate;
@synthesize dateList, custList, numList, contractList, actionList, amountList, statusList, channelList;
@synthesize isPreInvoice;
@synthesize custAccount, salesId;

#define LABEL_TAG 1 
#define VALUE_TAG 2 
#define FIRST_CELL_IDENTIFIER @"TrailItemCell" 
#define SECOND_CELL_IDENTIFIER @"RegularCell" 


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (isPreInvoice) {
        self.navigationItem.title = @"Предварительный просмотр накладных";
        [self createPreGrid];
        
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStylePlain target:self action:@selector(cancel_Clicked:)];
            
        barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
            
        self.navigationItem.rightBarButtonItem = barButton;
    } else {
        self.navigationItem.title = @"Накладные";
        [self createGrid];
    }
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundView:[[UIView alloc] init]];
}

- (void)cancel_Clicked:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createGrid {
    custList              = [NSMutableArray new];
	custToLiveInArray     = [NSMutableArray array];
    
    actionList           = [NSMutableArray new];
    actionToLiveInArray  = [NSMutableArray array];
    
    dateList              = [NSMutableArray new];
    dateToLiveInArray     = [NSMutableArray array];
    
    amountList            = [NSMutableArray new];
    amountToLiveInArray   = [NSMutableArray array];
    
    numList               = [NSMutableArray new];
    numToLiveInArray      = [NSMutableArray array];
    
    channelList           = [NSMutableArray new];
    channelToLiveInArray  = [NSMutableArray array];
    
    contractList          = [NSMutableArray new];
    contractToLiveInArray = [NSMutableArray array];
    
    statusList            = [NSMutableArray new];
    statusToLiveInArray   = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        sql = "select CustAccount, InvoiceId, InvoiceDate, AmountSum, ChannelTypeId, InvoiceStatus, ContractId, Action from CustInvoiceTable";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *custAcc   = @"null";
                NSString *date      = @"null";
                NSString *num       = @"null";
                NSString *contract  = @"null";
                NSString *action    = @"null";
                NSString *channel   = @"null";
                NSString *amount    = @"null";
                NSString *status    = @"null";
                NSString *custName  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    num  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    date = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    amount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    channel = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    contract = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    action = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                const char *sql_1;
                
                sql_1 = "select Name from CustTable where CustAccount = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(selstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt) == SQLITE_ROW) 
                    {
                        if (sqlite3_column_text(selstmt, 0))
                            custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                    }
                }
                sqlite3_finalize(selstmt);
                
                [custToLiveInArray          addObject:custName];
                [actionToLiveInArray        addObject:action];
                [dateToLiveInArray          addObject:date];
                [amountToLiveInArray        addObject:amount];
                [numToLiveInArray           addObject:num];
                [channelToLiveInArray       addObject:channel];
                [contractToLiveInArray      addObject:contract];
                [statusToLiveInArray        addObject:status];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *custToLiveInDict     = [NSDictionary dictionaryWithObject:custToLiveInArray forKey:@"Cust"];
    NSDictionary *actionToLiveInDict   = [NSDictionary dictionaryWithObject:actionToLiveInArray forKey:@"Action"];
    NSDictionary *dateToLiveInDict     = [NSDictionary dictionaryWithObject:dateToLiveInArray forKey:@"Date"];
    NSDictionary *amountToLiveInDict   = [NSDictionary dictionaryWithObject:amountToLiveInArray forKey:@"Amount"];
    NSDictionary *numToLiveInDict      = [NSDictionary dictionaryWithObject:numToLiveInArray forKey:@"Num"];
    NSDictionary *channelToLiveInDict  = [NSDictionary dictionaryWithObject:channelToLiveInArray forKey:@"Channel"];
    NSDictionary *contractToLiveInDict = [NSDictionary dictionaryWithObject:contractToLiveInArray forKey:@"Contract"];
    NSDictionary *statusToLiveInDict   = [NSDictionary dictionaryWithObject:statusToLiveInArray forKey:@"Status"];
    
    [custList     addObject:custToLiveInDict];
    [actionList   addObject:actionToLiveInDict];
    [dateList     addObject:dateToLiveInDict];
    [amountList   addObject:amountToLiveInDict];
    [numList      addObject:numToLiveInDict];
    [channelList  addObject:channelToLiveInDict];
    [contractList addObject:contractToLiveInDict];
    [statusList   addObject:statusToLiveInDict];
}

- (void)createPreGrid {
    custList              = [NSMutableArray new];
	custToLiveInArray     = [NSMutableArray array];
    
    actionList           = [NSMutableArray new];
    actionToLiveInArray  = [NSMutableArray array];
    
    dateList              = [NSMutableArray new];
    dateToLiveInArray     = [NSMutableArray array];
    
    amountList            = [NSMutableArray new];
    amountToLiveInArray   = [NSMutableArray array];
    
    numList               = [NSMutableArray new];
    numToLiveInArray      = [NSMutableArray array];
    
    channelList           = [NSMutableArray new];
    channelToLiveInArray  = [NSMutableArray array];
    
    contractList          = [NSMutableArray new];
    contractToLiveInArray = [NSMutableArray array];
    
    statusList            = [NSMutableArray new];
    statusToLiveInArray   = [NSMutableArray array];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (salesId == nil)
            sql = "select ItemId, Qty, LineAmount, ContractId, BrandId from tmpSalesLine where CustAccount = ? group by ContractId";
        else
            sql = "select AmountSum, ContractId from SalesTable where SalesId = ? group by ContractId";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            if (salesId == nil)
                sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(selectstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
                NSString *num       = @"null";
                NSString *contract  = @"null";
                NSString *action    = @"null";
                NSString *channel   = @"null";
                NSString *amount    = @"null";
                NSString *status    = @"null";
                NSString *custName  = @"null";
                NSString *sumAmount = @"null";
                
                if (sqlite3_column_text(selectstmt, 3))
                    contract = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                const char *sql_1;
                
                sql_1 = "select Name from CustTable where CustAccount = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(selstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt) == SQLITE_ROW) 
                    {
                        if (sqlite3_column_text(selstmt, 0))
                            custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                    }
                }
                sqlite3_finalize(selstmt);
                
                const char *sql_2;
                
                double totalSum = 0.0;

                if (salesId == nil)
                    sql_2 = "select LineAmount from tmpSalesLine where CustAccount = ? and ContractId = ?";
                else
                    sql_2 = "select LineAmount from SalesLine where SalesId = ?";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) 
                {
                    if (salesId == nil)
                    {
                        sqlite3_bind_text(selstmt_2, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(selstmt_2, 2, [contract UTF8String], -1, SQLITE_TRANSIENT);
                    }
                    else
                        sqlite3_bind_text(selstmt_2, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
                    
                    while (sqlite3_step(selstmt_2) == SQLITE_ROW) {
                        if (sqlite3_column_text(selstmt_2, 0))
                            amount   = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                        
                        totalSum += [amount doubleValue];
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                sumAmount = [NSString stringWithFormat:@"%1.2f", totalSum];
                
                [custToLiveInArray          addObject:custName];
                [actionToLiveInArray        addObject:action];
                [dateToLiveInArray          addObject:strDate];
                [amountToLiveInArray        addObject:sumAmount];
                [numToLiveInArray           addObject:num];
                [channelToLiveInArray       addObject:channel];
                [contractToLiveInArray      addObject:contract];
                [statusToLiveInArray        addObject:status];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *custToLiveInDict     = [NSDictionary dictionaryWithObject:custToLiveInArray forKey:@"Cust"];
    NSDictionary *actionToLiveInDict   = [NSDictionary dictionaryWithObject:actionToLiveInArray forKey:@"Action"];
    NSDictionary *dateToLiveInDict     = [NSDictionary dictionaryWithObject:dateToLiveInArray forKey:@"Date"];
    NSDictionary *amountToLiveInDict   = [NSDictionary dictionaryWithObject:amountToLiveInArray forKey:@"Amount"];
    NSDictionary *numToLiveInDict      = [NSDictionary dictionaryWithObject:numToLiveInArray forKey:@"Num"];
    NSDictionary *channelToLiveInDict  = [NSDictionary dictionaryWithObject:channelToLiveInArray forKey:@"Channel"];
    NSDictionary *contractToLiveInDict = [NSDictionary dictionaryWithObject:contractToLiveInArray forKey:@"Contract"];
    NSDictionary *statusToLiveInDict   = [NSDictionary dictionaryWithObject:statusToLiveInArray forKey:@"Status"];
    
    [custList     addObject:custToLiveInDict];
    [actionList   addObject:actionToLiveInDict];
    [dateList     addObject:dateToLiveInDict];
    [amountList   addObject:amountToLiveInDict];
    [numList      addObject:numToLiveInDict];
    [channelList  addObject:channelToLiveInDict];
    [contractList addObject:contractToLiveInDict];
    [statusList   addObject:statusToLiveInDict];
}


- (void)refreshData{

    if (isPreInvoice)
        [self createPreGrid];
    else
        [self createGrid];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [custList count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
    NSDictionary *dictionary = [custList objectAtIndex:section];
    NSArray		 *array = [dictionary objectForKey:@"Cust"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	CGRect l1_Frame;
    CGRect l2_Frame;
    CGRect l3_Frame;
    CGRect l4_Frame;
    CGRect l5_Frame;
    CGRect l6_Frame;
    CGRect l7_Frame;
    
    if (isPreInvoice) {
        l1_Frame  = CGRectMake(5.0, 0, 60.0,    tableView.rowHeight);
        l2_Frame  = CGRectMake(75.0, 0, 215.0,  tableView.rowHeight);
        l3_Frame  = CGRectMake(300.0, 0, 80.0,  tableView.rowHeight);
        l4_Frame  = CGRectMake(390.0, 0, 80.0,  tableView.rowHeight);
        l5_Frame  = CGRectMake(480.0, 0, 80.0,  tableView.rowHeight);
        l6_Frame  = CGRectMake(570.0, 0, 80.0,  tableView.rowHeight);
        l7_Frame  = CGRectMake(660.0, 0, 105.0, tableView.rowHeight);
    } else {
        l1_Frame  = CGRectMake(5.0, 0, 40.0,    tableView.rowHeight);
        l2_Frame  = CGRectMake(55.0, 0, 170.0,  tableView.rowHeight);
        l3_Frame  = CGRectMake(235.0, 0, 80.0,  tableView.rowHeight);
        l4_Frame  = CGRectMake(325.0, 0, 80.0,  tableView.rowHeight);
        l5_Frame  = CGRectMake(415.0, 0, 80.0,  tableView.rowHeight);
        l6_Frame  = CGRectMake(505.0, 0, 80.0,  tableView.rowHeight);
        l7_Frame  = CGRectMake(591.0, 0, 105.0, tableView.rowHeight);
    }
    
    NSString *MyIdentifier = [NSString stringWithFormat:@"MyIdentifier %li", (long)indexPath.row];
    MyTableCell *cell = (MyTableCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	
	if (cell == nil) {
		cell = [[MyTableCell alloc] initWithFrame:CGRectZero];
		
        if (isPreInvoice) {
            [cell addColumn:70];
            [cell addColumn:295];
            [cell addColumn:385];
            [cell addColumn:475];
            [cell addColumn:565];
            [cell addColumn:655];
        } else {
            [cell addColumn:50];
            [cell addColumn:230];
            [cell addColumn:320];
            [cell addColumn:410];
            [cell addColumn:500];
            [cell addColumn:590];
        }
    }
    
    UILabel *label;
    
    NSDictionary *numDict  = [numList objectAtIndex:indexPath.section];
    NSArray		 *numArray = [numDict objectForKey:@"Num"];
    NSString     *numValue = [numArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:l1_Frame];
    
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = numValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:label]; 
    
    NSDictionary *custDict  = [custList objectAtIndex:indexPath.section];
    NSArray		 *custArray = [custDict objectForKey:@"Cust"];
    NSString     *custValue = [custArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:l2_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = custValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:label]; 
    
    NSString     *dateContractValue;
    
    if (isPreInvoice) {
        NSDictionary *dict  = [contractList objectAtIndex:indexPath.section];
        NSArray		 *array = [dict objectForKey:@"Contract"];
        dateContractValue   = [array objectAtIndex:indexPath.row];
    } else {
        NSDictionary *dateDict  = [dateList objectAtIndex:indexPath.section];
        NSArray		 *dateArray = [dateDict objectForKey:@"Date"];
        dateContractValue       = [dateArray objectAtIndex:indexPath.row];
    }
    
    label = [[UILabel	alloc] initWithFrame:l3_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = dateContractValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:label];
    
    NSDictionary *actionDict  = [actionList objectAtIndex:indexPath.section];
    NSArray		 *actionArray = [actionDict objectForKey:@"Action"];
    NSString     *actionValue = [actionArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:l4_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = actionValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:label];
    
    NSDictionary *channelDict  = [channelList objectAtIndex:indexPath.section];
    NSArray		 *channelArray = [channelDict objectForKey:@"Channel"];
    NSString     *channelValue = [channelArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:l5_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = channelValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:label];
    
    NSDictionary *amountDict  = [amountList objectAtIndex:indexPath.section];
    NSArray		 *amountArray = [amountDict objectForKey:@"Amount"];
    NSString     *amountValue = [amountArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:l6_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = amountValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:label];
    
    NSDictionary *statusDict  = [statusList objectAtIndex:indexPath.section];
    NSArray		 *statusArray = [statusDict objectForKey:@"Status"];
    NSString     *statusValue = [statusArray objectAtIndex:indexPath.row];
    
    label = [[UILabel	alloc] initWithFrame:l7_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    
    if (isPreInvoice)
        label.text = @"Предпросмотр";
    else
        label.text = statusValue;
    
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:label];
    
    CALayer *cellLayer = cell.layer;
    cellLayer.borderColor = [[UIColor blackColor] CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
    NSDictionary *custDict  = [custList objectAtIndex:indexPath.section];
    NSArray		 *custArray = [custDict objectForKey:@"Cust"];
    NSString     *custValue = [custArray objectAtIndex:indexPath.row];
    
    NSDictionary *numDict  = [numList objectAtIndex:indexPath.section];
    NSArray		 *numArray = [numDict objectForKey:@"Num"];
    NSString     *num      = [numArray objectAtIndex:indexPath.row];
    
    NSDictionary *amountDict  = [amountList objectAtIndex:indexPath.section];
    NSArray		 *amountArray = [amountDict objectForKey:@"Amount"];
    NSString     *amountValue = [amountArray objectAtIndex:indexPath.row];
    */
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect headFrame;
    CGRect l1_Frame;
    CGRect l2_Frame;
    CGRect l3_Frame;
    CGRect l4_Frame;
    CGRect l5_Frame;
    CGRect l6_Frame;
    CGRect l7_Frame;
    
    if (isPreInvoice) {
        headFrame = CGRectMake(0, 0, 768, 20);
        
        l1_Frame  = CGRectMake(0.0, 0, 70.0, 20);
        l2_Frame  = CGRectMake(70.0, 0, 225.0, 20);
        l3_Frame  = CGRectMake(295.0, 0, 90.0, 20);
        l4_Frame  = CGRectMake(385.0, 0, 90.0, 20);
        l5_Frame  = CGRectMake(475.0, 0, 90.0, 20);
        l6_Frame  = CGRectMake(565.0, 0, 90.0, 20);
        l7_Frame  = CGRectMake(655.0, 0, 115.0, 20);
    } else {
        headFrame = CGRectMake(0, 0, 703, 20);
        
        l1_Frame  = CGRectMake(0.0, 0, 50.0, 20);
        l2_Frame  = CGRectMake(50.0, 0, 180.0, 20);
        l3_Frame  = CGRectMake(230.0, 0, 90.0, 20);
        l4_Frame  = CGRectMake(320.0, 0, 90.0, 20);
        l5_Frame  = CGRectMake(410.0, 0, 90.0, 20);
        l6_Frame  = CGRectMake(500.0, 0, 90.0, 20);
        l7_Frame  = CGRectMake(590.0, 0, 115.0, 20);
    }
    //section text as a label
    UIView *sectionHead = [[UIView alloc] initWithFrame:headFrame];
    //[sectionHead setBackgroundColor:[UIColor redColor]];
    
    UILabel *label = [[UILabel	alloc] initWithFrame:l1_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = @"№";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer = label.layer;
    cellLayer.borderColor = [[UIColor blackColor] CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:l2_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = @"Клиент";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer1 = label.layer;
    cellLayer1.borderColor = [[UIColor blackColor] CGColor];
    cellLayer1.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:l3_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    
    if (isPreInvoice)
        label.text = @"Договор";
    else
        label.text = @"Дата";
    
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer3 = label.layer;
    cellLayer3.borderColor = [[UIColor blackColor] CGColor];
    cellLayer3.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:l4_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = @"Акция";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer4 = label.layer;
    cellLayer4.borderColor = [[UIColor blackColor] CGColor];
    cellLayer4.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:l5_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = @"Источник";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer5 = label.layer;
    cellLayer5.borderColor = [[UIColor blackColor] CGColor];
    cellLayer5.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:l6_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = @"Сумма";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer6 = label.layer;
    cellLayer6.borderColor = [[UIColor blackColor] CGColor];
    cellLayer6.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:l7_Frame];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:12.0]; 
    label.text = @"Статус";
    label.textAlignment = NSTextAlignmentCenter; 
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer7 = label.layer;
    cellLayer7.borderColor = [[UIColor blackColor] CGColor];
    cellLayer7.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    return sectionHead;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = UIColor.whiteColor;
    
    CALayer *invoiceTableLayer = cell.layer;
    invoiceTableLayer.borderColor = [[UIColor blackColor] CGColor];
    invoiceTableLayer.borderWidth = 2.0f;
}

- (BOOL)shouldAutorotate {
    return YES;
}

+ (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}


@end
