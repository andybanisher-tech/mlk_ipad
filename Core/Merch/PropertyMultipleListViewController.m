
#import "PropertyMultipleListViewController.h"

static sqlite3 *database = nil;

@implementation PropertyMultipleListViewController

@synthesize setBtn, selectedCollection;

#define LABEL_TAG 1

- (BOOL)shouldAutorotate {
    return YES;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 250, 54)];
    
    NSMutableArray* btns = [[NSMutableArray alloc] initWithCapacity:3];
    
    UIBarButtonItem *custkey = [[UIBarButtonItem alloc] initWithTitle:@"Очистить" style:UIBarButtonItemStyleDone target:self action:@selector(removeFilter:)];
    
    [btns addObject:custkey];
    
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    [fixed setWidth:60.0f];
    [btns addObject:fixed];
    
    UIBarButtonItem *sourcekey = [[UIBarButtonItem alloc] initWithTitle:@"Применить" style:UIBarButtonItemStyleDone target:self action:@selector(useFilter:)];
    
    setBtn = sourcekey;
    
    [btns addObject:sourcekey];
    
    [sectionHead setItems:btns animated:NO];

    sectionHead.tintColor = [UIColor blackColor];
    
    UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
    [setBtn setTintColor:color];
    
    [setBtn setEnabled:YES];
    
    return sectionHead;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 54;
}

- (void)removeFilter:(id)sender {
    //[self.delegate selectCity:nil];
    [savedCollection removeAllObjects];
    [selectedCollection removeAllObjects];
    [self viewDidLoad];
}

- (void)useFilter:(id)sender {
    //if ([citySelected count] != 0)
    [self.delegate multipleSelect:selectedCollection propId:propertyId];
}

- (void)viewDidLoad {
    [self refreshData];
    [super viewDidLoad];
}

- (void)createList {
    
    propIdList                = [NSMutableArray new];
	propIdToLiveInArray       = [NSMutableArray array];
    
    elementIdList             = [NSMutableArray new];
	elementIdToLiveInArray    = [NSMutableArray array];
    
    elementNameList           = [NSMutableArray new];
	elementNameToLiveInArray  = [NSMutableArray array];
    
    if (selectedCollection == nil) {
        selectedCollection = [[NSMutableDictionary alloc] init];
    }
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select PropertyId, ListElementId, ListElementName from MerchPropertiesList where PropertyId = ?";
		
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
			sqlite3_bind_text(selectstmt, 1, [propertyId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *propId      = @"";
                NSString *elementId   = @"";
                NSString *elementName = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    propId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    elementId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    elementName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                [propIdToLiveInArray        addObject:propId];
                [elementIdToLiveInArray     addObject:elementId];
                [elementNameToLiveInArray   addObject:elementName];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *propIdToLiveInDict      = [NSDictionary dictionaryWithObject:propIdToLiveInArray forKey:@"propId"];
    NSDictionary *elementIdToLiveInDict   = [NSDictionary dictionaryWithObject:elementIdToLiveInArray forKey:@"elementId"];
    NSDictionary *elementNameToLiveInDict = [NSDictionary dictionaryWithObject:elementNameToLiveInArray forKey:@"elementName"];
    
    [propIdList       addObject:propIdToLiveInDict];
    [elementIdList    addObject:elementIdToLiveInDict];
    [elementNameList  addObject:elementNameToLiveInDict];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return [propIdList count];
}
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dictionary = [propIdList objectAtIndex:section];
    NSArray		 *array      = [dictionary objectForKey:@"propId"];
    
    return [array count];
}

/*- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Get the label for the current cell
	NSDictionary	*dictionary = [elementNameList objectAtIndex:indexPath.section];
    NSArray			*array		= [dictionary objectForKey:@"elementName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text       = cellValue;
    
    return cell;
}*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
	
    NSDictionary	*dictionary = [elementNameList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"elementName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    
    
    cell.textLabel.textColor = [UIColor blackColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    NSDictionary	*dictionaryElemId = [elementIdList objectAtIndex:0];
    NSArray			*arrayElemId		= [dictionaryElemId objectForKey:@"elementId"];
    NSString		*currentValue	= [arrayElemId objectAtIndex:indexPath.row];
    
    
    if ([savedCollection objectForKey:currentValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        [selectedCollection setObject:[savedCollection objectForKey:currentValue] forKey:currentValue];
        //[savedCollection removeAllObjects];

    } else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([selectedCollection objectForKey:currentValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}
/*- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary	*dictionaryId  = [propIdList objectAtIndex:indexPath.section];
    NSArray			*arrayId	   = [dictionaryId objectForKey:@"propId"];
    NSString		*propId        = [arrayId objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionaryElementId  = [elementIdList objectAtIndex:indexPath.section];
    NSArray			*arrayElementId	      = [dictionaryElementId objectForKey:@"elementId"];
    NSString		*propElementId        = [arrayElementId objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionary = [elementNameList objectAtIndex:indexPath.section];
    NSArray			*array		= [dictionary objectForKey:@"elementName"];
    NSString		*propName	= [array objectAtIndex:indexPath.row];
    
    if (self.delegate) {
        [self.delegate elementIsSelected:propName propId:propId propElementId:propElementId];
    }
}*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionaryPropId  = [propIdList objectAtIndex:indexPath.section];
    NSArray      *arrayPropId       = [dictionaryPropId objectForKey:@"propId"];
    NSString     *propId	  = [arrayPropId objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionaryElementId  = [elementIdList objectAtIndex:indexPath.section];
    NSArray			*arrayElementId	      = [dictionaryElementId objectForKey:@"elementId"];
    NSString		*propElementId        = [arrayElementId objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionary = [elementNameList objectAtIndex:indexPath.section];
    NSArray			*array		= [dictionary objectForKey:@"elementName"];
    NSString		*propName	= [array objectAtIndex:indexPath.row];
    
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (currentCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        currentCell.accessoryType = UITableViewCellAccessoryNone;
        [selectedCollection removeObjectForKey:propElementId];
    } else {
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        NSMutableDictionary *addRow = [[NSMutableDictionary alloc]init];
        [addRow setObject:propId forKey:@"propId"];
        [addRow setObject:propElementId forKey:@"elementId"];
        [addRow setObject:propName forKey:@"elementName"];
        [selectedCollection setObject:addRow forKey:propElementId];
        addRow = nil;
    }

    /*if ([selectedCollection count] > 0) {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [setBtn setTintColor:color];
        
        [setBtn setEnabled:YES];
    } else {
        //[setBtn setTintColor:UIColor.clearColor];
        //[setBtn setEnabled:FALSE];
    }*/
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.frame = CGRectMake(0, 0, 250, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)refreshData{

    [self createList];
    [self.tableView reloadData];
}

@end
