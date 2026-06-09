//
//  CustomerTypesTableViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 15.10.2021.
//

#import "CustomerTypesTableViewController.h"
#import "RWBorderedButton.h"

#import "sqlite3.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kCustomerTypeCellHeight = 44.0;

static sqlite3 *database = nil;

@interface CustomerTypesTableViewController ()
@property (nonatomic, strong) NSMutableArray *typesArray;

@end

@implementation CustomerTypesTableViewController {
    UIBarButtonItem *_btnApply;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    if (!self.selectedTypesArray) {
        self.selectedTypesArray = [NSMutableArray new];
    }
    self.tableView.frame = CGRectMake(0, 0, 260, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createCustomerTypes];
}

#pragma mark - Data
- (void)createCustomerTypes {
    self.typesArray = [NSMutableArray new];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Property6, Property6Name from CustTable order by Property6Name";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *customerType = [NSMutableDictionary new];
                
                NSString *property6;
                NSString *property6Name;
                
                if (sqlite3_column_text(selectstmt, 0)) {
                    property6  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                }
                
                if (sqlite3_column_text(selectstmt, 1)) {
                    property6Name  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
                
                customerType[@"property6"] = property6;
                customerType[@"property6Name"] = property6Name;
                
                if (![self.typesArray containsObject:customerType] && property6.length > 0 && property6Name.length > 0) {
                    [self.typesArray addObject:customerType];
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 250, 44)];
    
    NSMutableArray* btns = [[NSMutableArray alloc] initWithCapacity:3];

    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,80,44)];
    [clearButton setTitle:@"Очистить" forState:UIControlStateNormal];
    [clearButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.f]];
    [clearButton setTitleColor:[UIColor colorNamed:ACColorNameMLKBlue] forState:UIControlStateNormal];
    [clearButton addTarget:self
                    action:@selector(clearFilters)
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
                    action:@selector(applyFilters)
          forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *sourcekey = [[UIBarButtonItem alloc] initWithCustomView:applyButton];

    _btnApply = sourcekey;

    [btns addObject:sourcekey];
    
    [sectionHead setItems:btns animated:NO];

    sectionHead.tintColor = [UIColor blackColor];
    [self enableApplyButton:self.selectedTypesArray.count > 0];
    return sectionHead;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kCustomerTypeCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *object = self.typesArray[indexPath.row];
    if ([self.selectedTypesArray containsObject:object]) {
        [self.selectedTypesArray removeObject:object];
    } else {
        [self.selectedTypesArray addObject:object];
    }

    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.typesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *object = self.typesArray[indexPath.row];

    cell.textLabel.text = object[@"property6Name"];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    if ([self.selectedTypesArray containsObject:object]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - ButtonActions
- (void)clearFilters {
    [self.selectedTypesArray removeAllObjects];
    [self applyFilters];
}

- (void)applyFilters {
    if ([self.delegate respondsToSelector:@selector(userDidSelectCustomerTypes:)]) {
        [self.delegate userDidSelectCustomerTypes:self.selectedTypesArray];
    }
}

#pragma mark - Helpers
- (void)enableApplyButton:(BOOL)state {
    UIButton *customViewButton = ((UIBarButtonItem *) _btnApply).customView;
    if (state) {
        [customViewButton setTitleColor:[UIColor colorNamed:ACColorNameMLKBlue] forState:UIControlStateNormal];
        [_btnApply setEnabled:YES];
    } else {
        [customViewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_btnApply setEnabled:NO];
    }
}

@end
