//
//  DateFilter.m
//  MLK
//
//  Created by Rustem Galyamov on 14.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DateFilter.h"

#import "GeneratedAssetSymbols.h"

@interface DateFilter ()
@property (nonatomic, copy) NSString *salesTable;

@end

@implementation DateFilter

static sqlite3 *database = nil;

@synthesize dateList;
@synthesize delegate;
@synthesize isToday;
@synthesize isPending;

- (void)dateListCreate {
    dateList              = [NSMutableArray new];
	dateToLiveInArray     = [NSMutableArray array];
    
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
            sqlString = [NSString stringWithFormat:@"select SalesDate from %@ where SalesDate = ? and (ChannelTypeId = 'ТП телефон' or ChannelTypeId = 'ТП') group by SalesDate", self.salesTable];
        } else if (isPending) {
            sqlString = [NSString stringWithFormat:@"select SalesDate, SalesDateSort from %@ where DeliveryDateSort > '%@' group by SalesDateSort, SalesDate order by SalesDateSort desc", self.salesTable, strDate];
        } else {
            sqlString = [NSString stringWithFormat:@"select SalesDate, SalesDateSort from %@ where (DeliveryDateSort < '%@' or DeliveryDateSort = '%@' or DeliveryDateSort is null) group by SalesDateSort, SalesDate order by SalesDateSort desc", self.salesTable, strDate, strDate];
        }
        
        const char *sql = sqlString.UTF8String;
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            if (isToday)
                sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            [dateToLiveInArray addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *date        = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                
                [dateToLiveInArray addObject:date];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *dateToLiveInDict    = [NSDictionary dictionaryWithObject:dateToLiveInArray forKey:@"Date"];
    
    [dateList addObject:dateToLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isConsult) {
        self.salesTable = @"ConsultSalesTable";
    } else {
        self.salesTable = @"SalesTable";
    }
    [self dateListCreate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.frame = CGRectMake(0, 0, 150, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [dateList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [dateList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"Date"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
    NSDictionary	*dictionary = [dateList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Date"];
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
    
    NSDictionary *dictionary  = [dateList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"Date"];
    NSString     *date        = [array objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0)
        [self.delegate selectDate:nil];
    else
        [self.delegate selectDate:date];
}


+ (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}


@end
