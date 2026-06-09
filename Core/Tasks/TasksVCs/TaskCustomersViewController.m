//
//  TaskCustomersViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 12.08.2021.
//

#import "TaskCustomersViewController.h"
#import "TaskTransViewController.h"

//Filters
#import "CustCity.h"
#import "CustDream.h"
#import "TaskSource.h"
#import "ASPDatePickerViewController.h"

//Custom Classes
#import "PutClientForRouteRequest.h"
#import "RWBorderedButton.h"

#import "sqlite3.h"

//Cells
#import "TaskCustomerTableViewCell.h"

#import "GeneratedAssetSymbols.h"

//Constants
static const CGFloat kTaskCustomerCellHeight = 64.0;

static sqlite3 *database = nil;

@interface TaskCustomersViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CustCityDelegate, CustDreamDelegate, TaskSourceDelegate, ASPDatePickerViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *mainSearchBar;
@property (nonatomic, weak) IBOutlet UITableView *mainTableView;

@property (nonatomic, weak) IBOutlet RWBorderedButton *btnRegion;
@property (nonatomic, weak) IBOutlet RWBorderedButton *btnStatus;
@property (nonatomic, weak) IBOutlet RWBorderedButton *btnSource;
@property (nonatomic, weak) IBOutlet RWBorderedButton *btnRoute;

@property (nonatomic, strong) NSMutableArray *taskCustomersArray;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) NSDictionary *customerToAddToRoute;

@property (nonatomic, strong) NSDateFormatter *mainDateFormatter;

//Filters
@property (nonatomic, strong) NSArray *selectedRegionsArray;
@property (nonatomic, strong) NSArray *selectedStatusesArray;
@property (nonatomic, strong) NSArray *selectedSourcesArray;
@property (nonatomic, assign) BOOL isRouteSelected;

@end

@implementation TaskCustomersViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    
    [SVProgressHUD showWithStatus:@"Загрузка списка клиентов"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self createTaskCustomers];
    });
}

#pragma mark - UI Setup
- (void)setupUI{
    //NavBar Setup
    self.navigationItem.title = self.selectedTask[@"taskName"];
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    //SearchBar
    self.mainSearchBar.searchTextField.backgroundColor = UIColor.whiteColor;
    
    //DateFormatter
    self.mainDateFormatter = NSDateFormatter.new;
    self.mainDateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
}

#pragma mark - Button Actions
- (IBAction)btnRegionTapped:(RWBorderedButton *)sender {
    if (self.presentedViewController) { return; }
    
    CustCity *regionsVC = [CustCity new];
    regionsVC.delegate = self;
    regionsVC.fromTask = YES;
    regionsVC.selected = self.selectedRegionsArray.mutableCopy;
    
    regionsVC.modalPresentationStyle = UIModalPresentationPopover;
    regionsVC.popoverPresentationController.sourceView = sender;
    [self presentViewController:regionsVC animated:YES completion:nil];
}

- (IBAction)btnStatusTapped:(RWBorderedButton *)sender {
    if (self.presentedViewController) { return; }
    
    CustDream *statusVC = [CustDream new];
    statusVC.delegate = self;
    statusVC.fromTask = YES;
    statusVC.selected = self.selectedStatusesArray.mutableCopy;
    
    statusVC.modalPresentationStyle = UIModalPresentationPopover;
    statusVC.popoverPresentationController.sourceView = sender;
    [self presentViewController:statusVC animated:YES completion:nil];
}

- (IBAction)btnSourceTapped:(RWBorderedButton *)sender {
    if (self.presentedViewController) { return; }
    
    TaskSource *taskSourceVC = [TaskSource new];
    taskSourceVC.delegate = self;
    taskSourceVC.selected = self.selectedSourcesArray.mutableCopy;
    
    taskSourceVC.modalPresentationStyle = UIModalPresentationPopover;
    taskSourceVC.popoverPresentationController.sourceView = sender;
    [self presentViewController:taskSourceVC animated:YES completion:nil];
}

- (IBAction)btnRouteTapped:(RWBorderedButton *)sender {
    self.isRouteSelected = !self.isRouteSelected;
    [sender setHighlightedState:_isRouteSelected];
    [self applyFilters];
}

#pragma mark - CustCityDelegate
- (void)userDidSelectCities:(NSMutableArray *)cities {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self.btnRegion setHighlightedState:cities.count > 0];
    if (!(self.selectedRegionsArray.count < 1 && cities.count < 1)) {
        self.selectedRegionsArray = cities;
        [self applyFilters];
    }
}

#pragma mark - CustDreamDelegate
- (void)userDidSelectDream:(NSMutableArray *)dreamArray{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self.btnStatus setHighlightedState:dreamArray.count > 0];
    if (!(self.selectedStatusesArray.count < 1 && dreamArray.count < 1)) {
        self.selectedStatusesArray = dreamArray;
        [self applyFilters];
    }
}

#pragma mark - TaskSourceDelegate
- (void)userDidSelectTaskSources:(NSMutableArray *)taskSources {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self.btnSource setHighlightedState:taskSources.count > 0];
    if (!(self.selectedSourcesArray.count < 1 && taskSources.count < 1)) {
        self.selectedSourcesArray = taskSources;
        [self applyFilters];
    }
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *dateString = [self.mainDateFormatter stringFromDate:date];
        [self addCustomerToRoute:self.customerToAddToRoute date:dateString];
        self.customerToAddToRoute = nil;
    }];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TaskCustomerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([TaskCustomerTableViewCell class]) forIndexPath:indexPath];
    cell.userInteractionEnabled = YES;
    
    NSDictionary *object = self.dataSource[indexPath.row];
    
    cell.lblCustomerName.text = object[@"custName"];
    cell.lblStartDate.text = object[@"startDate"];
    
    NSString *source = [NSString stringWithFormat:@"Назначено %@", object[@"source"]];
    if (![object[@"from1C"] isEqualToString:@"1"]) {
        source = @"Собственная";
    }
    cell.lblSource.text = source;
    
    cell.lblResult.text = object[@"result"];
    
    if ([object[@"typeOfResult"] isEqualToString:@"2"]) {
        cell.lblResult.text = object[@"lineDescription"];
    }
    
    NSString *status = object[@"status"];
    if ([status isEqualToString:@"Готово"]) {
        cell.lblStatus.textColor = [UIColor colorNamed:ACColorNameMLKGreen];
    } else {
        cell.lblStatus.textColor = [UIColor blackColor];
    }
    
    NSInteger daysLeft = [object[@"daysLeft"] integerValue];
    if (daysLeft < 7) {
        if (daysLeft >= 0) {
            status = [NSString stringWithFormat:@"%@\nГорит", status];
        }
        
        if (daysLeft < 0) {
            status = [NSString stringWithFormat:@"%@\nПросрочка", status];
            cell.userInteractionEnabled = NO;
        }
        cell.lblStatus.textColor = [UIColor redColor];
    }
    cell.lblStatus.text = status;
    
    cell.lblLastActionDate.text = object[@"transDate"];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kTaskCustomerCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self showActionSheetFrom:[tableView cellForRowAtIndexPath:indexPath] forCustomer:self.dataSource[indexPath.row]];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
    [self applyFilters];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [self applyFilters];
}

#pragma mark - Preparing Data
- (void)createTaskCustomers {
    [self.mainSearchBar resignFirstResponder];
    self.taskCustomersArray = [NSMutableArray new];
    
    NSString *taskID = self.selectedTask[@"taskID"];
    
    //Retrieving Initial Data
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sqlCustTable = [@"select Name, CustAccount, City, FactAddress, GPSPoint, LastVisitDate, SalesDate, Property6, PDZAmount from CustTable where 1=1 and exists(select * from TaskTable where CustTable.CustAccount == TaskTable.CustAccount and TaskId = ?) order by Name" UTF8String];
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sqlCustTable, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [taskID UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custName = @"null";
                NSString *custAccount = @"null";
                NSString *city = @"null";
                NSString *factAddress = @"null";
                NSString *gpsPoint = @"null";
                NSString *lastVisitDate;
                NSString *salesDate;
                NSString *property6;
                NSString *pdzAmount;
                
                if (sqlite3_column_text(selectstmt, 0))
                    custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                if (sqlite3_column_text(selectstmt, 1))
                    custAccount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                if (sqlite3_column_text(selectstmt, 2))
                    city = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                if (sqlite3_column_text(selectstmt, 3))
                    factAddress = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                if (sqlite3_column_text(selectstmt, 4))
                    gpsPoint = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                if (sqlite3_column_text(selectstmt, 5))
                    lastVisitDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                if (sqlite3_column_text(selectstmt, 6))
                    salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                if (sqlite3_column_text(selectstmt, 7))
                    property6 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                if (sqlite3_column_text(selectstmt, 8))
                    pdzAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
 
                //Retrieving Additional Data
                NSMutableDictionary *taskCustomer = [self taskCustomerForTaskID:taskID custAccount:custAccount];
                taskCustomer[@"custName"] = custName;
                taskCustomer[@"custAccount"] = custAccount;
                taskCustomer[@"city"] = city;
                taskCustomer[@"factAddress"] = factAddress;
                taskCustomer[@"gpsPoint"] = gpsPoint;
                taskCustomer[@"lastVisitDate"] = lastVisitDate;
                taskCustomer[@"salesDate"] = salesDate;
                taskCustomer[@"property6"] = property6;
                taskCustomer[@"pdzAmount"] = pdzAmount;
                taskCustomer[@"lineDescription"] = [self lineDescriptionForTaskID:taskID result:taskCustomer[@"result"]];
                
                [self.taskCustomersArray addObject:taskCustomer];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);

    [self applyFilters];
    
    [SVProgressHUD dismiss];
}

#pragma mark - Data Helpers
- (NSMutableDictionary *)taskCustomerForTaskID:(NSString *)taskID custAccount:(NSString *)custAcc {
    const char *sqlTaskTable = [@"select DateStart, DateEnd, Setted, Source, From1C, TypeOfResult, Result, Visit, Status from TaskTable where TaskId = ? and CustAccount = ?" UTF8String];
    sqlite3_stmt *selectstmt;
    
    NSMutableDictionary *taskCustomer = [NSMutableDictionary new];
    NSDate *nowDate = NSDate.date;
    NSString *nowDateString = [self.mainDateFormatter stringFromDate:nowDate];
    
    if (sqlite3_prepare_v2(database, sqlTaskTable, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [taskID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selectstmt, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectstmt) == SQLITE_ROW) {
            NSString *startDateString = @"";
            NSString *endDateString = @"";
            NSString *setted = @"null";
            NSString *source = @"null";
            NSString *from1C = @"null";
            NSString *typeOfResult = @"null";
            NSString *result = @"null";
            NSString *visit = @"null";
            NSString *status = @"null";
            
            if (sqlite3_column_text(selectstmt, 0))
                startDateString = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            if (sqlite3_column_text(selectstmt, 1))
                endDateString = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
            if (sqlite3_column_text(selectstmt, 2))
                setted = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
            if (sqlite3_column_text(selectstmt, 3))
                source = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
            if (sqlite3_column_text(selectstmt, 4))
                from1C = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
            if (sqlite3_column_text(selectstmt, 5))
                typeOfResult = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
            if (sqlite3_column_text(selectstmt, 6))
                result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
            if (sqlite3_column_text(selectstmt, 7))
                visit = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
            if (sqlite3_column_text(selectstmt, 8))
                status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
            
            taskCustomer[@"startDate"] = startDateString;
            taskCustomer[@"endDate"] = endDateString;
            taskCustomer[@"setted"] = setted;
            taskCustomer[@"source"] = source;
            taskCustomer[@"from1C"] = from1C;
            taskCustomer[@"typeOfResult"] = typeOfResult;
            taskCustomer[@"result"] = result;
            taskCustomer[@"visit"] = visit;
            taskCustomer[@"status"] = status;
            
            if (![status isEqualToString:@"Готово"] && ![status isEqualToString:@"Отказ"]) {
                NSDate *endDate = [self.mainDateFormatter dateFromString:endDateString];
                
                NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:nowDate toDate:endDate options:kNilOptions];
                taskCustomer[@"daysLeft"] = [NSNumber numberWithInteger:dateComponents.day];
            }
            
            //Retrieving TransDate
            taskCustomer[@"transDate"] = [self latestTransDateForTaskID:taskID custAccount:custAcc];
            //Retrieving CustomerInRouteData
            [taskCustomer addEntriesFromDictionary:[self customerInRouteData:custAcc dateOfRoute:nowDateString]];
        }
    }
    sqlite3_finalize(selectstmt);
    
    return taskCustomer;
}

- (NSDictionary *)customerInRouteData:(NSString *)custAcc dateOfRoute:(NSString *)dateOfRoute {
    const char *sqlTCustForRoute = [@"select CustAccount, Status from CustForRoute where CustAccount = ? and DateOfRoute = ?" UTF8String];
    sqlite3_stmt *selectstmt;
    
    NSString *custAccount = @"";
    NSString *status = @"";
    if (sqlite3_prepare_v2(database, sqlTCustForRoute, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selectstmt, 2, [dateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectstmt) == SQLITE_ROW) {
            if (sqlite3_column_text(selectstmt, 0))
                custAccount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            if (sqlite3_column_text(selectstmt, 1))
                status = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
        }
    }
    sqlite3_finalize(selectstmt);
    
    NSNumber *isInRoute = [NSNumber numberWithBool:custAccount.length > 0];
    NSNumber *isVisitInRoute = [NSNumber numberWithBool:[status isEqualToString:@"visit"]];
    
    return @{@"isInRoute" : isInRoute, @"isVisitInRoute" : isVisitInRoute};
}

- (NSString *)latestTransDateForTaskID:(NSString *)taskID custAccount:(NSString *)custAcc {
    const char *sqlTaskTrans = [@"select TransDate from TaskTrans where TaskId = ? and CustAccount = ?" UTF8String];
    sqlite3_stmt *selectstmt;
    
    NSMutableArray *taskTransDates = [NSMutableArray new];
    if (sqlite3_prepare_v2(database, sqlTaskTrans, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [taskID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selectstmt, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(selectstmt) == SQLITE_ROW) {
            NSString *transDate = @"";
            
            if (sqlite3_column_text(selectstmt, 0))
                transDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            [taskTransDates addObject:transDate];
        }
        [taskTransDates sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSDate *date1 = [self.mainDateFormatter dateFromString:obj1];
            NSDate *date2 = [self.mainDateFormatter dateFromString:obj2];
            return [date2 compare: date1];
        }];
    }
    sqlite3_finalize(selectstmt);
    
    return taskTransDates.firstObject;
}

- (NSString *)lineDescriptionForTaskID:(NSString *)taskID result:(NSString *)result {
    const char *sqlTaskList = [@"select LineDescription from TaskList where TaskId = ? and LineId = ?" UTF8String];
    sqlite3_stmt *selectstmt;
    
    NSString *lineDescription = @"Не выбрано";
    if (sqlite3_prepare_v2(database, sqlTaskList, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [taskID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selectstmt, 2, [result UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectstmt) == SQLITE_ROW) {
            if (sqlite3_column_text(selectstmt, 0))
                lineDescription  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
        }
    }
    sqlite3_finalize(selectstmt);
    
    return lineDescription;
}

- (NSInteger)getCustomersInRouteCountForDate:(NSString *)dateStr {
    NSInteger custInRouteCount = 0;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select count(*) from CustForRoute where DateOfRoute = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [dateStr UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW )
                custInRouteCount = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return custInRouteCount;
}

- (void)addCustomerToRoute:(NSDictionary *)customer date:(NSString *)dateString {
    NSInteger customersInRouteCount = [self getCustomersInRouteCountForDate:dateString];
    
    NSString *strLineNum = [NSString stringWithFormat:@"%li", (long)customersInRouteCount];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *addStmt;
        
        const char *sql = "insert or ignore into CustForRoute (CustAccount, DateOfRoute, RegularRoute, CustName, GPSPoint, lineNum, GPSRequest) Values(?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [customer[@"custAccount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [dateString UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [@"No" UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [customer[@"custName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [customer[@"gpsPoint"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
        
        PutClientForRouteRequest *putClientForRoute = [[PutClientForRouteRequest alloc] init];
        putClientForRoute.custAccount = customer[@"custAccount"];
        putClientForRoute.date = dateString;
        putClientForRoute.custAddress = customer[@"gpsPoint"];
        putClientForRoute.custName = customer[@"custName"];
        putClientForRoute.forDelete = NO;
        putClientForRoute.notShowProgress = YES;
        [putClientForRoute sendCust];
        
        NSMutableDictionary *mutableCustomer = customer.mutableCopy;
        mutableCustomer[@"isInRoute"] = [NSNumber numberWithBool:YES];
        NSUInteger searchIndex = [self.taskCustomersArray indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj[@"custAccount"] isEqual:customer[@"custAccount"]];
        }];
        
        if (searchIndex != NSNotFound) {
            [self.taskCustomersArray replaceObjectAtIndex:searchIndex withObject:mutableCustomer];
        }
        
        [self applyFilters];
        
        [AlertWorkerObjc alertWithTitle:@"Маршрут" message:[NSString stringWithFormat:@"Клиент %@ добавлен в маршрут на %@", customer[@"custName"], dateString] acceptMessage:@"OK" acceptBlock:^{
            if ([self.delegate respondsToSelector:@selector(userDidAddCustomersToRoute: date:)]) {
                [self.delegate userDidAddCustomersToRoute:@[customer] date:[self.mainDateFormatter dateFromString:dateString]];
            }
        }];

    }
    sqlite3_close(database);
}

#pragma mark - Helpers
- (void)applyFilters {
    NSString *searchText = self.mainSearchBar.text;
    
    self.dataSource = [self.taskCustomersArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        BOOL regionFilter = YES;
        if (self.selectedRegionsArray.count > 0) {
            regionFilter = [self.selectedRegionsArray containsObject:object[@"city"]];
        }
        
        BOOL statusFilter = YES;
        if (self.selectedStatusesArray.count > 0) {
            statusFilter = [self.selectedStatusesArray containsObject:object[@"status"]];
        }
        
        BOOL sourceFilter = YES;
        if (self.selectedSourcesArray.count > 0) {
            NSString *source = [NSString stringWithFormat:@"Назначено %@", object[@"source"]];
            if (![object[@"from1C"] isEqualToString:@"1"]) {
                source = @"Собственная";
            }
            sourceFilter = [self.selectedSourcesArray containsObject:source];
        }
        
        BOOL routeFilter = YES;
        if (self.isRouteSelected) {
            routeFilter = [object[@"isInRoute"] boolValue];
        }
        
        BOOL searchFilter = YES;
        if (searchText.length > 0) {
            NSString *custName = object[@"custName"];
            NSString *startDate = object[@"startDate"];
            NSString *endDate = object[@"endDate"];
            searchFilter = [custName localizedStandardContainsString:searchText]
            || [startDate localizedStandardContainsString:searchText]
            || [endDate localizedStandardContainsString:searchText];
        }
        
        return regionFilter && statusFilter && routeFilter && sourceFilter && searchFilter;
    }]];
    
    [self.mainTableView reloadData];
}

- (void)showActionSheetFrom:(UIView *)sourceView forCustomer:(NSDictionary *)customer {
    NSMutableArray *buttonsArray = [NSMutableArray arrayWithArray:@[@"Карточка клиента", @"Задача", @"Отмена"]];
    if ([customer[@"visit"] isEqualToString:@"0"] && ![customer[@"isInRoute"] boolValue]) {
        buttonsArray = @[@"Карточка клиента", @"Задача", @"Добавить в маршрут", @"Отмена"].mutableCopy;
    } else if ([customer[@"visit"] isEqualToString:@"1"] && ![customer[@"isVisitInRoute"] boolValue]) {
        if ([customer[@"isInRoute"] boolValue]) {
            buttonsArray = @[@"Карточка клиента", @"Отмена"].mutableCopy;
        } else {
            buttonsArray = @[@"Добавить в маршрут", @"Карточка клиента", @"Отмена"].mutableCopy;
        }
    }
    
    [AlertWorkerObjc actionSheetWithTitle:customer[@"custAccount"] message:nil sourceView:sourceView buttons:buttonsArray isLastButtonCancel:YES permittedArrowDirections:UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if ([action.title isEqual:@"Карточка клиента"]) {
            [NavigationWorker openCustomerDetails:customer[@"custAccount"]];
        } else if ([action.title isEqual:@"Задача"]) {
            TaskTransViewController *taskTransVC = [[TaskTransViewController alloc] initWithNibName:@"TaskTransViewController" bundle:nil];
            taskTransVC.isViewPushed = NO;
            taskTransVC.custAccount = customer[@"custAccount"];
            taskTransVC.custName = customer[@"custName"];
            taskTransVC.taskId = self.selectedTask[@"taskID"];
            taskTransVC.taskName = self.selectedTask[@"taskName"];
            taskTransVC.status = customer[@"status"];
            taskTransVC.typeOfResult = customer[@"typeOfResult"];
            taskTransVC.result = customer[@"result"];
            taskTransVC.dateEnd = customer[@"endDate"];
            
            UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:taskTransVC];
            navVC.modalPresentationStyle = UIModalPresentationFormSheet;
            
            [self.navigationController presentViewController:navVC animated:YES completion:nil];
        } else if ([action.title isEqual:@"Добавить в маршрут"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [AlertWorkerObjc alertWithTitle:@"Добавить в маршрут:" message:nil buttons:@[@"Текущий", @"Выбрать дату", @"Отмена"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
                    if (index == 0) {
                        NSString *nowDateString = [self.mainDateFormatter stringFromDate:NSDate.date];
                        [self addCustomerToRoute:customer date:nowDateString];
                    } else if (index == 1) {
                        self.customerToAddToRoute = customer;
                        [self showDatePicker:sourceView];
                    }
                }];
            });
        }
    }];
}

- (void)showDatePicker:(UIView *)sourceView {
    ASPDatePickerViewController *datePickerVC = [ASPDatePickerViewController new];
    datePickerVC.delegate = self;
    datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
    datePickerVC.popoverPresentationController.sourceView = sourceView;
    datePickerVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    [self presentViewController:datePickerVC animated:YES completion:nil];
    [datePickerVC setMinimumDate:NSDate.date];
}

@end
