//
//  CustDream.m
//  MLK
//
//  Created by Rustem Galyamov on 06.12.13.
//
//

#import "CustDream.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kCellHeight = 44.0;

@implementation CustDream

static sqlite3 *database = nil;

@synthesize dreamList;
@synthesize delegate;
@synthesize visitPlan;
@synthesize addCust;
@synthesize fromTask, fromCustTask, custAcccount, setBtn, dreamSelected, selected;

- (void)dreamListCreate {
    dreamList           = [NSMutableArray new];
	dreamToLiveInArray  = [NSMutableArray array];
    
    if (!dreamSelected)
        dreamSelected       = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (visitPlan)
            sql = "select StatusDN from CustStatusDN where (StatusDN = '1' or StatusDN = '2') and exists(select * from CustTable where CustTable.CustAccount == CustStatusDN.CustAccount) group by StatusDN";
        else if (addCust)
            sql = "select StatusDN from CustStatusDN where StatusDN != '' and exists(select * from CustTable where CustTable.CustAccount == CustStatusDN.CustAccount and CustTable.AdditionalCust = '1') group by StatusDN";
        else
            sql = "select StatusDN from CustStatusDN where StatusDN != '' and exists(select * from CustTable where CustTable.CustAccount == CustStatusDN.CustAccount) group by StatusDN";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            //[dreamToLiveInArray addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				
                NSString *dr = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    dr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                [dreamToLiveInArray addObject:dr];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    //[dreamToLiveInArray addObject:@"Без статуса"];
    
    NSDictionary *dreamToLiveInDict = [NSDictionary dictionaryWithObject:dreamToLiveInArray forKey:@"Dream"];
    
    [dreamList addObject:dreamToLiveInDict];
}

- (void)taskStatusListCreate {
    dreamList           = [NSMutableArray new];
    dreamToLiveInArray  = [NSMutableArray array];
    
    if (!dreamSelected)
        dreamSelected       = [NSMutableArray new];
	
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (fromCustTask)
            sql = "select Status from TaskTable where CustAccount = ? group by Status";
        else
            sql = "select Status from TaskTable group by Status";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            if (fromCustTask)
                sqlite3_bind_text(selectstmt, 1, [custAcccount UTF8String], -1, SQLITE_TRANSIENT);
            
            //[dreamToLiveInArray addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				
                NSString *dr = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    dr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                [dreamToLiveInArray addObject:dr];
            }
            
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    //[dreamToLiveInArray addObject:@"Без статуса"];
    
    NSDictionary *dreamToLiveInDict = [NSDictionary dictionaryWithObject:dreamToLiveInArray forKey:@"Dream"];
    
    [dreamList addObject:dreamToLiveInDict];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
    self.tableView.frame = CGRectMake(0.0, 0.0, 250.0, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = CGSizeMake(self.tableView.contentSize.width, ([dreamList[0][@"Dream"] count] + 1) * kCellHeight);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (fromTask)
        [self taskStatusListCreate];
    else
        [self dreamListCreate];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 250, 44)];
    
    NSMutableArray* btns = [[NSMutableArray alloc] initWithCapacity:3];

    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,80,44)];
    [clearButton setTitle:@"Очистить" forState:UIControlStateNormal];
    [clearButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.f]];
    [clearButton setTitleColor:[UIColor colorNamed:ACColorNameMLKBlue] forState:UIControlStateNormal];
    [clearButton addTarget:self
                    action:@selector(removeFilter:)
          forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *custkey = [[UIBarButtonItem alloc] initWithCustomView:clearButton];
    [btns addObject:custkey];

    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];

    [fixed setWidth:45.0f];
    [btns addObject:fixed];

    UIButton *applyButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,100,44)];
    [applyButton setTitle:@"Применить" forState:UIControlStateNormal];
    [applyButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.f]];
    [applyButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [applyButton addTarget:self
                    action:@selector(useFilter:)
          forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *sourcekey = [[UIBarButtonItem alloc] initWithCustomView:applyButton];

    setBtn = sourcekey;

    [btns addObject:sourcekey];
    
    [sectionHead setItems:btns animated:NO];

    sectionHead.tintColor = [UIColor blackColor];
    [self enableApplyButton:[dreamSelected count] > 0];
    return sectionHead;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kCellHeight;
}

- (void)removeFilter:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidSelectDream:)]) {
        [self.delegate userDidSelectDream:nil];
    }
}

- (void)useFilter:(id)sender {
    if (dreamSelected.count != 0) {
        if ([self.delegate respondsToSelector:@selector(userDidSelectDream:)]) {
            [self.delegate userDidSelectDream:dreamSelected];
        }
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [dreamList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [dreamList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"Dream"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
	
    NSDictionary	*dictionary = [dreamList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Dream"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    if (fromTask) {
        cell.textLabel.text = cellValue;
    } else {
        if ([cellValue isEqualToString:@"0"])
            cell.textLabel.text = @"Не рабочий";
        else if ([cellValue isEqualToString:@"1"])
            cell.textLabel.text = @"Рабочий";
        else if ([cellValue isEqualToString:@"2"])
            cell.textLabel.text = @"Dream";
        else if ([cellValue isEqualToString:@"3"])
            cell.textLabel.text = @"Новый";
        else if ([cellValue isEqualToString:@"4"])
            cell.textLabel.text = @"Временный";
        else if ([cellValue isEqualToString:@"5"])
            cell.textLabel.text = @"Без статуса";
    }
    
    if ([selected containsObject:cellValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [dreamSelected addObject:cellValue];
    } else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([dreamSelected containsObject:cellValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.textColor = [UIColor blackColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //if (indexPath.row == 0)
    //    cell.backgroundColor = UIColor.lightGrayColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	/*
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *dream;
    
    NSDictionary *dictionary  = [dreamList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"Dream"];
    
    dream				      = [array objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0)
        [self.delegate selectDream:nil];
    else
        [self.delegate selectDream:dream];
    */
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [dreamList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"Dream"];
    NSString     *dream	  = [array objectAtIndex:indexPath.row];
    
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (currentCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        currentCell.accessoryType = UITableViewCellAccessoryNone;
        [dreamSelected removeObject:dream];
    } else {
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [dreamSelected addObject:dream];
    }

    [self enableApplyButton:[dreamSelected count] > 0];
}

- (void)enableApplyButton:(BOOL)state {
    UIButton *customViewButton = ((UIBarButtonItem *) setBtn).customView;
    if (state) {
        [customViewButton setTitleColor:[UIColor colorNamed:ACColorNameMLKBlue] forState:UIControlStateNormal];
        [setBtn setEnabled:YES];
    } else {
        [customViewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [setBtn setEnabled:FALSE];
    }
}

+ (void)finalizeStatements {
	if (database)
		sqlite3_close(database);
}


@end
