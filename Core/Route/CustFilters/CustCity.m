//
//  CustCity.m
//  MLK
//
//  Created by Rustem Galyamov on 02.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "CustCity.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

@implementation CustCity

static sqlite3 *database = nil;

@synthesize cityList;
@synthesize delegate;
@synthesize visitPlan;
@synthesize addCust, selected;
@synthesize fromTask, custAcccount, setBtn, citySelected;

- (void)cityListCreate {
    cityList           = [NSMutableArray new];
	cityToLiveInArray  = [NSMutableArray array];
    if (!citySelected)
        citySelected       = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (visitPlan)
            sql = "select City from CustTable where City != '' and exists(select * from CustStatusDN where CustTable.CustAccount == CustStatusDN.CustAccount and (StatusDN = '1' or StatusDN = '2')) group by City";
        else if (addCust)
            sql = "select City from CustTable where City != '' and AdditionalCust = '1' group by City";
        else
            sql = "select City from CustTable where City != '' group by City";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            //[cityToLiveInArray addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				
                NSString *city = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    city  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                [cityToLiveInArray addObject:city];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *cityToLiveInDict = [NSDictionary dictionaryWithObject:cityToLiveInArray forKey:@"City"];
    
    [cityList addObject:cityToLiveInDict];
}

- (void)taskCityListCreate {
    cityList           = [NSMutableArray new];
	cityToLiveInArray  = [NSMutableArray array];
    if (!citySelected)
        citySelected       = [NSMutableArray new];
	
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        sql = "select City from CustTable where City != '' and exists(select * from TaskTable where CustTable.CustAccount == TaskTable.CustAccount) group by City";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt, 1, [custAcccount UTF8String], -1, SQLITE_TRANSIENT);
            
            //[cityToLiveInArray addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				
                NSString *dr = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    dr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                [cityToLiveInArray addObject:dr];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *cityToLiveInDict = [NSDictionary dictionaryWithObject:cityToLiveInArray forKey:@"City"];
    
    [cityList addObject:cityToLiveInDict];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.frame = CGRectMake(0.0, 0.0, 250.0, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (fromTask)
        [self taskCityListCreate];
    else
        [self cityListCreate];
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
    [self enableApplyButton:[citySelected count] > 0];
    return sectionHead;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}


- (void)removeFilter:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidSelectCities:)]) {
        [self.delegate userDidSelectCities:nil];
    }
}

- (void)useFilter:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidSelectCities:)]) {
        [self.delegate userDidSelectCities:citySelected];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [cityList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [cityList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"City"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
	
    NSDictionary	*dictionary = [cityList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"City"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    
    
    cell.textLabel.textColor = [UIColor blackColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    if ([selected containsObject:cellValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [citySelected addObject:cellValue];
    } else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([citySelected containsObject:cellValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    /*if (indexPath.row == 0)
        cell.backgroundColor = UIColor.lightGrayColor;*/
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [cityList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"City"];
    NSString     *source	  = [array objectAtIndex:indexPath.row];
    
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (currentCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        currentCell.accessoryType = UITableViewCellAccessoryNone;
        [citySelected removeObject:source];
    } else {
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [citySelected addObject:source];
    }

    [self enableApplyButton:[citySelected count] > 0];
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
