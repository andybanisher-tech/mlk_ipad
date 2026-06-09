//
//  BrandDop.m
//  MLK
//
//  Created by garu on 11/12/14.
//
//

#import "BrandDop.h"

#import "GeneratedAssetSymbols.h"

@implementation BrandDop

static sqlite3 *database = nil;

@synthesize brandList, brandIdList;
@synthesize delegate;
@synthesize brandSelected, selected, setBtn, brandString;

- (void)brandCreate {
    brandList             = [NSMutableArray new];
	brandToLiveInArray    = [NSMutableArray array];
    
    brandIdList           = [NSMutableArray new];
	brandIdToLiveInArray  = [NSMutableArray array];
    
    if (!brandSelected)
        brandSelected       = [NSMutableArray new];

    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select BrandName, BrandId from BrandDop order by BrandName";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				
                NSString *brand     = @"null";
                NSString *brandId   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    brand  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    brandId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [brandToLiveInArray     addObject:brand];
                [brandIdToLiveInArray   addObject:brandId];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *brandToLiveInDict     = [NSDictionary dictionaryWithObject:brandToLiveInArray forKey:@"Brand"];
    NSDictionary *brandIdToLiveInDict   = [NSDictionary dictionaryWithObject:brandIdToLiveInArray forKey:@"BrandId"];
    
    [brandList      addObject:brandToLiveInDict];
    [brandIdList    addObject:brandIdToLiveInDict];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.tableView.frame = CGRectMake(0, 0, 260, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self brandCreate];
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
    [self enableApplyButton:[brandSelected count] > 0];
    return sectionHead;
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

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}


- (void)removeFilter:(id)sender {
    [self.delegate selectBrand:nil];
}

- (void)useFilter:(id)sender {
    if ([brandSelected count] != 0) {
        NSDictionary	*dictionary = [brandList objectAtIndex:0];
        NSArray			*arrayN		= [dictionary objectForKey:@"Brand"];
        
        NSDictionary	*dictionaryV = [brandIdList objectAtIndex:0];
        NSArray			*arrayV		 = [dictionaryV objectForKey:@"BrandId"];
        
        for (int i = 0; i < [brandSelected count]; i++) {
            NSUInteger j = [arrayV indexOfObject:brandSelected[i]];
            if (i == 0)
                brandString = [NSString stringWithFormat:@"%@", arrayN[j]];
            else
                brandString = [NSString stringWithFormat:@"%@,%@", brandString, arrayN[j]];
        }

        [self.delegate selectBrandArray:brandSelected brandString:brandString];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [brandList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [brandList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"Brand"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
	
    NSDictionary	*dictionary = [brandList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Brand"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionaryV = [brandIdList objectAtIndex:0];
    NSArray			*arrayV		 = [dictionaryV objectForKey:@"BrandId"];
    NSString		*cellValueV	 = [arrayV objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    cell.textLabel.textColor = [UIColor blackColor];
    
    if ([selected containsObject:cellValueV]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [brandSelected addObject:cellValueV];
    } else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([brandSelected containsObject:cellValueV]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [brandIdList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"BrandId"];
    NSString     *brandId	  = [array objectAtIndex:indexPath.row];
    
    [self.delegate selectBrand:brandId];
}*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [brandIdList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"BrandId"];
    NSString     *source	  = [array objectAtIndex:indexPath.row];
    
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (currentCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        currentCell.accessoryType = UITableViewCellAccessoryNone;
        [brandSelected removeObject:source];
    } else {
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [brandSelected addObject:source];
    }
    [self enableApplyButton:[brandSelected count] > 0];
}

+ (void)finalizeStatements {
	if (database)
		sqlite3_close(database);
}

@end
