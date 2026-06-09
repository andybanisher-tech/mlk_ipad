//
//  CustForTaskView.m
//  MLK
//
//  Created by garu on 11/26/14.
//
//

#import "CustForTaskView.h"

@implementation CustForTaskView

static sqlite3 *database = nil;

@synthesize custAccList, custNameList;
@synthesize delegate;
@synthesize taskId;
@synthesize fcity, cityArray;
@synthesize fkey, keyArray;
@synthesize fmark, markArray;
@synthesize arrayByCopyCustAccList;
@synthesize arrayByCopyCustNameList;
@synthesize cityBtn;
@synthesize markBtn;
@synthesize keyBtn;
@synthesize selectedArray;

- (void)custListCreate {
    custAccList             = [NSMutableArray new];
	custAccToLiveInArray    = [NSMutableArray array];
    
    custNameList               = [NSMutableArray new];
	custNameToLiveInArray  = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select CustAccount, Name from CustTable where not exists(select * from TaskTable where CustTable.CustAccount == TaskTable.CustAccount and TaskId = ?) order by Name";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *acc     = @"null";
                NSString *name   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    acc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    name  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [custAccToLiveInArray    addObject:acc];
                [custNameToLiveInArray   addObject:name];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *custAccToLiveInDict     = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    NSDictionary *custNameToLiveInDict   = [NSDictionary dictionaryWithObject:custNameToLiveInArray forKey:@"CustName"];
    
    [custAccList      addObject:custAccToLiveInDict];
    [custNameList    addObject:custNameToLiveInDict];
}

- (void)selectWithFilters {
    custAccList             = [NSMutableArray new];
	custAccToLiveInArray    = [NSMutableArray array];
    
    custNameList               = [NSMutableArray new];
	custNameToLiveInArray  = [NSMutableArray array];
    
    arrayByCopyCustAccList = [NSMutableArray new];
    arrayByCopyCustNameList = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        NSString *squl;
        
        squl = @"select CustAccount, Name from CustTable where not exists(select * from TaskTable where CustTable.CustAccount == TaskTable.CustAccount and TaskId = ?)";
        
        if (fkey) {
            squl = [NSString stringWithFormat:@"%@ and exists(select * from CustStatusDN where CustTable.CustAccount == CustStatusDN.CustAccount and %@)", squl, fkey];
        }
        if (fcity) {
            squl = [NSString stringWithFormat:@"%@ and %@", squl, fcity];
        }
        if (fmark) {
            squl = [NSString stringWithFormat:@"%@ and exists(select * from PersonalPriceList where CustTable.CustAccount == PersonalPriceList.CustAccount and PersonalPriceList.Active = '1' and %@)", squl, fmark];
        }
        
        squl = [NSString stringWithFormat:@"%@ order by Name", squl];
        sql  = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *acc   = @"null";
                NSString *name  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    acc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                     name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                
                [custAccToLiveInArray    addObject:acc];
                [custNameToLiveInArray   addObject:name];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *custsToLiveInDict    = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    NSDictionary *custsAccToLiveInDict = [NSDictionary dictionaryWithObject:custNameToLiveInArray forKey:@"CustName"];
    
    [custAccList    addObject:custsToLiveInDict];
    [custNameList addObject:custsAccToLiveInDict];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.frame = CGRectMake(0, 0, 650, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self custListCreate];
}

- (void)loadView{
    [super loadView];
    
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 703, 44)];
    
    NSMutableArray* btns = [[NSMutableArray alloc] initWithCapacity:3];
    
    // create a spacer
    UIBarButtonItem *bit = [[UIBarButtonItem alloc]
                            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [btns addObject:bit];

    // create a standard "refresh" button
    UIBarButtonItem *city = [[UIBarButtonItem alloc] initWithTitle:@"Регион" style:UIBarButtonItemStyleDone target:self action:@selector(showCity:)];
    
    [btns addObject:city];
    
    UIBarButtonItem *custkey = [[UIBarButtonItem alloc] initWithTitle:@"Статус" style:UIBarButtonItemStyleDone target:self action:@selector(showDream:)];
    
    [btns addObject:custkey];
    
    UIBarButtonItem *mark = [[UIBarButtonItem alloc] initWithTitle:@"Марка" style:UIBarButtonItemStyleDone target:self action:@selector(showBrand:)];
    
    [btns addObject:mark];
    
    [sectionHead setItems:btns animated:NO];

    sectionHead.tintColor = [UIColor blackColor];
    
    return sectionHead;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [custAccList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [custAccList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"CustAcc"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSDictionary	*dictionary = [custNameList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"CustName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [custAccList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"CustAcc"];
    NSString     *acc	      = [array objectAtIndex:indexPath.row];
    
    NSDictionary *dictName    = [custNameList objectAtIndex:indexPath.section];
    NSArray      *arrayName   = [dictName objectForKey:@"CustName"];
    NSString     *custName    = [arrayName objectAtIndex:indexPath.row];
    
    [self.delegate selectCustAcc:acc custName:custName];
}

+ (void)finalizeStatements {
	if (database)
		sqlite3_close(database);
}

- (void)populateSelectedArray{
	NSDictionary *dictCustAcc  = [custAccList objectAtIndex:0];
    NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[arrayCustAcc count]];
	for (int y=0; y < [arrayCustAcc count]; y++)
		[array addObject:[NSNumber numberWithBool:NO]];
	self.selectedArray = array;
}

- (void)userDidSelectCities:(NSMutableArray *)cities {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    cityArray = [cities copy];
    
    NSString *squl;
    for (NSString *city in cityArray) {
        if ([city isEqualToString:cityArray.firstObject]) {
            squl = [NSString stringWithFormat:@"City = '%@'", city];
        } else {
            squl = [NSString stringWithFormat:@"%@ or City = '%@'", squl, city];
        }
    }
    
    fcity = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    [self selectWithFilters];
    [self populateSelectedArray];
    [self.tableView reloadData];
    
    if (fcity == nil) {
        [cityBtn setTintColor:UIColor.clearColor];
    } else {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [cityBtn setTintColor:color];
    }
}

- (void)userDidSelectBrand:(NSMutableArray *)brandArray{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    markArray = [brandArray copy];
    
    NSArray *array = [brandArray copy];
    NSString *squl;
    int counter;
    
    for(counter = 0; counter < [array count]; counter++) {
        if (counter == 0) {
            squl = [NSString stringWithFormat:@"BrandId = '%@'", [array objectAtIndex:counter]];
        } else {
            squl = [NSString stringWithFormat:@"%@ or BrandId = '%@'", squl, [array objectAtIndex:counter]];
        }
    }
    
    fmark = [NSString stringWithFormat:@"(%@)",squl];

    [self selectWithFilters];
    [self populateSelectedArray];
    [self.tableView reloadData];
    
    if (fmark == nil) {
        [markBtn setTintColor:UIColor.clearColor];
    } else {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [markBtn setTintColor:color];
    }
    
}

- (void)userDidSelectDream:(NSMutableArray *)dreamArray{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    keyArray = [dreamArray copy];
    
    NSString *squl;
    for (NSString *dream in dreamArray) {
        if ([dream isEqualToString:keyArray.firstObject]) {
            squl = [NSString stringWithFormat:@"StatusDN = '%@'", dream];
        } else {
            squl = [NSString stringWithFormat:@"%@ or StatusDN = '%@'", squl, dream];
        }
    }
    
    fkey = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    [self selectWithFilters];
    [self populateSelectedArray];
    [self.tableView reloadData];
    
    if (fkey == nil) {
        [keyBtn setTintColor:UIColor.clearColor];
    } else {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [keyBtn setTintColor:color];
    }
}

- (void)selectBrand:(NSString *)brand {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (!brand)
        markArray = nil;

    fmark = brand;

    [self selectWithFilters];
    [self populateSelectedArray];
    [self.tableView reloadData];
    
    if (fmark == nil) {
        [markBtn setTintColor:UIColor.clearColor];
    } else {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [markBtn setTintColor:color];
    }
}

- (void)showCity:(id)sender {
    [self.tableView reloadData];
    
    if (self.presentedViewController) { return; }
    CustCity *custCity = [CustCity new];
    custCity.delegate = self;
    custCity.selected = cityArray;
    
    custCity.modalPresentationStyle = UIModalPresentationPopover;
    custCity.popoverPresentationController.sourceView = self.view;
    custCity.popoverPresentationController.sourceRect = CGRectMake(-40, 0, 150, 44);
    [self presentViewController:custCity animated:YES completion:nil];
    
    cityBtn = sender;
}

- (void)showBrand:(id)sender {
    [self.tableView reloadData];
    
    if (self.presentedViewController) { return; }
    CustBrand *custBrand = [CustBrand new];
    custBrand.delegate  = self;
    custBrand.selected = markArray;
    
    custBrand.modalPresentationStyle = UIModalPresentationPopover;
    custBrand.popoverPresentationController.sourceView = self.view;
    custBrand.popoverPresentationController.sourceRect = CGRectMake(120, 0, 150, 44);
    
    [self presentViewController:custBrand animated:YES completion:nil];

    markBtn = sender;
}

- (void)showDream:(id)sender {
    [self.tableView reloadData];
    
    if (self.presentedViewController) { return; }
    CustDream *custDream = [CustDream new];
    custDream.delegate = self;
    custDream.selected = keyArray;
    
    custDream.modalPresentationStyle = UIModalPresentationPopover;
    custDream.popoverPresentationController.sourceView = self.view;
    custDream.popoverPresentationController.sourceRect = CGRectMake(40, 0, 150, 44);
    
    [self presentViewController:custDream animated:YES completion:nil];
    
    keyBtn = sender;
}


@end
