//
//  SetTask.m
//  MLK
//
//  Created by garu on 12/11/14.
//
//

#import "SetTask.h"

@implementation SetTask

static sqlite3 *database = nil;

@synthesize setList, setToLiveInArray;
@synthesize delegate;
@synthesize fromCust, custAccount;

- (void)setListCreate {
    setList             = [NSMutableArray new];
	setToLiveInArray    = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (fromCust)
            sql = "select Setted from TaskTable where CustAccount = ? group by Setted";
        else
            sql = "select Setted from TaskTable group by Setted";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            [setToLiveInArray addObject:@"Убрать фильтр"];
            
            if (fromCust)
                sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *setValue = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    setValue  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if ([setValue isEqualToString:@"0"])
                    setValue = @"Своя";
                else
                    setValue = @"Назначенная";
                
                [setToLiveInArray     addObject:setValue];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *setToLiveInDict = [NSDictionary dictionaryWithObject:setToLiveInArray forKey:@"Setted"];
    
    [setList    addObject:setToLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setListCreate];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [setList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [setList objectAtIndex:0];
    NSArray		 *array      = [dictionary objectForKey:@"Setted"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSDictionary	*dictionary = [setList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Setted"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
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
    
    NSDictionary *dictionary  = [setList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"Setted"];
    NSString     *setValue	  = [array objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0)
        [self.delegate selectSetTask:nil];
    else
        [self.delegate selectSetTask:setValue];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.frame = CGRectMake(0, 0, 250, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

+ (void)finalizeStatements {
	if (database)
		sqlite3_close(database);
}


@end
