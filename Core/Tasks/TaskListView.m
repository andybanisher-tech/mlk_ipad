//
//  TaskListView.m
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "TaskListView.h"

@implementation TaskListView

static sqlite3 *database = nil;

@synthesize listIdList, listNameList;
@synthesize delegate;
@synthesize taskId;

- (void)listCreate {
    listIdList             = [NSMutableArray new];
	listIdToLiveInArray    = [NSMutableArray array];
    
    listNameList               = [NSMutableArray new];
	listNameToLiveInArray  = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select LineId, LineDescription from TaskList where TaskId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *lineId     = @"null";
                NSString *lineName   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    lineId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    lineName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [listIdToLiveInArray     addObject:lineId];
                [listNameToLiveInArray   addObject:lineName];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *listIdToLiveInDict     = [NSDictionary dictionaryWithObject:listIdToLiveInArray forKey:@"ListId"];
    NSDictionary *listNameToLiveInDict   = [NSDictionary dictionaryWithObject:listNameToLiveInArray forKey:@"ListName"];
    
    [listIdList      addObject:listIdToLiveInDict];
    [listNameList    addObject:listNameToLiveInDict];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.tableView.frame = CGRectMake(0, 0, 250, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self listCreate];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [listIdList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [listIdList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"ListId"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSDictionary	*dictionary = [listNameList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"ListName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [listIdList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"ListId"];
    NSString     *listId	  = [array objectAtIndex:indexPath.row];
    
    NSDictionary *dictName    = [listNameList objectAtIndex:indexPath.section];
    NSArray      *arrayName   = [dictName objectForKey:@"ListName"];
    NSString     *listName    = [arrayName objectAtIndex:indexPath.row];
    
    [self.delegate selectListId:listId listName:listName];
}

+ (void)finalizeStatements {
	if (database)
		sqlite3_close(database);
}


@end
