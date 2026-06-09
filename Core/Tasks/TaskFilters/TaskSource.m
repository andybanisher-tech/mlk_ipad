//
//  TaskSource.m
//  MLK
//
//  Created by garu on 12/11/14.
//
//

#import "TaskSource.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kCellHeight = 44.0;

@implementation TaskSource

static sqlite3 *database = nil;

@synthesize sourceList, sourceToLiveInArray;
@synthesize delegate;
@synthesize fromCust, custAccount, sourceSelected, selected, setBtn;

- (void)sourceListCreate {
    sourceList             = [NSMutableArray new];
    sourceToLiveInArray    = [NSMutableArray array];
    if (!sourceSelected)
        sourceSelected         = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
        if (fromCust)
            sql = "select Source, From1C from TaskTable where CustAccount = ? group by Source, From1C";
        else
            sql = "select Source, From1C from TaskTable group by Source, From1C";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            //[sourceToLiveInArray addObject:@"Убрать фильтр"];
            
            if (fromCust)
                sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *source = @"null";
                //NSString *setted = @"null";
                NSString *from1C = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    source  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                //if (sqlite3_column_text(selectstmt, 1))
                //    setted  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    from1C  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                
                if ([from1C isEqualToString:@"1"])
                {
                    if ([source isEqualToString:@"iPad"])
                        [sourceToLiveInArray     addObject:@"Назначено iPad"];
                    else
                        [sourceToLiveInArray     addObject:@"Назначено 1C"];
                    
                }
                else
                    [sourceToLiveInArray     addObject:@"Собственная"];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    NSDictionary *sourceToLiveInDict = [NSDictionary dictionaryWithObject:sourceToLiveInArray forKey:@"Source"];
    
    [sourceList      addObject:sourceToLiveInDict];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.frame = CGRectMake(0.0, 0.0, 250.0, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = CGSizeMake(self.tableView.contentSize.width, ([sourceList[0][@"Source"] count] + 1) * kCellHeight);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self sourceListCreate];
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

    [self enableApplyButton:[sourceSelected count] > 0];

    return sectionHead;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kCellHeight;
}

- (void)removeFilter:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidSelectTaskSources:)]) {
        [self.delegate userDidSelectTaskSources:nil];
    }
}

- (void)useFilter:(id)sender {
    if (sourceSelected.count != 0) {
        if ([self.delegate respondsToSelector:@selector(userDidSelectTaskSources:)]) {
            [self.delegate userDidSelectTaskSources:sourceSelected];
        }
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [sourceList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [sourceList objectAtIndex:0];
    NSArray		 *array      = [dictionary objectForKey:@"Source"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSDictionary	*dictionary = [sourceList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Source"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    /*if (indexPath.row == 0)
        cell.textLabel.textColor = [UIColor blueColor];
    else*/
        cell.textLabel.textColor = [UIColor blackColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    if ([selected containsObject:cellValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [sourceSelected addObject:cellValue];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //if (indexPath.row == 0)
    //    cell.backgroundColor = UIColor.lightGrayColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [sourceList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"Source"];
    NSString     *source	  = [array objectAtIndex:indexPath.row];
    
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (currentCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        currentCell.accessoryType = UITableViewCellAccessoryNone;
        [sourceSelected removeObject:source];
    } else {
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [sourceSelected addObject:source];
    }

    [self enableApplyButton:[sourceSelected count] > 0];
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
