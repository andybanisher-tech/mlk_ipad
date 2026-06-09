//
//  TaskForCustView.m
//  MLK
//
//  Created by garu on 12/12/14.
//
//

#import "TaskForCustView.h"

@implementation TaskForCustView

static sqlite3 *database = nil;

@synthesize taskList, taskNameList;
@synthesize delegate;
@synthesize custAccount;

- (void)taskListCreate {
    taskList             = [NSMutableArray new];
	taskToLiveInArray    = [NSMutableArray array];
    
    taskNameList           = [NSMutableArray new];
	taskNameToLiveInArray  = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select TaskId, TaskName from TaskTable where Setted = 1 or (From1C = 0 and Source = 'iPad') group by TaskId, TaskName ";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *tId     = @"null";
                NSString *tName   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    tId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    tName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (![self customerOnTask:tId])
                {
                    [taskToLiveInArray    addObject:tId];
                    [taskNameToLiveInArray   addObject:tName];
                }
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *taskToLiveInDict     = [NSDictionary dictionaryWithObject:taskToLiveInArray forKey:@"TaskId"];
    NSDictionary *taskNameToLiveInDict = [NSDictionary dictionaryWithObject:taskNameToLiveInArray forKey:@"TaskName"];
    
    [taskList      addObject:taskToLiveInDict];
    [taskNameList  addObject:taskNameToLiveInDict];
}

-(BOOL)customerOnTask:(NSString *)taskNum{
    BOOL exists = NO;
    
    const char *sql = "select TaskId from TaskTable where TaskId = ? and CustAccount = ?";
    
    sqlite3_stmt *selectstmt;
    
    if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [taskNum UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectstmt) == SQLITE_ROW) {
            exists = YES;
        }
    }
    sqlite3_finalize(selectstmt);
    
    return exists;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.tableView.frame = CGRectMake(0, 0, 250, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self taskListCreate];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [taskList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [taskList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"TaskId"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSDictionary	*dictionary = [taskNameList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"TaskName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [taskList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"TaskId"];
    NSString     *tId	      = [array objectAtIndex:indexPath.row];
    
    NSDictionary *dictName    = [taskNameList objectAtIndex:indexPath.section];
    NSArray      *arrayName   = [dictName objectForKey:@"TaskName"];
    NSString     *tName       = [arrayName objectAtIndex:indexPath.row];
    
    [self.delegate selectTask:tId taskName:tName];
}

+ (void)finalizeStatements {
	if (database)
		sqlite3_close(database);
}


@end
