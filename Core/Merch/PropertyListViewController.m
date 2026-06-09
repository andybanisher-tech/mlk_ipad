//
//  PropertyListViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 02.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "PropertyListViewController.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@implementation PropertyListViewController

/*@synthesize delegate;
@synthesize propIdList, elementIdList, elementNameList;
@synthesize propertyId;*/

#define LABEL_TAG 1

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.frame = CGRectMake(0, 0, 250, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [self refreshData];
    [super viewDidLoad];
}

- (void)createList {
    propIdList                = [NSMutableArray new];
	propIdToLiveInArray       = [NSMutableArray new];
    
    elementIdList             = [NSMutableArray new];
	elementIdToLiveInArray    = [NSMutableArray new];
    
    elementNameList           = [NSMutableArray new];
	elementNameToLiveInArray  = [NSMutableArray new];
    
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

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [propIdList count];
}
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dictionary = [propIdList objectAtIndex:section];
    NSArray		 *array      = [dictionary objectForKey:@"propId"];
    
    return [array count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Get the label for the current cell
	NSDictionary	*dictionary = [elementNameList objectAtIndex:indexPath.section];
    NSArray			*array		= [dictionary objectForKey:@"elementName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text = cellValue;
    
    NSDictionary *elementIDDictionary = elementIdList[indexPath.section];
    NSArray *elementIDArray = elementIDDictionary[@"elementId"];
    NSString *elementID = elementIDArray[indexPath.row];
    
    if ([savedCollection[elementID][@"elementName"] isEqual:cellValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
}

- (void)refreshData{
    [self createList];
    [self.tableView reloadData];
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView  *headerView             = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    headerView.backgroundColor      = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
    UILabel *headerString           = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    
    headerString.text = @"Выберите значение";
        
    headerString.textAlignment      = NSTextAlignmentCenter;
    headerString.textColor          = UIColor.whiteColor;
    headerString.backgroundColor    = UIColor.clearColor;
        
    [headerView addSubview:headerString];
        
    return headerView;
}
@end
