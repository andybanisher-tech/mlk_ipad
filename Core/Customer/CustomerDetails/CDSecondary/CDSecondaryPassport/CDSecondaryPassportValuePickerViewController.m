//
//  CDSecondaryPassportValuePickerViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 28.03.2025.
//

#import "CDSecondaryPassportValuePickerViewController.h"

//Cells
#import "CDSecondaryPassportValuePickerTableViewCell.h"

#import "GeneratedAssetSymbols.h"

#import "sqlite3.h"

//UI Constants
static const CGFloat kPassportValueCellHeight = 50.0;

@interface CDSecondaryPassportValuePickerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mainTableView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

static sqlite3 *database = nil;

@implementation CDSecondaryPassportValuePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self prepareDataSource];
}

#pragma mark - UI
- (void)setupNavBar {
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[ASPFunctions colorFromHex:@"F2F2F7"] titleColor:[ASPFunctions colorFromHex:@"4F4F4F"] tintColor:[UIColor colorNamed:ACColorNameMLKLightBlue]];
    self.navigationController.navigationBar.standardAppearance.shadowColor = UIColor.clearColor;
    self.navigationController.navigationBar.scrollEdgeAppearance.shadowColor = UIColor.clearColor;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self  action:@selector(cancelButtonTapped)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self  action:@selector(doneButtonTapped)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

#pragma mark - Button Actions
- (void)cancelButtonTapped {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonTapped {
    [self.view endEditing:YES];
    
    if ([self.delegate respondsToSelector:@selector(userDidPickValues:listIDs:propertyID:)]) {
        [self.delegate userDidPickValues:self.selectedValues listIDs:self.selectedListIDs propertyID:self.propertyID];
    }
}

#pragma mark - Prepare Data
- (void)prepareDataSource {
    self.dataSource = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select ListElementId, ListElementName from MerchPropertiesList where PropertyId = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            sqlite3_bind_text(selectstmt, 1, self.propertyID.UTF8String, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *contact = [NSMutableDictionary new];
                
                for (int i = 0; i < sqlite3_column_count(selectstmt); i++) {
                    if (sqlite3_column_text(selectstmt, i)) {
                        NSString *key = [NSString stringWithUTF8String:(char *)sqlite3_column_name(selectstmt, i)];
                        NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, i)];
                        contact[key] = value;
                    }
                }
                
                [self.dataSource addObject:contact];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self.mainTableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryPassportValuePickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(CDSecondaryPassportValuePickerTableViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.row];
    
    NSString *elementName = object[@"ListElementName"];
    [cell setName:elementName];
    
    if ([self.selectedValues containsObject:elementName]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kPassportValueCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *object = self.dataSource[indexPath.row];
    
    NSString *elementID = object[@"ListElementId"];
    NSString *elementName = object[@"ListElementName"];
    if ([self.selectedListIDs containsObject:elementID]) {
        [self.selectedListIDs removeObject:elementID];
        [self.selectedValues removeObject:elementName];
    } else {
        if (!self.isMultiple) {
            [self.selectedListIDs removeAllObjects];
            [self.selectedValues removeAllObjects];
        }
        
        [self.selectedListIDs addObject:elementID];
        [self.selectedValues addObject:elementName];
    }
    
    [self.mainTableView reloadData];
}

@end
