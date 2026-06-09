//
//  CustStatusDN.m
//  mlk
//
//  Created by Nikolya Smolnyakov on 17.10.16.
//
//

#import "CustStatusDN.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

@implementation CustStatusDN

static sqlite3 *database = nil;

@synthesize statusDNList;
@synthesize delegate;
@synthesize visitPlan;
@synthesize addCust;
@synthesize fromTask, fromCustTask, custAcccount, setBtn, statusDNSelected, selected;

- (void)statusDNCreate {
    statusDNList             = [NSMutableArray new];
    statusDNToLiveInArray    = [NSMutableArray array];
    
    if (!statusDNSelected)
        statusDNSelected         = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
//        if (visitPlan)
//            sql = "select StatusDN from CustStatusDN where (StatusDN = '1' or StatusDN = '2') and exists(select * from CustTable where CustTable.CustAccount == CustStatusDN.CustAccount) group by StatusDN";
//        else
//            if (addCust)
//                sql = "select StatusDN from CustStatusDN where StatusDN != '' and exists(select * from CustTable where CustTable.CustAccount == CustStatusDN.CustAccount and CustTable.AdditionalCust = '1') group by StatusDN";
//            else
//                sql = "select StatusDN from CustStatusDN where StatusDN != '' and exists(select * from CustTable where CustTable.CustAccount == CustStatusDN.CustAccount) group by StatusDN";
        
        sql = "select distinct Status from CustStatusDNBrand where Status != '' and exists(select * from CustTable where CustTable.CustAccount == CustStatusDNBrand.CustAccount) group by Status;";
        
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                
                NSString *dr = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    dr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                [statusDNToLiveInArray addObject:dr];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }

    //[statusDNToLiveInArray addObject:@"Без статуса"];
    
    NSDictionary *toLiveInDict     = [NSDictionary dictionaryWithObject:statusDNToLiveInArray forKey:@"StatusDN"];

    
    [statusDNList      addObject:toLiveInDict];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.delegate = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.frame = CGRectMake(0, 0, 260, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)taskStatusListCreate {
    statusDNList           = [NSMutableArray new];
    statusDNToLiveInArray  = [NSMutableArray array];
    
    if (!statusDNSelected)
        statusDNSelected       = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
//        if (fromCustTask)
//            sql = "select Status from TaskTable where CustAccount = ? group by Status";
//        else
//            sql = "select Status from TaskTable group by Status";
        
        sql = "select distinct Status from CustStatusDNBrand where Status != '' group by Status";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (fromCustTask)
                sqlite3_bind_text(selectstmt, 1, [custAcccount UTF8String], -1, SQLITE_TRANSIENT);
            
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                
                NSString *dr = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    dr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                [statusDNToLiveInArray addObject:dr];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    //[statusDNToLiveInArray addObject:@"Без статуса"];
    
    NSDictionary *toLiveInDict = [NSDictionary dictionaryWithObject:statusDNToLiveInArray forKey:@"StatusDN"];
    
    [statusDNList addObject:toLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (fromTask)
        [self taskStatusListCreate];
    else
        [self statusDNCreate];
    
    /*
     
     UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 250, 44)];
     
     NSMutableArray* btns = [[NSMutableArray alloc] initWithCapacity:3];
     
     UIBarButtonItem *custkey = [[[UIBarButtonItem alloc] initWithTitle:@"Очистить" style:UIBarButtonItemStyleDone target:self action:@selector(removeFilter:)] autorelease];
     
     [btns addObject:custkey];
     
     UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
     
     [fixed setWidth:60.0f];
     [btns addObject:fixed];
     
     UIBarButtonItem *sourcekey = [[[UIBarButtonItem alloc] initWithTitle:@"Применить" style:UIBarButtonItemStyleDone target:self action:@selector(useFilter:)] autorelease];
     
     setBtn = sourcekey;
     
     [btns addObject:sourcekey];
     
     [sectionHead setItems:btns animated:NO];
     
     [btns release];
     
     sectionHead.tintColor = [UIColor blackColor];
     
     [self.view addSubview:sectionHead];
     [sectionHead release];
     
     [setBtn setEnabled:NO];*/
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
    [self enableApplyButton:[statusDNSelected count] > 0];
    return sectionHead;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (void)removeFilter:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidSelectStatusDN:)]) {
        [self.delegate userDidSelectStatusDN:nil];
    }
}

- (void)useFilter:(id)sender {
    if (statusDNSelected.count != 0) {
        if ([self.delegate respondsToSelector:@selector(userDidSelectStatusDN:)]) {
            [self.delegate userDidSelectStatusDN:statusDNSelected];
        }
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [statusDNList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [statusDNList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"StatusDN"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    
    NSDictionary	*dictionary = [statusDNList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"StatusDN"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    if (fromTask) {
        cell.textLabel.text = cellValue;
    } else {
        cell.textLabel.text = cellValue;
    }
    
    if ([selected containsObject:cellValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [statusDNSelected addObject:cellValue];
    } else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([statusDNSelected containsObject:cellValue]) {
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

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [statusDNList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"StatusDN"];
    NSString     *status	  = [array objectAtIndex:indexPath.row];
    
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (currentCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        currentCell.accessoryType = UITableViewCellAccessoryNone;
        [statusDNSelected removeObject:status];
    } else {
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [statusDNSelected addObject:status];
    }
    
    [self enableApplyButton:[statusDNSelected count] > 0];
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
