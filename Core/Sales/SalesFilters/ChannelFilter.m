//
//  ChannelFilter.m
//  MLK
//
//  Created by Rustem Galyamov on 14.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ChannelFilter.h"

#import "GeneratedAssetSymbols.h"

@implementation ChannelFilter

static sqlite3 *database = nil;

@synthesize channelList;
@synthesize delegate;
@synthesize isToday;
@synthesize isPending;

- (void)listCreate {
    channelList              = [NSMutableArray new];
	channelToLiveInArray     = [NSMutableArray array];
    
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
		const char *sql;
        
        if (isToday) {
            sql = "select ChannelTypeId from SalesTable where SalesDate = ? and (ChannelTypeId = 'ТП телефон' or ChannelTypeId = 'ТП') group by ChannelTypeId";
        }
        else if (isPending) {
            sql = [[NSString stringWithFormat:@"select ChannelTypeId from SalesTable where DeliveryDateSort > '%@' group by ChannelTypeId", strDate] UTF8String];
        } else {
            sql = [[NSString stringWithFormat:@"select ChannelTypeId from SalesTable where (DeliveryDateSort < '%@' or DeliveryDateSort = '%@' or DeliveryDateSort is null) group by ChannelTypeId", strDate, strDate] UTF8String];
        }
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            if (isToday)
                sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            [channelToLiveInArray addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *channel        = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    channel  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                
                [channelToLiveInArray addObject:channel];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *channelToLiveInDict    = [NSDictionary dictionaryWithObject:channelToLiveInArray forKey:@"Channel"];
    
    [channelList addObject:channelToLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self listCreate];
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
    return [channelList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [channelList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"Channel"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
    NSDictionary	*dictionary = [channelList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Channel"];
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
    
    NSDictionary *dictionary  = [channelList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"Channel"];
    NSString     *channel     = [array objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0)
        [self.delegate selectChannel:nil];
    else
        [self.delegate selectChannel:channel];
}

+ (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}


@end
