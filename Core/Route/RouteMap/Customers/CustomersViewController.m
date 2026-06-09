//
//  CustomersViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 20.04.2022.
//

#import "CustomersViewController.h"

//DataWorkers
#import "sqlite3.h"

//VCs
#import "CustCity.h"
#import "CustDream.h"
#import "CustBrand.h"
#import "CustStatusDN.h"
#import "CustomerTypesTableViewController.h"
#import "MapViewController.h"

#import "ASPDatePickerViewController.h"

//Cells
#import "CustomerTableViewCell.h"

#import "GeneratedAssetSymbols.h"

typedef NS_ENUM(NSUInteger, SortType) {
    SortTypeOrderDateAsc = 0,
    SortTypeOrderDateDesc = 1,
    SortTypeVisitDateAsc = 2,
    SortTypeVisitDateDesc = 3,
    SortTypeDefault = 4
};

//UI Constants
static const CGFloat kEstimatedCustomerCellHeight = 60.0;

@interface CustomersViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, ASPDatePickerViewControllerDelegate, CustCityDelegate, CustDreamDelegate, CustBrandDelegate, CustStatusDNDelegate, CustomerTypesTableViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *mainTableView;

//Buttons
@property (nonatomic, weak) IBOutlet UIButton *editButton;
@property (nonatomic, weak) IBOutlet UIButton *regionButton;
@property (nonatomic, weak) IBOutlet UIButton *statusButton;
@property (nonatomic, weak) IBOutlet UIButton *markButton;
@property (nonatomic, weak) IBOutlet UIButton *brandStatusDNButton;
@property (nonatomic, weak) IBOutlet UIButton *customerTypeButton;

@property (nonatomic, strong) UISearchBar *mainSearchBar;

@property (nonatomic, strong) NSDateFormatter *mainDateFormatter;

@property (nonatomic, strong) NSMutableArray *customers;
@property (nonatomic, strong) NSArray *dataSource;

@property (nonatomic, strong) NSMutableArray *selectedCustomers;
@property (nonatomic, strong) NSDictionary *customerToAddToRoute;

//Filters
@property (nonatomic, strong) NSArray *regionFilters;
@property (nonatomic, strong) NSArray *statusFilters;
@property (nonatomic, strong) NSArray *markFilters;
@property (nonatomic, strong) NSArray *brandStatusDNFilters;
@property (nonatomic, strong) NSArray *customerTypeFilters;
@property (nonatomic, assign) BOOL applyPDZFilter;
@property (nonatomic, assign) BOOL applyOrderFilter;
@property (nonatomic, assign) BOOL applyVisitFilter;

@property (nonatomic, assign) SortType sortType;

@end

static sqlite3 *database = nil;

@implementation CustomersViewController {
    NSIndexPath *_swipedRowIndexPath;
}

#pragma mark - Life Cycle
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self turnOnKeyboardTracking:YES];
    
    [self prepareCustomers];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.mainSearchBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.mainSearchBar.hidden = YES;
    
    [self.mainSearchBar resignFirstResponder];
    [self turnOnKeyboardTracking:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self setupUI];
}

#pragma mark - UI Setup
- (void)setupNavBar {
    if (self.navigationController) {
        self.navigationItem.title = @"Клиенты";
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self  action:@selector(doneButtonTapped)];
        self.navigationItem.rightBarButtonItem = doneButton;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)setupUI {
    self.mainDateFormatter = NSDateFormatter.new;
    self.mainDateFormatter.defaultDate = NSDate.date;
    self.mainDateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    
    self.selectedCustomers = [NSMutableArray new];
    
    self.sortType = SortTypeDefault;
    self.mainAcc = LocalAuthWorker.login;
    
    self.mainSearchBar = [UISearchBar new];
    self.mainSearchBar.barTintColor = UIColor.whiteColor;
    self.mainSearchBar.backgroundImage = [UIImage new];
    self.mainSearchBar.delegate = self;
    self.mainSearchBar.hidden = YES;
    self.mainSearchBar.placeholder = @"Поиск";
    self.mainSearchBar.searchTextField.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F7"];
    self.mainSearchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.navigationController.navigationBar addSubview:self.mainSearchBar];
    
    //Constants
    CGFloat searchBarWidthMultiplier = 0.27;
    [NSLayoutConstraint activateConstraints:@[
        //MainSearchBar
        [self.mainSearchBar.widthAnchor constraintEqualToAnchor:self.navigationController.navigationBar.widthAnchor multiplier:searchBarWidthMultiplier],
        [self.mainSearchBar.heightAnchor constraintEqualToAnchor:self.navigationController.navigationBar.heightAnchor],
        [NSLayoutConstraint constraintWithItem:self.mainSearchBar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.navigationController.navigationBar attribute:NSLayoutAttributeCenterX multiplier:1.5 constant:1.0],
        [self.mainSearchBar.centerYAnchor constraintEqualToAnchor:self.navigationController.navigationBar.centerYAnchor]
    ]];
}

#pragma mark - PrepareData
- (void)prepareCustomers {
    [SVProgressHUD showWithStatus:@"Загрузка списка клиентов"];
    
    [self.mainSearchBar resignFirstResponder];
    
    NSNumber *isCurrentAcc = [NSNumber numberWithBool:[self.currentAcc isEqualToString:self.mainAcc]];
    self.customers = [NSMutableArray new];
    NSMutableArray *mutableCustomersInRoute = [NSMutableArray arrayWithArray:self.customersInRoute];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            const char *sql = "select distinct CustTable.CustAccount, CustTable.Name, CustTable.FactAddress, CustTable.City, CustTable.SendStatus, CustTable.PDZAmount, CustTable.Phone, CustTable.AdditionalCust, CustTable.GPSPoint, CustTable.Property6, CustStatusDN.StatusDN, CustTable.LastVisitDate, CustTable.SalesDate from CustTable INNER JOIN CustStatusDN ON CustTable.CustAccount = CustStatusDN.CustAccount where 1=1";
            sqlite3_stmt *selectstmt;
            
            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                    NSMutableDictionary *customer = [NSMutableDictionary new];
                    
                    NSString *custAccount;
                    NSString *custName;
                    NSString *factAddress;
                    NSString *city;
                    NSString *sendStatus;
                    NSString *pdzAmount;
                    NSString *phone;
                    NSString *additionalCust;
                    NSString *gpsPoint;
                    NSString *property6;
                    NSString *statusDN;
                    NSString *lastVisitDate;
                    NSString *salesDate;
                    
                    if (sqlite3_column_text(selectstmt, 0))
                        custAccount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    if (sqlite3_column_text(selectstmt, 1))
                        custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                    if (sqlite3_column_text(selectstmt, 2))
                        factAddress = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                    if (sqlite3_column_text(selectstmt, 3))
                        city = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                    if (sqlite3_column_text(selectstmt, 4))
                        sendStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                    if (sqlite3_column_text(selectstmt, 5))
                        pdzAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                    if (sqlite3_column_text(selectstmt, 6))
                        phone = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                    if (sqlite3_column_text(selectstmt, 7))
                        additionalCust = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                    if (sqlite3_column_text(selectstmt, 8))
                        gpsPoint = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                    if (sqlite3_column_text(selectstmt, 9))
                        property6 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                    if (sqlite3_column_text(selectstmt, 10))
                        statusDN = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                    if (sqlite3_column_text(selectstmt, 11))
                        lastVisitDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                    if (sqlite3_column_text(selectstmt, 12))
                        salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 12)];
                    
                    customer[@"custAccount"] = custAccount;
                    customer[@"custName"] = custName;
                    customer[@"factAddress"] = factAddress;
                    customer[@"city"] = city;
                    customer[@"sendStatus"] = sendStatus;
                    customer[@"pdzAmount"] = pdzAmount;
                    customer[@"phone"] = phone;
                    customer[@"additionalCust"] = additionalCust;
                    customer[@"gpsPoint"] = gpsPoint;
                    customer[@"property6"] = property6;
                    customer[@"statusDN"] = statusDN;
                    
                    if (lastVisitDate) {
                        customer[@"lastVisitDate"] = lastVisitDate;
                        customer[@"lastVisitDateObject"] = [self.mainDateFormatter dateFromString:lastVisitDate];
                    }
                    
                    if (salesDate) {
                        customer[@"salesDate"] = salesDate;
                        customer[@"salesDateObject"] = [self.mainDateFormatter dateFromString:salesDate];
                    }
                    
                    if (mutableCustomersInRoute.count > 0) {
                        NSUInteger searchIndex = [mutableCustomersInRoute indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            return [custAccount isEqual:obj[@"custAccount"]] && [obj[@"managerIDs"] containsObject:self.mainAcc];
                        }];
                        
                        if (searchIndex != NSNotFound) {
                            customer[@"status"] = mutableCustomersInRoute[searchIndex][@"status"];
                            customer[@"regularRoute"] = mutableCustomersInRoute[searchIndex][@"regularRoute"];
                            customer[@"managerIDs"] = mutableCustomersInRoute[searchIndex][@"managerIDs"];
                            [mutableCustomersInRoute removeObjectAtIndex:searchIndex];
                        }
                    }
                    
                    customer[@"tasksCount"] = [self tasksCount:custAccount];
                    customer[@"brands"] = [self brands:custAccount];
                    customer[@"isCurrentAcc"] = isCurrentAcc;
                    
                    [self.customers addObject:customer];
                }
            }
            sqlite3_finalize(selectstmt);
        }
        sqlite3_close(database);
        
        if (self.selectedManager) {
            [self getSubAccountCustomers];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^() {
                [self applyFilters];
                [self applySort];
                [SVProgressHUD dismiss];
            });
        }
    });
}

- (void)getSubAccountCustomers {
    NSString *subAcc = self.selectedManager[@"id"];
    if (!subAcc) { return; }
    
    NSNumber *isCurrentAcc = [NSNumber numberWithBool:[self.currentAcc isEqualToString:subAcc]];
    NSMutableArray *mutableCustomersInRoute = [NSMutableArray arrayWithArray:self.customersInRoute];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select distinct CustAccount, Name, FactAddress, City, SendStatus, PDZAmount, Phone, AdditionalCust, GPSPoint, Property6, LastVisitDate, SalesDate from tmpCustTable";
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *customer = [NSMutableDictionary new];
                
                NSString *custAccount;
                NSString *custName;
                NSString *factAddress;
                NSString *city;
                NSString *sendStatus;
                NSString *pdzAmount;
                NSString *phone;
                NSString *additionalCust;
                NSString *gpsPoint;
                NSString *property6;
                NSString *lastVisitDate;
                NSString *salesDate;
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAccount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                if (sqlite3_column_text(selectstmt, 1))
                    custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                if (sqlite3_column_text(selectstmt, 2))
                    factAddress = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                if (sqlite3_column_text(selectstmt, 3))
                    city = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                if (sqlite3_column_text(selectstmt, 4))
                    sendStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                if (sqlite3_column_text(selectstmt, 5))
                    pdzAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                if (sqlite3_column_text(selectstmt, 6))
                    phone = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                if (sqlite3_column_text(selectstmt, 7))
                    additionalCust = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                if (sqlite3_column_text(selectstmt, 8))
                    gpsPoint = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                if (sqlite3_column_text(selectstmt, 9))
                    property6 = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                if (sqlite3_column_text(selectstmt, 10))
                    lastVisitDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                if (sqlite3_column_text(selectstmt, 11))
                    salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                customer[@"custAccount"] = custAccount;
                customer[@"custName"] = custName;
                customer[@"factAddress"] = factAddress;
                customer[@"city"] = city;
                customer[@"sendStatus"] = sendStatus;
                customer[@"pdzAmount"] = pdzAmount;
                customer[@"phone"] = phone;
                customer[@"additionalCust"] = additionalCust;
                customer[@"gpsPoint"] = gpsPoint;
                customer[@"property6"] = property6;
                
                if (lastVisitDate) {
                    customer[@"lastVisitDate"] = lastVisitDate;
                    customer[@"lastVisitDateObject"] = [self.mainDateFormatter dateFromString:lastVisitDate];
                }
                
                if (salesDate) {
                    customer[@"salesDate"] = salesDate;
                    customer[@"salesDateObject"] = [self.mainDateFormatter dateFromString:salesDate];
                }
                
                if (mutableCustomersInRoute.count > 0) {
                    NSUInteger searchIndex = [mutableCustomersInRoute indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        return [custAccount isEqual:obj[@"custAccount"]] && [obj[@"managerIDs"] containsObject:subAcc];
                    }];
                    
                    if (searchIndex != NSNotFound) {
                        customer[@"status"] = mutableCustomersInRoute[searchIndex][@"status"];
                        customer[@"regularRoute"] = mutableCustomersInRoute[searchIndex][@"regularRoute"];
                        customer[@"managerIDs"] = mutableCustomersInRoute[searchIndex][@"managerIDs"];
                        [mutableCustomersInRoute removeObjectAtIndex:searchIndex];
                    }
                }
                
                customer[@"isCurrentAcc"] = isCurrentAcc;
                
                [self.customers addObject:customer];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self applyFilters];
        [self applySort];
        [SVProgressHUD dismiss];
    });
}

- (NSNumber *)tasksCount:(NSString *)custAcc {
    //Selecting Tasks count
    const char *sql = "select count(TaskId) from TaskTable where CustAccount = ? and (Status = 'Открытая' or Status = 'В работе')";
    sqlite3_stmt *selectstmt;
    
    NSNumber *tasksCount;
    if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectstmt) == SQLITE_ROW) {
            if (sqlite3_column_text(selectstmt, 0)) {
                tasksCount = @(sqlite3_column_int(selectstmt, 0));
            }
        }
    }
    sqlite3_finalize(selectstmt);
    
    return tasksCount;
}

- (NSArray *)brands:(NSString *)custAcc {
    //Selecting Brands
    const char *sql = "select PersonalPriceList.BrandId, CustStatusDNBrand.Status from PersonalPriceList JOIN CustStatusDNBrand on PersonalPriceList.CustAccount == CustStatusDNBrand.CustAccount and PersonalPriceList.BrandId == CustStatusDNBrand.BrandID where PersonalPriceList.CustAccount = ? and PersonalPriceList.Active = '1'";
    sqlite3_stmt *selectstmt;
    
    NSMutableArray *brands = [NSMutableArray new];
    if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selectstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
        
        while (sqlite3_step(selectstmt) == SQLITE_ROW) {
            NSMutableDictionary *brandObject = [NSMutableDictionary new];
            
            NSString *brandID;
            NSString *brandStatusDN;
            
            if (sqlite3_column_text(selectstmt, 0))
                brandID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            
            if (sqlite3_column_text(selectstmt, 1))
                brandStatusDN = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
            
            brandObject[@"brandID"] = brandID;
            brandObject[@"brandStatusDN"] = brandStatusDN;
            [brands addObject:brandObject];
        }
    }
    sqlite3_finalize(selectstmt);
    
    return brands;
}

#pragma mark - Button Actions
- (void)doneButtonTapped {
    [self addCustomersToRoute:self.selectedDate];
}

- (IBAction)editButtonTapped:(id)sender {
    [self.mainTableView setEditing:!self.mainTableView.isEditing animated:YES];
    [self.editButton setTitle:self.mainTableView.isEditing ? @"Отменить" : @"Выбрать" forState:UIControlStateNormal];
    
    if (self.mainTableView.isEditing) {
        [self.selectedCustomers removeAllObjects];
    }
}

- (IBAction)regionButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    CustCity *chooseRegionVC = [CustCity new];
    chooseRegionVC.delegate = self;
    chooseRegionVC.selected = self.regionFilters.mutableCopy;
    
    [self presentPopover:chooseRegionVC sourceView:sender];
}

- (IBAction)statusButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    CustDream *chooseStatusVC = [CustDream new];
    chooseStatusVC.delegate = self;
    chooseStatusVC.selected = self.statusFilters.mutableCopy;
    
    [self presentPopover:chooseStatusVC sourceView:sender];
}

- (IBAction)markButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    CustBrand *chooseMarkVC = [CustBrand new];
    chooseMarkVC.delegate = self;
    chooseMarkVC.selected = self.markFilters.mutableCopy;
    
    [self presentPopover:chooseMarkVC sourceView:sender];
}

- (IBAction)brandStatusDNButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    CustStatusDN *custStatusDNVC = [CustStatusDN new];
    custStatusDNVC.delegate = self;
    custStatusDNVC.selected = self.brandStatusDNFilters.mutableCopy;
    
    [self presentPopover:custStatusDNVC sourceView:sender];
}

- (IBAction)customerTypeButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    CustomerTypesTableViewController *chooseCustTypeVC = [CustomerTypesTableViewController new];
    chooseCustTypeVC.delegate = self;
    chooseCustTypeVC.selectedTypesArray = self.customerTypeFilters.mutableCopy;
    
    [self presentPopover:chooseCustTypeVC sourceView:sender];
}

- (IBAction)PDZButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    self.applyPDZFilter = !self.applyPDZFilter;
    [self applyFilters];
    [self setButton:sender highlighted:self.applyPDZFilter];
}

- (IBAction)orderButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    self.applyOrderFilter = !self.applyOrderFilter;
    [self applyFilters];
    [self setButton:sender highlighted:self.applyOrderFilter];
}

- (IBAction)visitButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    self.applyVisitFilter = !self.applyVisitFilter;
    [self applyFilters];
    [self setButton:sender highlighted:self.applyVisitFilter];
}

- (IBAction)sortButtonTapped:(UIButton *)sender {
    [self.mainSearchBar resignFirstResponder];
    
    NSMutableArray *buttons = [self sortTypeTitles].mutableCopy;
    [buttons removeObjectAtIndex:self.sortType];
    [AlertWorkerObjc actionSheetWithTitle:@"Сортировка" message:nil sourceView:sender buttons:buttons tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index < buttons.count - 1) {
            NSInteger index = [[self sortTypeTitles] indexOfObject:action.title];
            self.sortType = index;
            [self applySort];
        }
    }];
}

#pragma mark - CustCityDelegate
- (void)userDidSelectCities:(NSMutableArray *)cities {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.regionFilters = cities;
    [self applyFilters];
    [self setButton:self.regionButton highlighted:self.regionFilters.count > 0];
}

#pragma mark - CustDreamDelegate
- (void)userDidSelectDream:(NSMutableArray *)dreamArray {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.statusFilters = dreamArray;
    [self applyFilters];
    [self setButton:self.statusButton highlighted:self.statusFilters.count > 0];
}

#pragma mark - CustBrandDelegate
- (void)userDidSelectBrand:(NSMutableArray *)brandArray {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.markFilters = brandArray;
    [self applyFilters];
    [self setButton:self.markButton highlighted:self.markFilters.count > 0];
    
    self.brandStatusDNFilters = nil;
    self.brandStatusDNButton.enabled = self.markFilters.count == 1;
    [self setButton:self.brandStatusDNButton highlighted:self.brandStatusDNFilters.count > 0];
}

#pragma mark - CustStatusDNDelegate
- (void)userDidSelectStatusDN:(NSMutableArray *)statusDNArray {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.brandStatusDNFilters = statusDNArray;
    [self applyFilters];
    [self setButton:self.brandStatusDNButton highlighted:self.brandStatusDNFilters.count > 0];
}

#pragma mark - CustomerTypesTableViewControllerDelegate
- (void)userDidSelectCustomerTypes:(NSArray *)selectedTypes {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.customerTypeFilters = selectedTypes;
    [self applyFilters];
    [self setButton:self.customerTypeButton highlighted:self.customerTypeFilters.count > 0];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([CustomerTableViewCell class]) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.row];
    
    NSString *custName = object[@"custName"];
    if (object[@"pdzAmount"] && ![object[@"pdzAmount"] isEqual:@"0"]) {
        custName = [NSString stringWithFormat:@"❗%@", custName];
    }
    cell.lblName.text = custName;
    cell.lblAddress.text = object[@"factAddress"];
    
    [cell setCustomerInRouteStatus:object[@"status"]];
    
    if ([object[@"lastVisitDate"] length] > 0) {
        cell.lblLastVisitDate.text = [NSString stringWithFormat:@"Последний визит %@", object[@"lastVisitDate"]];
    } else {
        cell.lblLastVisitDate.text = nil;
    }
    
    if ([object[@"salesDate"] length] > 0) {
        cell.lblLastOrderDate.text = [NSString stringWithFormat:@"Последний заказ %@", object[@"salesDate"]];
    } else {
        cell.lblLastOrderDate.text = nil;
    }
    
    NSInteger tasksCount = [object[@"tasksCount"] integerValue];
    if (tasksCount > 0) {
        cell.lblTasksCount.text = [NSString stringWithFormat:@"Задачи: %ld", (long)tasksCount];
    } else {
        cell.lblTasksCount.text = nil;
    }
    
    if ([object[@"isCurrentAcc"] boolValue]) {
        cell.contentView.alpha = 1.0;
        cell.userInteractionEnabled = YES;
    } else {
        cell.contentView.alpha = 0.5;
        cell.userInteractionEnabled = NO;
    }
    
    if (object[@"managerIDs"]) {
        if ([object[@"managerIDs"] containsObject:self.mainAcc]) {
            cell.managerInfoImageView.image = [UIImage imageNamed:ACImageNameCommonCustomerInRoute];
            cell.managerInfoImageView.hidden = [object[@"managerIDs"] count] < 2;
        } else {
            cell.managerInfoImageView.image = [UIImage imageNamed:ACImageNameConnectedManager];
            cell.managerInfoImageView.hidden = NO;
        }
    } else {
        cell.managerInfoImageView.hidden = YES;
    }
    
    if ([self.selectedCustomers containsObject:object]) {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.dataSource[indexPath.row];
    return [object[@"isCurrentAcc"] boolValue];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kEstimatedCustomerCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.dataSource[indexPath.row];
    if (tableView.isEditing) {
        if (![self.selectedCustomers containsObject:object]) {
            [self.selectedCustomers addObject:object];
            self.navigationItem.rightBarButtonItem.enabled = self.selectedCustomers.count > 0;
        }
    } else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self showActions:object sourceView:cell];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        });
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        NSDictionary *object = self.dataSource[indexPath.row];
        if ([self.selectedCustomers containsObject:object]) {
            [self.selectedCustomers removeObject:object];
            self.navigationItem.rightBarButtonItem.enabled = self.selectedCustomers.count > 0;
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.dataSource[indexPath.row];
    
    NSMutableArray *swipeActions = [NSMutableArray new];
    if (object[@"status"]) {
        if (![object[@"regularRoute"] isEqual:@"Yes"] && ![object[@"status"] isEqual:@"visited"]) {
            UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completion)(BOOL)) {
                [self.selectedCustomers addObject:object];
                [self removeCustomersFromRoute];
                completion(YES);
            }];
            removeAction.backgroundColor = [ASPFunctions colorFromHex:@"EB5757"];
            removeAction.image = [UIImage imageNamed:ACImageNameRemoveCust];
            [swipeActions addObject:removeAction];
        }
    } else {
        UIContextualAction *addAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completion)(BOOL)) {
            [self showRouteDatePicker:object sourceView:sourceView];
            completion(YES);
        }];
        addAction.backgroundColor = [ASPFunctions colorFromHex:@"27AE60"];
        addAction.image = [UIImage imageNamed:ACImageNameAdd];
        [swipeActions addObject:addAction];
    }
    
    UIContextualAction *customerInfoAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completion)(BOOL)) {
        [self openCustomerDetails:object];
        completion(YES);
    }];
    customerInfoAction.backgroundColor = [UIColor colorNamed:ACColorNameMLKBlue];
    customerInfoAction.image = [UIImage imageNamed:ACImageNameInfo];
    [swipeActions addObject:customerInfoAction];
    
    UIContextualAction *onMapAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completion)(BOOL)) {
        [self showCustomerOnMap:object];
        completion(YES);
    }];
    onMapAction.backgroundColor = [ASPFunctions colorFromHex:@"F2994A"];
    onMapAction.image = [UIImage imageNamed:ACImageNameOnMap];
    [swipeActions addObject:onMapAction];
    
    UISwipeActionsConfiguration *swipeActionConfig = [UISwipeActionsConfiguration configurationWithActions:swipeActions];
    swipeActionConfig.performsFirstActionWithFullSwipe = NO;
    
    return swipeActionConfig;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    _swipedRowIndexPath = indexPath;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    _swipedRowIndexPath = nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    if (_swipedRowIndexPath) {
        self.view.userInteractionEnabled = NO;
        [tableView setEditing:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.view.userInteractionEnabled = YES;
        });
    } else {
        [self.editButton setTitle:@"Отменить" forState:UIControlStateNormal];
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
    [self applyFilters];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [self applyFilters];
}

#pragma mark - Helpers
- (void)applyFilters {
    NSString *searchText = self.mainSearchBar.text;
    
    self.dataSource = [self.customers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable object, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        BOOL regionFilterFlag = YES;
        if (self.regionFilters.count > 0) {
            regionFilterFlag = [self.regionFilters containsObject:object[@"city"]];
        }
        
        BOOL statusFilterFlag = YES;
        if (self.statusFilters.count > 0) {
            statusFilterFlag = [self.statusFilters containsObject:object[@"statusDN"]];
        }
        
        BOOL markFilterFlag = YES;
        if (self.markFilters.count > 0) {
            markFilterFlag = NO;
            NSArray *objectBrands = object[@"brands"];
            for (NSString *markFilter in self.markFilters) {
                id searchObject = [ASPFunctions firstObjectInArray:objectBrands where:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    BOOL brandStatusDNFlag = YES;
                    if (self.brandStatusDNFilters.count > 0) {
                        NSString *brandStatusDN = obj[@"brandStatusDN"];
                        brandStatusDNFlag = [self.brandStatusDNFilters containsObject:brandStatusDN];
                    }
                    
                    return [markFilter isEqualToString:obj[@"brandID"]] && brandStatusDNFlag;
                }];
                
                if (searchObject) {
                    markFilterFlag = YES;
                    break;
                }
            }
        }
        
        BOOL customerTypeFilterFlag = YES;
        if (self.customerTypeFilters.count > 0) {
            id searchObject = [ASPFunctions firstObjectInArray:self.customerTypeFilters where:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj[@"property6"] isEqual:object[@"property6"]];
            }];
            
            customerTypeFilterFlag = searchObject != nil;
        }
        
        BOOL pdzFilterFlag = YES;
        if (self.applyPDZFilter) {
            pdzFilterFlag = object[@"pdzAmount"] && ![object[@"pdzAmount"] isEqual:@"0"];
        }
        
        BOOL orderFilterFlag = YES;
        if (self.applyOrderFilter) {
            orderFilterFlag = object[@"salesDateObject"];
        }
        
        BOOL visitFilterFlag = YES;
        if (self.applyVisitFilter) {
            visitFilterFlag = object[@"lastVisitDateObject"];
        }
        
        BOOL searchFilterFlag = YES;
        if (searchText.length > 0) {
            NSString *custName = object[@"custName"];
            NSString *factAddress = object[@"factAddress"];
            searchFilterFlag = [custName localizedStandardContainsString:searchText]
            || [factAddress localizedStandardContainsString:searchText];
        }
        
        return regionFilterFlag && statusFilterFlag && markFilterFlag && customerTypeFilterFlag && pdzFilterFlag && orderFilterFlag && visitFilterFlag && searchFilterFlag;
    }]];
    
    [self applySort];
}

- (void)applySort {
    self.dataSource = [self.dataSource sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        if (self.sortType < 4) {
            NSDate *firstObjectDate = self.sortType < 2 ? obj1[@"salesDateObject"] : obj1[@"lastVisitDateObject"];
            NSDate *secondObjectDate = self.sortType < 2 ? obj2[@"salesDateObject"] : obj2[@"lastVisitDateObject"];
            
            NSComparisonResult targetResult = self.sortType % 2 == 0 ? NSOrderedDescending : NSOrderedAscending;
            if (!firstObjectDate) {
                return targetResult == NSOrderedAscending;
            } else if (!secondObjectDate) {
                return targetResult == NSOrderedDescending;
            } else {
                return [firstObjectDate compare:secondObjectDate] == targetResult;
            }
        }
        
        return [obj1[@"custName"] localizedStandardCompare: obj2[@"custName"]];
    }];
    
    [self.mainTableView reloadData];
}

- (void)presentPopover:(UIViewController *)popover sourceView:(UIView *)sourceView{
    popover.modalPresentationStyle = UIModalPresentationPopover;
    popover.popoverPresentationController.sourceView = sourceView;
    
    [self presentViewController:popover animated:YES completion:nil];
}

#pragma mark - Button styling methods
- (void)setButton:(UIButton *)button highlighted:(BOOL)highlighted {
    UIColor *titleColor = highlighted ? UIColor.whiteColor : [UIColor colorNamed:ACColorNameMLKBlue];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    
    UIColor *backgroundColor = highlighted ? [UIColor colorNamed:ACColorNameMLKLightBlue] : UIColor.whiteColor;
    button.backgroundColor = backgroundColor;
}

#pragma mark - Actions
- (void)showActions:(NSDictionary *)customer sourceView:(UIView *)sourceView {
    NSMutableArray *alertActions = [NSMutableArray new];
    if (customer[@"status"]) {
        if (![customer[@"regularRoute"] isEqual:@"Yes"] && ![customer[@"status"] isEqual:@"visited"]) {
            UIAlertAction *removeAction = [UIAlertAction actionWithTitle:@"Убрать из маршрута" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self.selectedCustomers addObject:customer];
                [self removeCustomersFromRoute];
            }];
            [alertActions addObject:removeAction];
        }
    } else {
        UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"Добавить в маршрут" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showRouteDatePicker:customer sourceView:sourceView];
        }];
        [alertActions addObject:addAction];
    }
    
    UIAlertAction *customerInfoAction = [UIAlertAction actionWithTitle:@"Карточка клиента" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openCustomerDetails:customer];
    }];
    [alertActions addObject:customerInfoAction];
    
    UIAlertAction *onMapAction = [UIAlertAction actionWithTitle:@"Показать на карте" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showCustomerOnMap:customer];
    }];
    [alertActions addObject:onMapAction];
    
    [AlertWorkerObjc actionSheetWithTitle:nil message:nil sourceView:sourceView actions:alertActions];
}

- (void)showRouteDatePicker:(NSDictionary *)customer sourceView:(UIView *)sourceView {
    self.customerToAddToRoute = customer;
    
    ASPDatePickerViewController *datePickerVC = [ASPDatePickerViewController new];
    datePickerVC.delegate = self;
    datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
    datePickerVC.popoverPresentationController.sourceView = sourceView;
    datePickerVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    [self presentViewController:datePickerVC animated:YES completion:nil];
    [datePickerVC setMinimumDate:NSDate.date];
}

- (void)addCustomersToRoute:(NSDate *)date {
    if ([self.delegate respondsToSelector:@selector(userDidAddCustomersToRoute:date:)]) {
        [self.delegate userDidAddCustomersToRoute:self.selectedCustomers date:date];
    }
}

- (void)removeCustomersFromRoute {
    if ([self.delegate respondsToSelector:@selector(userDidRemoveCustomersFromRoute:)]) {
        [self.delegate userDidRemoveCustomersFromRoute:self.selectedCustomers];
    }
}

- (void)openCustomerDetails:(NSDictionary *)customer {
    [NavigationWorker openCustomerDetails:customer[@"custAccount"]];
}

- (void)showCustomerOnMap:(NSDictionary *)customer {
    MapViewController *customerOnMapVC = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:NSBundle.mainBundle];
    customerOnMapVC.custName = customer[@"custName"];
    customerOnMapVC.custAddr = customer[@"gpsPoint"];
    customerOnMapVC.isViewPushed = NO;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:customerOnMapVC];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.selectedCustomers addObject:self.customerToAddToRoute];
        [self addCustomersToRoute:date];
        self.customerToAddToRoute = nil;
    }];
}

#pragma mark - Keyboard & Textfield Mngmnt
- (void)turnOnKeyboardTracking:(BOOL)isOn {
    if (isOn) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    } else {
        [NSNotificationCenter.defaultCenter removeObserver:self];
    }
}

#pragma mark - Keyboard Methods
//1st Step
- (void)keyboardWillShow:(NSNotification *)notification {
    [self animateKeyboardWithDuration:[[[notification userInfo] objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue] frame:[[[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue] options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue]<<16];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self animateKeyboardWithDuration:[[[notification userInfo] objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue] frame:CGRectZero options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue]<<16];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    [self animateKeyboardWithDuration:[[[notification userInfo] objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue] frame:[[[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue] options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue]<<16];
}

//2nd Step
- (void)animateKeyboardWithDuration:(CGFloat)duration frame:(CGRect)keyboardFrame options:(UIViewAnimationOptions)animOptions {
    [UIView animateWithDuration:duration delay:0 options:(animOptions | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        UIWindow *window = ASPFunctions.mainKeyWindow;
        CGFloat keyboardHeight = keyboardFrame.size.height - window.safeAreaInsets.bottom;
        
        [self updateScrollInsets:keyboardHeight < 0.0 ? 0.0 : keyboardHeight];
    }completion:nil];
}

- (void)updateScrollInsets:(CGFloat)keyboardHeight {
    self.mainTableView.contentInset = UIEdgeInsetsMake(self.mainTableView.contentInset.top, self.mainTableView.contentInset.left, keyboardHeight, self.mainTableView.contentInset.right);
    self.mainTableView.scrollIndicatorInsets = self.mainTableView.contentInset;
}

#pragma mark - ConstData
- (NSArray *)sortTypeTitles {
    return @[@"Заказ по возрастанию", @"Заказ по убыванию", @"Визит по возрастанию", @"Визит по убыванию", @"По умолчанию", @"Отмена"];
}

@end
