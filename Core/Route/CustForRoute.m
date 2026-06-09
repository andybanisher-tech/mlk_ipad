//
//  CustForRoute.m
//  MLK
//
//  Created by Rustem Galyamov on 03.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "CustForRoute.h"

#import "GeneratedAssetSymbols.h"

@implementation CustForRoute

static sqlite3 *database = nil;

@synthesize custList, custAccList;
@synthesize delegate;
@synthesize dateOfMonth;
@synthesize searchBar;
@synthesize i;
@synthesize fcity, fkey, fmark, fday;

- (void)custListCreate {
    custList             = [NSMutableArray new];
	custAccList          = [NSMutableArray new];
	
    NSMutableArray *custToLiveInArray    = [NSMutableArray array];
    NSMutableArray *custAccToLiveInArray = [NSMutableArray array];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select CustAccount, Name, Address, Phone from CustTable where not exists(select * from CustForRoute where CustTable.CustAccount == CustForRoute.CustAccount and DateOfRoute = ?) order by Name";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			if (dateOfMonth)
                sqlite3_bind_text(selectstmt, 1, [dateOfMonth UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				
                NSString *acc   = @"null";
                NSString *name  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    acc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    name  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [custAccToLiveInArray addObject:acc];
                [custToLiveInArray    addObject:name];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *custsToLiveInDict    = [NSDictionary dictionaryWithObject:custToLiveInArray forKey:@"Name"];
    NSDictionary *custsAccToLiveInDict = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    
    [custList    addObject:custsToLiveInDict];
    [custAccList addObject:custsAccToLiveInDict];
    
    copyCustList    = [NSMutableArray new];
    copyCustAccList = [NSMutableArray new];    
}

- (void)selectWithFilters {
    custList             = [NSMutableArray new];
	custAccList          = [NSMutableArray new];
    
    NSMutableArray *custsToLiveInArray   = [NSMutableArray array];
    NSMutableArray *custAccToLiveInArray = [NSMutableArray array];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
        NSString *squl;
        
        if (dateOfMonth) {
            squl = [NSString stringWithFormat:@"select CustAccount, Name, FactAddress from CustTable where not exists(select * from CustForRoute where CustTable.CustAccount == CustForRoute.CustAccount and DateOfRoute = '%@')", dateOfMonth];
        } else {
            squl = [NSString stringWithFormat:@"select CustAccount, Name from CustTable where not exists(select * from CustForRoute where CustTable.CustAccount == CustForRoute.CustAccount and DateOfRoute = '%@')", strDate];
        }
        
        
        if (fkey) {
            squl = [NSString stringWithFormat:@"%@ and exists(select * from CustStatusDN where CustTable.CustAccount == CustStatusDN.CustAccount and %@)", squl, fkey];
        }
        if (fcity) {
            squl = [NSString stringWithFormat:@"%@ and %@", squl, fcity];
        }
        if (fmark) {
            squl = [NSString stringWithFormat:@"%@ and exists(select * from PersonalPriceList where CustTable.CustAccount == PersonalPriceList.CustAccount and PersonalPriceList.Active = '1' and %@)", squl, fmark]; 
        }
        if (fday) {
            squl = [NSString stringWithFormat:@"%@ and LVDateComp > '%@'", squl, fday];
        }
        
        squl = [NSString stringWithFormat:@"%@ order by Name", squl];
        sql = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
		    while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *custAcc   = @"null";
                NSString *custName  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [custsToLiveInArray   addObject:custName];
                [custAccToLiveInArray addObject:custAcc];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *custsToLiveInDict    = [NSDictionary dictionaryWithObject:custsToLiveInArray forKey:@"Name"];
    NSDictionary *custsAccToLiveInDict = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    
    [custList    addObject:custsToLiveInDict];
    [custAccList addObject:custsAccToLiveInDict];
    
    copyCustList    = [NSMutableArray new];
    copyCustAccList = [NSMutableArray new];
}

- (void)city{

    [self selectWithFilters];
}

- (void)key{

    [self selectWithFilters];
}

- (void)brand {

    [self selectWithFilters];
}

- (void)day{

    [self selectWithFilters];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self custListCreate];
    
    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundView:[[UIView alloc] init]];
    
    searching        = NO;
	letUserSelectRow = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self finalizeStatements];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if ([copyCustList count] > 0 && searching)
	{
		return 1;
	}
	else
	{
		return [custList count];
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    if ([copyCustList count] > 0 && searching)
	{
		return [copyCustList count];
	}
	else 
	{
		//Number of rows it should expect should be based on the section
		NSDictionary *dictionary = [custList objectAtIndex:section];
		NSArray		 *array      = [dictionary objectForKey:@"Name"];
		
		return [array count];
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
		UIFont *cellFont = [UIFont systemFontOfSize:18.0];
		UIFont *detailCellFont = [UIFont systemFontOfSize:14.0];
        
        cell.textLabel.font = cellFont;
        cell.detailTextLabel.font = detailCellFont;
    }
	
    if ([copyCustList count] > 0 && searching) {
        NSString *cellValue	= [copyCustList objectAtIndex:indexPath.row];
        cell.textLabel.text = cellValue;
            
        cell.imageView.image = [UIImage imageNamed:ACImageNameCustomers];
    } else {
        NSDictionary	*dictionary = [custList objectAtIndex:0];
        NSArray			*array		= [dictionary objectForKey:@"Name"];
        NSString		*cellValue	= [array objectAtIndex:indexPath.row];
        
        cell.textLabel.text	 	  = cellValue;
        
        cell.imageView.image = [UIImage imageNamed:ACImageNameCustomers];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //UIColor *mycolor= [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:128.0/255.0 alpha:1.0];
}

- (void)addToRoute:(id)sender {
    NSLog(@"%@", sender);
    //[self.delegate addToRoute];
}
- (void)refreshData{

    //[self custListCreate];
    [self selectWithFilters];
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *custAccout;
    NSString *custName;
	
    // Andrey +
//    BOOL start = [self IsStart];
    BOOL stop = [self IsStop];
    if (stop==YES) {
        [AlertWorkerObjc alertWithTitle:@"Маршрут уже закончен"];
    }

    else
    // Andrey -
    if ([copyCustList count] > 0 && searching) {
        custName                 = [copyCustList objectAtIndex:indexPath.row];
        custAccout               = [copyCustAccList objectAtIndex:indexPath.row];
            
        [self.delegate showCustActionSheet:[NSNumber numberWithUnsignedInteger:indexPath.row] title:custAccout custAccount:custAccout custName:custName];
    } else {
        NSDictionary *dictionary  = [custList objectAtIndex:indexPath.section];
        NSArray      *array       = [dictionary objectForKey:@"Name"];
		
        custName				  = [array objectAtIndex:indexPath.row];
        
        NSDictionary *dictCustAcc  = [custAccList objectAtIndex:indexPath.section];
        NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];
        
        custAccout				   = [arrayCustAcc objectAtIndex:indexPath.row];
        
        [self.delegate showCustActionSheet:[NSNumber numberWithUnsignedInteger:indexPath.row] title:custAccout custAccount:custAccout custName:custName];
    }
}


- (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}

#pragma mark -
#pragma mark Search Bar 

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	//This method is called again when the user clicks back from teh detail view.
	//So the overlay is displayed on the results, which is something we do not want to happen.
    if (searching)
		return;
	
	searching = YES;
	letUserSelectRow = NO;
	self.tableView.scrollEnabled = NO;
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
	//Remove all objects first.
	[copyCustList removeAllObjects];
    [copyCustAccList removeAllObjects];
    
    if ([searchText length] > 0) {
		searching = YES;
		letUserSelectRow = YES;
		self.tableView.scrollEnabled = YES;
		[self searchTableView];
	}
	else 
	{
		searching = NO;
		letUserSelectRow = NO;
		self.tableView.scrollEnabled = NO;
	}
	
	[self.delegate reloadCustTable];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
	[self searchTableView];
}

- (void)searchTableView {
    NSString *searchText = searchBar.text;
     
    NSMutableArray *searchArray        = [NSMutableArray new];
    NSMutableArray *searchArrayCustAcc = [NSMutableArray new];
     
    for (NSDictionary *dictionary in custList) {
        NSArray *array = [dictionary objectForKey:@"Name"];
        [searchArray addObjectsFromArray:array];
    }
     
    for (NSDictionary *dictCustAcc in custAccList) {
        NSArray *array = [dictCustAcc objectForKey:@"CustAcc"];
        [searchArrayCustAcc addObjectsFromArray:array];
    }
     
    for (NSString *sTemp in searchArray) {
        i = i + 1;
     
        NSRange titleResultsRange = [sTemp rangeOfString:searchText options:NSCaseInsensitiveSearch];
     
        if (titleResultsRange.length > 0) {
            [copyCustList    addObject:sTemp];
            [copyCustAccList addObject:[searchArrayCustAcc objectAtIndex:i - 1]];
        }
    }
     
    i = 0;

    searchArray = nil;

    searchArrayCustAcc = nil;
}

- (void) doneSearching_Clicked:(id)sender {
	
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	
	letUserSelectRow = YES;
	searching = NO;
	self.navigationItem.rightBarButtonItem = nil;
	self.tableView.scrollEnabled = YES;
	
    [self.delegate reloadCustTable];
}

// Andrey +
-(BOOL)IsStart {
    BOOL isStart = false;
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *routeDate = [dateFormat stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from StartStop where Date = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"START" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                isStart = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return isStart;
}

-(BOOL)IsStop{
    BOOL isStop = false;
    
    NSDate *date = NSDate.date;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *routeDate;
    if (!dateOfMonth) {
        routeDate = [dateFormat stringFromDate:date];
    } else {
        routeDate = dateOfMonth;
    }
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from StartStop where Date = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"STOP" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                isStop = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return isStop;
}

// Andrey -

@end
