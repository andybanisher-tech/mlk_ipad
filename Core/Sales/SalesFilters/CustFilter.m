//
//  CustFilter.m
//  MLK
//
//  Created by Rustem Galyamov on 12.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CustFilter.h"

#import "GeneratedAssetSymbols.h"

@interface CustFilter ()
@property (nonatomic, copy) NSString *salesTable;

@end

@implementation CustFilter

static sqlite3 *database = nil;

@synthesize custList, custAccList;
@synthesize delegate;
@synthesize isToday;
@synthesize isPending;

- (void)custListCreate {
    custList              = [NSMutableArray new];
	custToLiveInArray     = [NSMutableArray array];
    
    custAccList           = [NSMutableArray new];
	custAccToLiveInArray  = [NSMutableArray array];
    
    NSString *strDate;
    
    if (isToday) {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;
        
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        strDate = [dateFormatter stringFromDate:date];
    } else if (isPending) {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;

        [dateFormatter setDateFormat:dateFormat_YYYY_MM_dd];
        
        strDate = [dateFormatter stringFromDate:date];
    } else {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;
        
        [dateFormatter setDateFormat:dateFormat_YYYY_MM_dd];
        
        strDate = [dateFormatter stringFromDate:date];
    }
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString;
        
        if (isToday) {
            sqlString = [NSString stringWithFormat:@"select Name, CustAccount from CustTable where exists(select * from %@ where CustTable.CustAccount == %@.CustAccount and %@.SalesDate = ? and (ChannelTypeId = 'ТП телефон' or ChannelTypeId = 'ТП')) group by Name, CustAccount", self.salesTable, self.salesTable, self.salesTable];
        } else if (isPending) {
            sqlString = [NSString stringWithFormat:@"select Name, CustAccount from CustTable where exists(select * from %@ where CustTable.CustAccount == %@.CustAccount and %@.DeliveryDateSort > '%@') group by Name, CustAccount", self.salesTable, self.salesTable, self.salesTable, strDate];
        } else {
            sqlString = [NSString stringWithFormat:@"select Name, CustAccount from CustTable where exists(select * from %@ where CustTable.CustAccount == %@.CustAccount and (DeliveryDateSort < '%@' or DeliveryDateSort = '%@' or DeliveryDateSort is null)) group by Name, CustAccount", self.salesTable, self.salesTable, strDate, strDate];
        }
        
        const char *sql = sqlString.UTF8String;
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (isToday) {
                sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            }
            
            [custAccToLiveInArray addObject:@"clear"];
            [custToLiveInArray addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
				NSString *name        = @"null";
                NSString *custAccount = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    name  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    custAccount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [custToLiveInArray addObject:name];
                [custAccToLiveInArray addObject:custAccount];
            }
		}
        sqlite3_finalize(selectstmt);
	}
    sqlite3_close(database);
    
    NSDictionary *custToLiveInDict    = [NSDictionary dictionaryWithObject:custToLiveInArray forKey:@"Name"];
    NSDictionary *custAccToLiveInDict = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    
    [custList addObject:custToLiveInDict];
    [custAccList addObject:custAccToLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.isConsult) {
        self.salesTable = @"ConsultSalesTable";
    } else {
        self.salesTable = @"SalesTable";
    }
    [self custListCreate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.frame = CGRectMake(0, 0, 350, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [custList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [custList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"Name"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
    NSDictionary	*dictionary = [custList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Name"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	= cellValue;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
    
    if (indexPath.row == 0)
        cell.textLabel.textColor = [UIColor colorNamed:ACColorNameMLKBlue];
    else
        cell.textLabel.textColor = [UIColor blackColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0)
        cell.backgroundColor = UIColor.lightGrayColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [custAccList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"CustAcc"];
    NSString     *cust        = [array objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0)
        [self.delegate selectCust:nil];
    else
        [self.delegate selectCust:cust];
}

+ (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}


@end
