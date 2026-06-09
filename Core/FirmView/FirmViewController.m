//
//  FirmViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 21.01.13.
//
//

#import "FirmViewController.h"

@implementation FirmViewController

static sqlite3 *database = nil;

@synthesize firmIdList, firmNameList, firmMarkupList;
@synthesize delegate;

- (void)firmListCreate {
    firmIdList     = [NSMutableArray new];
	firmNameList   = [NSMutableArray new];
    firmMarkupList = [NSMutableArray new];
    
    NSMutableArray  *firmIdToLiveInArray     = [NSMutableArray array];
    NSMutableArray  *firmNameToLiveInArray   = [NSMutableArray array];
    NSMutableArray  *firmMarkupToLiveInArray = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select FirmId, Name, Markup from FirmTable";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *fid    = @"null";
                NSString *name   = @"null";
                NSString *markup = @"0";
                
                if (sqlite3_column_text(selectstmt, 0))
                    fid  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    name  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    markup  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                [firmIdToLiveInArray     addObject:fid];
                [firmNameToLiveInArray   addObject:name];
                [firmMarkupToLiveInArray addObject:markup];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *firmIdToLiveInDict     = [NSDictionary dictionaryWithObject:firmIdToLiveInArray forKey:@"FirmId"];
    NSDictionary *firmNameToLiveInDict   = [NSDictionary dictionaryWithObject:firmNameToLiveInArray forKey:@"Name"];
    NSDictionary *firmMarkupToLiveInDict = [NSDictionary dictionaryWithObject:firmMarkupToLiveInArray forKey:@"Markup"];
    
    [firmIdList     addObject:firmIdToLiveInDict];
    [firmNameList   addObject:firmNameToLiveInDict];
    [firmMarkupList addObject:firmMarkupToLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self firmListCreate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.frame = CGRectMake(0, 0, 400, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [firmIdList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [firmIdList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"FirmId"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
    NSDictionary	*dictionary = [firmNameList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Name"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	= cellValue;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [firmIdList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"FirmId"];
    NSString     *firm        = [array objectAtIndex:indexPath.row];
    
    NSDictionary *dictName    = [firmNameList objectAtIndex:indexPath.section];
    NSArray      *arrayName   = [dictName objectForKey:@"Name"];
    NSString     *firmName    = [arrayName objectAtIndex:indexPath.row];
    
    NSDictionary *dictMarkup    = [firmMarkupList objectAtIndex:indexPath.section];
    NSArray      *arrayMarkup   = [dictMarkup objectForKey:@"Markup"];
    NSString     *firmMarkup    = [arrayMarkup objectAtIndex:indexPath.row];
    
    [self.delegate selectFirm:firm firmName:firmName firmMarkup:firmMarkup];
}

+ (void)finalizeStatements {
	if (database)
		sqlite3_close(database);
}


@end
