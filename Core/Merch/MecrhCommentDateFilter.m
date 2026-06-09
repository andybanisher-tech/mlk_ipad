//
//  MecrhCommentDateFilter.m
//  MLK
//
//  Created by Rustem Galyamov on 25.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "MecrhCommentDateFilter.h"

@implementation MecrhCommentDateFilter

static sqlite3 *database = nil;

@synthesize dateList;
@synthesize delegate;
@synthesize isToday;
@synthesize custAccount;

- (void)dateListCreate {
    dateList              = [NSMutableArray new];
	dateToLiveInArray     = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        sql = "select Date from CustComment where CustAccount = ? and CommentType = ? group by Date";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [@"merch" UTF8String], -1, SQLITE_TRANSIENT);
            
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.frame = CGRectMake(0, 0, 250, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self dateListCreate];
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
        cell.textLabel.textColor = [UIColor blueColor];
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
