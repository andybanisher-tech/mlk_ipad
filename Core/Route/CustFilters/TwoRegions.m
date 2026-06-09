//
//  TwoRegions.m
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import "TwoRegions.h"

#import "GeneratedAssetSymbols.h"

@implementation TwoRegions

static sqlite3 *database = nil;

@synthesize regionValueIdList, regionValueNameList;
@synthesize delegate;
@synthesize selected;
@synthesize setBtn, citySelected, cityString;

- (void)regionCreate {
    regionValueIdList             = [NSMutableArray new];
	regionValueIdToLiveInArray    = [NSMutableArray array];
    
    regionValueNameList           = [NSMutableArray new];
	regionValueNameToLiveInArray  = [NSMutableArray array];
    
    if (!citySelected)
        citySelected       = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select PropertyValueID, PropertyValueName from TwoRegion order by PropertyValueName";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				
                NSString *regionId     = @"null";
                NSString *regionName   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    regionId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    regionName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [regionValueIdToLiveInArray     addObject:regionId];
                [regionValueNameToLiveInArray   addObject:regionName];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *regionValueIdToLiveInDict     = [NSDictionary dictionaryWithObject:regionValueIdToLiveInArray forKey:@"RegionValue"];
    NSDictionary *regionValueNameToLiveInDict   = [NSDictionary dictionaryWithObject:regionValueNameToLiveInArray forKey:@"RegionName"];
    
    [regionValueIdList      addObject:regionValueIdToLiveInDict];
    [regionValueNameList    addObject:regionValueNameToLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self regionCreate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    
    self.tableView.frame = CGRectMake(0, 0, 260, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
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
    [self.delegate selectRegions:nil regionName:nil];
}

- (void)useFilter:(id)sender {
    if ([citySelected count] != 0) {
        NSDictionary	*dictionary = [regionValueNameList objectAtIndex:0];
        NSArray			*arrayN		= [dictionary objectForKey:@"RegionName"];
        
        NSDictionary	*dictionaryV = [regionValueIdList objectAtIndex:0];
        NSArray			*arrayV		 = [dictionaryV objectForKey:@"RegionValue"];
        
        for (int i = 0; i < [citySelected count]; i++) {
            NSUInteger j = [arrayV indexOfObject:citySelected[i]];
            if (i == 0)
                cityString = [NSString stringWithFormat:@"%@", arrayN[j]];
            else
                cityString = [NSString stringWithFormat:@"%@,%@", cityString, arrayN[j]];
        }

        [self.delegate selectCityArray:citySelected cityString:cityString];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [regionValueIdList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [regionValueIdList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"RegionValue"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSDictionary	*dictionary = [regionValueNameList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"RegionName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionaryV = [regionValueIdList objectAtIndex:0];
    NSArray			*arrayV		 = [dictionaryV objectForKey:@"RegionValue"];
    NSString		*cellValueV	 = [arrayV objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    cell.textLabel.textColor = [UIColor blackColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    if ([selected containsObject:cellValueV]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [citySelected addObject:cellValueV]; 
    } else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([citySelected containsObject:cellValueV]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [regionValueIdList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"RegionValue"];
    NSString     *regionId	  = [array objectAtIndex:indexPath.row];
    
    NSDictionary *dictName    = [regionValueNameList objectAtIndex:indexPath.section];
    NSArray      *arrayName   = [dictName objectForKey:@"RegionName"];
    NSString     *regionName  = [arrayName objectAtIndex:indexPath.row];
    
    [self.delegate selectRegions:regionId regionName:regionName];
}*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [regionValueIdList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"RegionValue"];
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
