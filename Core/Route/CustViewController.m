//
//  CustViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//
//  Modern list UI (UICollectionView list + diffable data source) added 2026.
//  All data/SQL/filter/delegate logic preserved from the legacy implementation.
//

#import "CustViewController.h"
#import "OverlayCustView.h"
#import "NewCustomerViewController.h"
#import "MoreCustViewController.h"
#import "PutClientForRouteRequest.h"
#import "RWBorderedButton.h"
#import "XMLWriter.h"
#import "PutNewCustomerRequest.h"

#import "CustListItem.h"
#import "CustListCollectionViewCell.h"

#import "GeneratedAssetSymbols.h"

const NSInteger SELECTION_INDICATOR_TAG = 54321;

static sqlite3 *database = nil;

static NSString *const kCustListSection = @"clients";

@interface CustViewController () <UISearchBarDelegate, UICollectionViewDelegate, CustListCollectionViewCellDelegate>

@property (nonatomic, strong) UICollectionView *listCollectionView;
@property (nonatomic, strong) UICollectionViewDiffableDataSource<NSString *, CustListItem *> *listDataSource;

@property (nonatomic, strong) UIScrollView *filterScrollView;
@property (nonatomic, strong) UIButton *cityPill;
@property (nonatomic, strong) UIButton *statusPill;
@property (nonatomic, strong) UIButton *markPill;
@property (nonatomic, strong) UIButton *statusDNPill;
@property (nonatomic, strong) UIButton *typePill;
@property (nonatomic, strong) UIButton *pdzPill;
@property (nonatomic, strong) UIButton *salesSortPill;

@property (nonatomic, strong) UIBarButtonItem *totalBarButton;
@property (nonatomic, strong) UIBarButtonItem *planBarButton;
@property (nonatomic, strong) UIBarButtonItem *createBarButton;

@property (nonatomic, strong) NSArray<CustListItem *> *displayItems;

// Brand names for the currently selected mark filter (used to show the last
// order date that actually contains a product of that brand).
@property (nonatomic, strong) NSArray<NSString *> *selectedBrandNames;

@end

@implementation CustViewController {
    PutClientForRouteRequest *lastSend;
}

@synthesize navigationBarTitle;
@synthesize searchBar;
@synthesize custDetList, custList, custAccList, custSendStatusList;
@synthesize selectedDate = _selectedDate;
@synthesize target = _target;
@synthesize action = _action;
@synthesize custForRoute;
@synthesize selectedArray;
@synthesize inPseudoEditMode;
@synthesize selectedImage;
@synthesize unselectedImage;
@synthesize deleteButton;
@synthesize toolbar;
@synthesize fcity, cityArray, fkey, keyArray, statusDNArray, fmark, markArray, fday, typesArray, fType;
@synthesize cityBtn, markBtn, statusDNBtn, typeBtn, keyBtn, dayBtn;
@synthesize myTableView;
@synthesize mButton;

@synthesize visitPlan, visitPlanBtn;
@synthesize additionalCusts;
@synthesize labelCustTotal;
@synthesize custPDZList;
@synthesize selectPDZ, selectPDZBtn;
@synthesize selectSalesDateSort, selectSalesDateSortBtn;
@synthesize isNotFirstLaunch;

@synthesize i;

//Andrey
@synthesize aButton;

@synthesize custAddToRouteController;

#pragma mark - View lifecycle
- (instancetype)init {
    self = [super init];
    if (self) {
        _checkboxSelections = 0;
        _cellForRow = 0;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    custForRoute = [NSMutableArray new];
    self.inPseudoEditMode = NO;
    self.selectedImage = [UIImage imageNamed:ACImageNameSelected];
    self.unselectedImage = [UIImage imageNamed:ACImageNameCheckmarkGray];

    self.view.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];

    [self setupNavBar];
    [self setupSearch];
    [self setupFilterBar];
    [self setupCollectionView];

    [self reloadAllAsync];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didSendNewCustomerNotification:)
                                               name:@"SendNewCustomerNotification"
                                             object:nil];

    if (additionalCusts) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refresh) name:@"updateParent" object:nil];
    }
}

#pragma mark - Setup UI
- (void)setupNavBar {
    [ASPFunctions setupNavigationController:self.navigationController
                            backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground]
                                 titleColor:UIColor.whiteColor
                                  tintColor:UIColor.whiteColor];

    [self reconfigureNavItemsForMode];
}

- (void)reconfigureNavItemsForMode {
    if (visitPlan) {
        self.navigationItem.title = @"План посещений";
    } else if (additionalCusts) {
        self.navigationItem.title = @"Дополнительные клиенты";
    } else {
        self.navigationItem.title = @"Список клиентов";
    }

    if (additionalCusts) {
        UIBarButtonItem *load = [[UIBarButtonItem alloc] initWithTitle:@"Загрузить" style:UIBarButtonItemStylePlain target:self action:@selector(requestCustomer:)];
        UIBarButtonItem *clear = [[UIBarButtonItem alloc] initWithTitle:@"Очистить" style:UIBarButtonItemStylePlain target:self action:@selector(customerDelete:)];
        self.navigationItem.leftBarButtonItems = @[load, clear];
        self.navigationItem.rightBarButtonItems = @[];
    } else {
        self.planBarButton = [[UIBarButtonItem alloc] initWithTitle:@"План посещений" style:UIBarButtonItemStylePlain target:self action:@selector(toggleVisitPlan:)];
        self.planBarButton.tintColor = visitPlan ? [UIColor colorNamed:ACColorNameMLKLightBlue] : UIColor.whiteColor;

        self.createBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createCustomer:)];

        self.navigationItem.rightBarButtonItems = @[self.planBarButton, self.createBarButton];

        self.totalBarButton = [[UIBarButtonItem alloc] initWithTitle:[self totalCustSum] style:UIBarButtonItemStylePlain target:nil action:nil];
        self.totalBarButton.enabled = NO;
        [self.totalBarButton setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor} forState:UIControlStateDisabled];
        self.navigationItem.leftBarButtonItems = @[self.totalBarButton];
    }
}

- (void)setupSearch {
    UISearchBar *bar = [[UISearchBar alloc] init];
    bar.placeholder = @"Поиск по названию или адресу";
    bar.delegate = self;
    bar.autocorrectionType = UITextAutocorrectionTypeNo;
    bar.searchBarStyle = UISearchBarStyleMinimal;
    bar.backgroundColor = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
    bar.searchTextField.backgroundColor = UIColor.whiteColor;
    bar.translatesAutoresizingMaskIntoConstraints = NO;

    // Reuse legacy ivar so legacy search helpers (which read searchBar.text) keep working.
    searchBar = bar;

    [self.view addSubview:bar];
    [NSLayoutConstraint activateConstraints:@[
        [bar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [bar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}

- (void)reloadAllAsync {
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self selectAllCustomers];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self populateSelectedArray];
            [self applySnapshot];
            [SVProgressHUD dismiss];
        });
    });
}

- (void)setupFilterBar {
    self.filterScrollView = [UIScrollView new];
    self.filterScrollView.showsHorizontalScrollIndicator = NO;
    self.filterScrollView.backgroundColor = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
    self.filterScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.filterScrollView];

    self.cityPill = [self pillWithTitle:@"Регион" action:@selector(showCity:)];
    self.statusPill = [self pillWithTitle:@"Статус" action:@selector(showDream:)];
    self.markPill = [self pillWithTitle:@"Марка" action:@selector(showBrand:)];
    self.statusDNPill = [self pillWithTitle:@"Статус DN" action:@selector(showStatusDN:)];
    self.typePill = [self pillWithTitle:@"Тип клиента" action:@selector(showCustomerTypes:)];
    self.pdzPill = [self pillWithTitle:@"ПДЗ" action:@selector(toggleSelectPDZ:)];
    self.salesSortPill = [self pillWithTitle:@"Заказ ⇅" action:@selector(toggleSelectSalesDateSort:)];

    [self setPill:self.statusDNPill enabled:NO];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.cityPill, self.statusPill, self.markPill, self.statusDNPill, self.typePill, self.pdzPill, self.salesSortPill
    ]];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.spacing = 8.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.filterScrollView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [self.filterScrollView.topAnchor constraintEqualToAnchor:searchBar.bottomAnchor],
        [self.filterScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.filterScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.filterScrollView.heightAnchor constraintEqualToConstant:48.0],

        [stack.topAnchor constraintEqualToAnchor:self.filterScrollView.topAnchor constant:8.0],
        [stack.bottomAnchor constraintEqualToAnchor:self.filterScrollView.bottomAnchor constant:-8.0],
        [stack.leadingAnchor constraintEqualToAnchor:self.filterScrollView.leadingAnchor constant:12.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.filterScrollView.trailingAnchor constant:-12.0],
        [stack.heightAnchor constraintEqualToConstant:32.0],
    ]];
}

- (UIButton *)pillWithTitle:(NSString *)title action:(SEL)action {
    UIButton *pill = [UIButton buttonWithType:UIButtonTypeSystem];
    [pill setTitle:title forState:UIControlStateNormal];
    pill.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    pill.contentEdgeInsets = UIEdgeInsetsMake(0.0, 14.0, 0.0, 14.0);
    pill.layer.cornerRadius = 16.0;
    pill.clipsToBounds = YES;
    [pill addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self setPill:pill active:NO];
    return pill;
}

- (void)setPill:(UIButton *)pill active:(BOOL)active {
    if (active) {
        pill.backgroundColor = [UIColor colorNamed:ACColorNameMLKLightBlue];
        [pill setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    } else {
        pill.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.18];
        [pill setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
}

- (void)setPill:(UIButton *)pill enabled:(BOOL)enabled {
    pill.enabled = enabled;
    pill.alpha = enabled ? 1.0 : 0.4;
}

- (void)setupCollectionView {
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    configuration.headerMode = UICollectionLayoutListHeaderModeSupplementary;

    __weak typeof(self) weakSelf = self;
    configuration.trailingSwipeActionsConfigurationProvider = ^UISwipeActionsConfiguration * _Nullable(NSIndexPath * _Nonnull indexPath) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return nil; }
        if (indexPath.item >= strongSelf.displayItems.count) { return nil; }

        CustListItem *item = strongSelf.displayItems[indexPath.item];
        BOOL notSent = item.sendStatus != nil && ![item.sendStatus isEqualToString:@"null"] && ![item.sendStatus isEqualToString:@"Sended"];
        if (!notSent) { return nil; }

        UIContextualAction *resend = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Отправить" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [strongSelf showAlertAboutNotSendedNewCusts];
            completionHandler(YES);
        }];
        resend.backgroundColor = [UIColor colorNamed:ACColorNameMLKLightBlue];
        return [UISwipeActionsConfiguration configurationWithActions:@[resend]];
    };

    UICollectionViewCompositionalLayout *layout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];

    self.listCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.listCollectionView.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    self.listCollectionView.delegate = self;
    self.listCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.listCollectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.listCollectionView.topAnchor constraintEqualToAnchor:self.filterScrollView.bottomAnchor],
        [self.listCollectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.listCollectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.listCollectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:CustListCollectionViewCell.class configurationHandler:^(CustListCollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, CustListItem * _Nonnull item) {
        [weakSelf configureCell:cell withItem:item];
    }];

    self.listDataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.listCollectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, CustListItem * _Nonnull item) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:item];
    }];

    UICollectionViewSupplementaryRegistration *headerRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:UICollectionViewListCell.class elementKind:UICollectionElementKindSectionHeader configurationHandler:^(UICollectionViewListCell * _Nonnull supplementaryView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        UIListContentConfiguration *content = [UIListContentConfiguration groupedHeaderConfiguration];
        content.text = (strongSelf->searching && strongSelf->searchBar.text.length > 0) ? @"Результаты поиска" : @"Клиенты";
        supplementaryView.contentConfiguration = content;
    }];

    self.listDataSource.supplementaryViewProvider = ^UICollectionReusableView * _Nullable(UICollectionView * _Nonnull collectionView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        return [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:headerRegistration forIndexPath:indexPath];
    };
}

#pragma mark - Snapshot
- (NSArray<CustListItem *> *)buildCurrentItems {
    NSMutableArray<CustListItem *> *items = [NSMutableArray new];

    BOOL isSearching = searching && searchBar.text.length > 0;

    if (isSearching) {
        for (NSUInteger idx = 0; idx < self->copyCustList.count; idx++) {
            CustListItem *item = [CustListItem new];
            item.name = self->copyCustList[idx];
            item.address = idx < self->copyCustDetList.count ? self->copyCustDetList[idx] : @"";
            item.custAccount = idx < self->copyCustAccList.count ? self->copyCustAccList[idx] : @"";
            item.sendStatus = idx < self->copyCustSendStatusList.count ? self->copyCustSendStatusList[idx] : nil;
            item.pdz = idx < self->copyCustPDZList.count ? self->copyCustPDZList[idx] : @"0";
            item.uid = [NSString stringWithFormat:@"%lu#%@", (unsigned long)idx, item.custAccount];
            [items addObject:item];
        }
    } else {
        if (custList.count == 0) { return items; }
        NSArray *names = custList[0][@"CustName"];
        NSArray *addrs = custDetList.count ? custDetList[0][@"CustAddr"] : @[];
        NSArray *accs = custAccList.count ? custAccList[0][@"CustAcc"] : @[];
        NSArray *statuses = custSendStatusList.count ? custSendStatusList[0][@"CustSendStatus"] : @[];
        NSArray *pdz = custPDZList.count ? custPDZList[0][@"PDZ"] : @[];

        for (NSUInteger idx = 0; idx < names.count; idx++) {
            CustListItem *item = [CustListItem new];
            item.name = names[idx];
            item.address = idx < addrs.count ? addrs[idx] : @"";
            item.custAccount = idx < accs.count ? accs[idx] : @"";
            item.sendStatus = idx < statuses.count ? statuses[idx] : nil;
            item.pdz = idx < pdz.count ? pdz[idx] : @"0";
            item.uid = [NSString stringWithFormat:@"%lu#%@", (unsigned long)idx, item.custAccount];
            [items addObject:item];
        }
    }

    return items;
}

- (void)applySnapshot {
    self.displayItems = [self buildCurrentItems];

    NSDiffableDataSourceSnapshot<NSString *, CustListItem *> *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[kCustListSection]];
    [snapshot appendItemsWithIdentifiers:self.displayItems intoSectionWithIdentifier:kCustListSection];
    [self.listDataSource applySnapshot:snapshot animatingDifferences:NO];

    if (!additionalCusts && self.totalBarButton) {
        self.totalBarButton.title = [self totalCustSum];
    }
}

- (void)configureCell:(CustListCollectionViewCell *)cell withItem:(CustListItem *)item {
    cell.cellDelegate = self;

    NSInteger taskCount = [self custTasksCount:item.custAccount];

    NSString *lastSalesDate;
    BOOL isTP;
    if (self.selectedBrandNames.count > 0) {
        // Brand filter active → show the last order date for this brand only.
        lastSalesDate = [self lastSalesDateForBrand:item.custAccount];
        isTP = NO;
    } else {
        lastSalesDate = [self getLastSalesDate:item.custAccount];
        isTP = ![lastSalesDate isEqualToString:@"null"] && [self isLastSalesTP:item.custAccount];
    }

    // Route highlight (all modes): in today's route → blue, visited → green.
    NSInteger visitState = 0;
    NSString *status = [self visitStatus:item.custAccount];
    if ([status isEqualToString:@"visited"]) {
        visitState = 1;
    } else if ([status isEqualToString:@"visit"]) {
        visitState = 2;
    } else if (visitPlan && [self custWasVisited:item.custAccount]) {
        visitState = 1;
    }

    [cell configureWithName:item.name
                    address:item.address
                     hasPDZ:![item.pdz isEqualToString:@"0"]
                 sendStatus:item.sendStatus
                  taskCount:taskCount
              lastSalesDate:lastSalesDate
              isLastSalesTP:isTP
                  visitPlan:visitPlan
                 visitState:visitState];
}

#pragma mark - CustListCollectionViewCellDelegate
- (void)custListCellDidTapResend:(CustListCollectionViewCell *)cell {
    [self showAlertAboutNotSendedNewCusts];
}

#pragma mark - Mode toggling
- (IBAction)toggleVisitPlan:(id)sender {
    isNotFirstLaunch = YES;

    fcity = nil; fkey = nil; fmark = nil; fType = nil; fday = nil;
    cityArray = nil; markArray = nil; typesArray = nil; keyArray = nil; statusDNArray = nil;
    self.selectedBrandNames = nil;
    [self setPill:self.cityPill active:NO];
    [self setPill:self.statusPill active:NO];
    [self setPill:self.markPill active:NO];
    [self setPill:self.statusDNPill active:NO];
    [self setPill:self.statusDNPill enabled:NO];
    [self setPill:self.typePill active:NO];

    selectPDZ = NO;
    [self setPill:self.pdzPill active:NO];

    visitPlan = !visitPlan;

    [self reconfigureNavItemsForMode];
    [self reloadAllAsync];
}

- (IBAction)toggleSelectPDZ:(id)sender {
    selectPDZ = !selectPDZ;
    [self setPill:self.pdzPill active:selectPDZ];

    [self selectWithFilters];
    [self populateSelectedArray];
    [self applySnapshot];
    [self.listCollectionView setContentOffset:CGPointZero animated:YES];
}

- (IBAction)toggleSelectSalesDateSort:(id)sender {
    selectSalesDateSort = !selectSalesDateSort;
    [self setPill:self.salesSortPill active:selectSalesDateSort];

    [self selectWithFilters];
    [self populateSelectedArray];
    [self applySnapshot];
    [self.listCollectionView setContentOffset:CGPointZero animated:YES];
}

#pragma mark - Legacy multi-select (kept for public API compatibility; not wired in modern UI)
- (IBAction)doDelete {
    NSDictionary *dictCustAcc  = [custAccList objectAtIndex:0];
    NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];

    NSMutableArray *rowsToBeDeleted = [NSMutableArray new];

    int index = 0;
    for (NSNumber *rowSelected in selectedArray) {
        if ([rowSelected boolValue]) {
            [rowsToBeDeleted addObject:[arrayCustAcc objectAtIndex:index]];
        }
        index++;
    }

    for (id value in rowsToBeDeleted) {
        [custAccList removeObject:value];
    }

    inPseudoEditMode = NO;
    [self populateSelectedArray];
    [self applySnapshot];
}

- (IBAction)togglePseudoEditMode:(id)sender {
    self.inPseudoEditMode = !inPseudoEditMode;
    toolbar.hidden = !inPseudoEditMode;
    [self applySnapshot];
}

- (void)populateSelectedArray {
    if (custAccList.count == 0) { self.selectedArray = [NSMutableArray new]; return; }
    NSDictionary *dictCustAcc  = [custAccList objectAtIndex:0];
    NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];

    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[arrayCustAcc count]];
    for (int y = 0; y < [arrayCustAcc count]; y++) {
        [array addObject:[NSNumber numberWithBool:NO]];
    }
    self.selectedArray = array;
}

- (void)didSendNewCustomerNotification:(NSNotification *)notification {
    [self performSelector:@selector(refresh) withObject:nil afterDelay:1.0];
    [SVProgressHUD dismiss];
}

- (NSString *)totalCustSum {
    if (custAccList.count == 0) { return @"0/0"; }
    NSDictionary     *cDict     = [custAccList objectAtIndex:0];
    NSArray          *cArray    = [cDict objectForKey:@"CustAcc"];

    NSCalendar       *calendar  = [NSCalendar autoupdatingCurrentCalendar];
    NSDate           *currDate  = NSDate.date;
    NSDateComponents *dComp     = [calendar components:( NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay )
                                              fromDate:currDate];

    NSUInteger month = [dComp month];
    NSUInteger year  = [dComp year];

    int visited = 0;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = nil;

        NSString *squl;

        NSString *selectPart = @"", *fromPart = @"", *leftJoinPart = @"", *wherePart = @"";

        selectPart      = @"select LastVisitDate\n";
        fromPart        = @"from CustTable custTbl\n";
        leftJoinPart    = @"Left Join CustStatusDN custStatus on custTbl.CustAccount = custStatus.CustAccount\n";
        wherePart       = @"where 1=1 and (StatusDN = '1' or StatusDN = '2') and LastVisitDate <> ''\n";

        if (fkey) {
            wherePart = [NSString stringWithFormat:@"%@ and %@", wherePart, fkey];
        }
        if (fcity) {
            wherePart = [NSString stringWithFormat:@"%@ and %@", wherePart, fcity];
        }
        if (fday) {
            wherePart = [NSString stringWithFormat:@"%@ and LVDateComp > '%@'", wherePart, fday];
        }
        if (fmark) {
            leftJoinPart  = [NSString stringWithFormat:@"%@ Left Join PersonalPriceList priceList on custTbl.CustAccount = priceList.CustAccount\n", leftJoinPart];
            wherePart = [NSString stringWithFormat:@"%@ and priceList.Active = '1' and %@", wherePart, fmark];
        }

        squl = [NSString stringWithFormat:@"%@ %@ %@ %@ order by Name", selectPart, fromPart, leftJoinPart, wherePart];
        sql  = [squl UTF8String];

        sqlite3_stmt *selectstmt;

        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *lvDate   = @"null";

                if (sqlite3_column_text(selectstmt, 0)) {
                    lvDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];

                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    NSDate *dateFromString = [dateFormatter dateFromString:lvDate];

                    if (dateFromString) {
                        NSCalendar       *cal = [NSCalendar autoupdatingCurrentCalendar];
                        NSDateComponents *dC  = [cal components:( NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay )
                                                       fromDate:dateFromString];

                        if ([dC month] == month && [dC year] == year)
                            visited = visited + 1;
                    }
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);

    return [NSString stringWithFormat:@"%d/%lu", visited, (unsigned long)[cArray count]];
}

- (void)selectAllCustomers {
    NSMutableArray *custsToLiveInArray          = [NSMutableArray array];
    NSMutableArray *custDetToLiveInArray        = [NSMutableArray array];
    NSMutableArray *custAccToLiveInArray        = [NSMutableArray array];
    NSMutableArray *custSendStatusToLiveInArray = [NSMutableArray array];
    NSMutableArray *custPDZToLiveInArray        = [NSMutableArray array];

    custList            = [NSMutableArray new];
    custDetList         = [NSMutableArray new];
    custAccList         = [NSMutableArray new];
    custSendStatusList  = [NSMutableArray new];
    custPDZList         = [NSMutableArray new];

    copyCustList            = [NSMutableArray new];
    copyCustDetList         = [NSMutableArray new];
    copyCustAccList         = [NSMutableArray new];
    copyCustSendStatusList  = [NSMutableArray new];
    copyCustPDZList         = [NSMutableArray new];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;

        if (visitPlan) {
            sql = "select CustTable.CustAccount, Name, FactAddress, SendStatus, PDZAmount, Phone \n"
                    "from CustTable \n"
                    "LEFT JOIN CustStatusDN on CustTable.CustAccount = CustStatusDN.CustAccount\n"
                    "where CustStatusDN.StatusDN = '1' or CustStatusDN.StatusDN = '2'\n"
                    "order by Name asc;";
        }
        else if (additionalCusts)
            sql = "select CustAccount, Name, FactAddress, SendStatus, PDZAmount, Phone from CustTable where AdditionalCust = 1 order by Name asc";
        else
            sql = "select CustAccount, Name, FactAddress, SendStatus, PDZAmount, Phone, AdditionalCust from CustTable order by Name asc";

        sqlite3_stmt *selectstmt;

        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);

        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc        = @"null";
                NSString *custName       = @"null";
                NSString *custAddr       = @"null";
                NSString *custSendStatus = @"null";
                NSString *pdzAmount      = @"0";

                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];

                if (sqlite3_column_text(selectstmt, 1))
                    custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];

                if (sqlite3_column_text(selectstmt, 2))
                    custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];

                if (sqlite3_column_text(selectstmt, 3))
                    custSendStatus  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];

                if (sqlite3_column_text(selectstmt, 4))
                    pdzAmount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];

                [custsToLiveInArray   addObject:custName];
                [custDetToLiveInArray addObject:custAddr];
                [custAccToLiveInArray addObject:custAcc];
                [custSendStatusToLiveInArray addObject:custSendStatus];
                [custPDZToLiveInArray addObject:pdzAmount];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);

    NSDictionary *custsToLiveInDict             = [NSDictionary dictionaryWithObject:custsToLiveInArray forKey:@"CustName"];
    NSDictionary *custsDetToLiveInDict          = [NSDictionary dictionaryWithObject:custDetToLiveInArray forKey:@"CustAddr"];
    NSDictionary *custsAccToLiveInDict          = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    NSDictionary *custsSendStatusToLiveInDict   = [NSDictionary dictionaryWithObject:custSendStatusToLiveInArray forKey:@"CustSendStatus"];
    NSDictionary *custsPDZToLiveInDict          = [NSDictionary dictionaryWithObject:custPDZToLiveInArray forKey:@"PDZ"];

    [custList           addObject:custsToLiveInDict];
    [custDetList        addObject:custsDetToLiveInDict];
    [custAccList        addObject:custsAccToLiveInDict];
    [custSendStatusList addObject:custsSendStatusToLiveInDict];
    [custPDZList        addObject:custsPDZToLiveInDict];
}

#pragma mark - Filter delegates
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
    [self applySnapshot];

    [self setPill:self.cityPill active:fcity != nil];
}

- (void)userDidSelectBrand:(NSMutableArray *)brandArray {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    markArray = [brandArray copy];

    NSString *squl;
    for (NSString *mark in markArray) {
        if ([mark isEqualToString:markArray.firstObject]) {
            squl = [NSString stringWithFormat:@"priceList.BrandId = '%@'", mark];
        } else {
            squl = [NSString stringWithFormat:@"%@ or priceList.BrandId = '%@'", squl, mark];
        }
    }

    fmark = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;

    // Cache brand names so each row can show the last order date for this brand.
    self.selectedBrandNames = markArray.count > 0 ? [self brandNamesForBrandIds:markArray] : nil;

    if (markArray.count == 1) {
        [self setPill:self.statusDNPill enabled:YES];
    } else {
        statusDNArray = nil;
        self.fstatusDN = nil;
        [self setPill:self.statusDNPill active:NO];
        [self setPill:self.statusDNPill enabled:NO];
    }

    [self selectWithFilters];
    [self populateSelectedArray];
    [self applySnapshot];

    [self setPill:self.markPill active:fmark != nil];
}

- (void)userDidSelectStatusDN:(NSMutableArray *)statusDNArrayParam {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    statusDNArray = [statusDNArrayParam copy];

    NSString *squl;
    for (NSString *statusDN in statusDNArray) {
        if ([statusDN isEqualToString:statusDNArray.firstObject]) {
            squl = [NSString stringWithFormat:@"sDNBrand.Status = '%@'", statusDN];
        } else {
            squl = [NSString stringWithFormat:@"%@ or sDNBrand.Status = '%@'", squl, statusDN];
        }
    }

    self.fstatusDN = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;

    [self selectWithFilters];
    [self populateSelectedArray];
    [self applySnapshot];

    [self setPill:self.statusDNPill active:self.fstatusDN != nil];
}

#pragma mark - CustomerTypesTableViewControllerDelegate
- (void)userDidSelectCustomerTypes:(NSArray *)selectedTypes {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    typesArray = [selectedTypes copy];

    NSString *squl;
    for (NSDictionary *type in typesArray) {
        if ([type isEqual:typesArray.firstObject]) {
            squl = [NSString stringWithFormat:@"Property6 = '%@'", type[@"property6"]];
        } else {
            squl = [NSString stringWithFormat:@"%@ or Property6 = '%@'", squl, type[@"property6"]];
        }
    }

    fType = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;

    [self selectWithFilters];
    [self populateSelectedArray];
    [self applySnapshot];

    [self setPill:self.typePill active:fType != nil];
}

- (void)userDidSelectDream:(NSMutableArray *)dreamArray {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    keyArray = [dreamArray copy];

    NSString *squl;
    for (NSString *dream in dreamArray) {
        if ([dream isEqualToString:dreamArray.firstObject]) {
            squl = [NSString stringWithFormat:@"StatusDN = '%@'", dream];
        } else {
            squl = [NSString stringWithFormat:@"%@ or StatusDN = '%@'", squl, dream];
        }
    }

    fkey = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;

    [self selectWithFilters];
    [self populateSelectedArray];
    [self applySnapshot];

    [self setPill:self.statusPill active:fkey != nil];
}

- (void)selectWithFilters {
    NSMutableArray *custsToLiveInArray          = [NSMutableArray array];
    NSMutableArray *custDetToLiveInArray        = [NSMutableArray array];
    NSMutableArray *custAccToLiveInArray        = [NSMutableArray array];
    NSMutableArray *custSendStatusToLiveInArray = [NSMutableArray array];
    NSMutableArray *custPDZToLiveInArray        = [NSMutableArray array];

    custList            = [NSMutableArray new];
    custDetList         = [NSMutableArray new];
    custAccList         = [NSMutableArray new];
    custSendStatusList  = [NSMutableArray new];
    custPDZList         = [NSMutableArray new];

    copyCustList            = [NSMutableArray new];
    copyCustDetList         = [NSMutableArray new];
    copyCustAccList         = [NSMutableArray new];
    copyCustSendStatusList  = [NSMutableArray new];
    copyCustPDZList         = [NSMutableArray new];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = nil;

        NSString *squl;

        NSString *selectPart = @"", *fromPart = @"", *leftJoinPart = @"", *wherePart = @"";
        if (visitPlan) {
            selectPart      = @"select distinct custTbl.CustAccount, custTbl.Name, custTbl.FactAddress, custTbl.SendStatus, custTbl.PDZAmount, custTbl.Phone\n";
            fromPart        = @"from CustTable custTbl\n";
            leftJoinPart    = @"Left Join CustStatusDN custStatus on custTbl.CustAccount = custStatus.CustAccount\n";
            wherePart       = @"Where (StatusDN = '1' or StatusDN = '2')";
        }
        else if (additionalCusts) {
            selectPart  = @"select distinct custTbl.CustAccount, custTbl.Name, custTbl.FactAddress, custTbl.SendStatus, custTbl.PDZAmount, custTbl.Phone\n";
            fromPart    = @"from CustTable custTbl\n";
            wherePart   = @"where 1=1 and AdditionalCust = '1'";
        } else {
            selectPart  = @"select distinct custTbl.CustAccount, custTbl.Name, custTbl.FactAddress, custTbl.SendStatus, custTbl.PDZAmount, custTbl.Phone\n";
            fromPart    = @"from CustTable custTbl\n";
            wherePart   = @"where 1=1";
        }

        if (fkey && !visitPlan) {
            leftJoinPart    = [NSString stringWithFormat:@"%@ Left Join CustStatusDN custStatus on custTbl.CustAccount = custStatus.CustAccount\n", leftJoinPart];
            wherePart       = [NSString stringWithFormat:@"%@ and %@", wherePart, fkey];
        }
        if (fcity) {
            wherePart = [NSString stringWithFormat:@"%@ and %@", wherePart, fcity];
        }
        if (fday) {
            wherePart = [NSString stringWithFormat:@"%@ and LVDateComp > '%@'", wherePart, fday];
        }
        if (fmark) {
            leftJoinPart  = [NSString stringWithFormat:@"%@ Left Join PersonalPriceList priceList on custTbl.CustAccount = priceList.CustAccount\n", leftJoinPart];

            if (self.fstatusDN) {
                leftJoinPart = [NSString stringWithFormat:@"%@ Join CustStatusDNBrand sDNBrand on (custTbl.CustAccount = sDNBrand.CustAccount and priceList.BrandId = sDNBrand.BrandId)\n", leftJoinPart];
            }
            wherePart = [NSString stringWithFormat:@"%@ and priceList.Active = '1' and %@", wherePart, fmark];

            if (self.fstatusDN) {
                wherePart = [NSString stringWithFormat:@"%@ and %@", wherePart, self.fstatusDN];
            }
        }

        if (fType) {
            wherePart = [NSString stringWithFormat:@"%@ and %@", wherePart, fType];
        }

        if (selectPDZ)
            wherePart = [NSString stringWithFormat:@"%@ and PDZAmount != '0'", wherePart];

        if (!selectSalesDateSort)
            squl = [NSString stringWithFormat:@"%@ %@ %@ %@ order by Name", selectPart, fromPart, leftJoinPart, wherePart];
        else
            squl = [NSString stringWithFormat:@"%@ %@ %@ %@ order by SalesDateSort desc", selectPart, fromPart, leftJoinPart, wherePart];

        sql = [squl UTF8String];

        sqlite3_stmt *selectstmt;

        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc        = @"null";
                NSString *custName       = @"null";
                NSString *custAddr       = @"null";
                NSString *custSendStatus = @"null";
                NSString *pdzAmount      = @"0";

                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];

                if (sqlite3_column_text(selectstmt, 1))
                    custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];

                if (sqlite3_column_text(selectstmt, 2))
                    custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];

                if (sqlite3_column_text(selectstmt, 3))
                    custSendStatus  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];

                if (sqlite3_column_text(selectstmt, 4))
                    pdzAmount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];

                [custsToLiveInArray          addObject:custName];
                [custDetToLiveInArray        addObject:custAddr];
                [custAccToLiveInArray        addObject:custAcc];
                [custSendStatusToLiveInArray addObject:custSendStatus];
                [custPDZToLiveInArray        addObject:pdzAmount];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    }
    else {
        sqlite3_close(database);
    }

    NSDictionary *custsToLiveInDict             = [NSDictionary dictionaryWithObject:custsToLiveInArray forKey:@"CustName"];
    NSDictionary *custsDetToLiveInDict          = [NSDictionary dictionaryWithObject:custDetToLiveInArray forKey:@"CustAddr"];
    NSDictionary *custsAccToLiveInDict          = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    NSDictionary *custsSendStatusToLiveInDict   = [NSDictionary dictionaryWithObject:custSendStatusToLiveInArray forKey:@"CustSendStatus"];
    NSDictionary *custsPDZToLiveInDict          = [NSDictionary dictionaryWithObject:custPDZToLiveInArray forKey:@"PDZ"];

    [custList           addObject:custsToLiveInDict];
    [custDetList        addObject:custsDetToLiveInDict];
    [custAccList        addObject:custsAccToLiveInDict];
    [custSendStatusList addObject:custsSendStatusToLiveInDict];
    [custPDZList        addObject:custsPDZToLiveInDict];
}

#pragma mark - Filter popovers
- (void)showCity:(id)sender {
    if (self.presentedViewController) { return; }
    CustCity *custCity = [[CustCity alloc] init];
    custCity.delegate = self;
    custCity.visitPlan = visitPlan;
    custCity.addCust = additionalCusts;
    custCity.selected = cityArray;

    custCity.modalPresentationStyle = UIModalPresentationPopover;
    custCity.popoverPresentationController.sourceView = self.cityPill;
    custCity.popoverPresentationController.sourceRect = self.cityPill.bounds;

    [self presentViewController:custCity animated:YES completion:nil];
}

- (void)showBrand:(id)sender {
    if (self.presentedViewController) { return; }
    CustBrand *custBrand = [CustBrand new];
    custBrand.delegate = self;
    custBrand.visitPlan = visitPlan;
    custBrand.addCust = additionalCusts;
    custBrand.selected = markArray;

    custBrand.modalPresentationStyle = UIModalPresentationPopover;
    custBrand.popoverPresentationController.sourceView = self.markPill;
    custBrand.popoverPresentationController.sourceRect = self.markPill.bounds;

    [self presentViewController:custBrand animated:YES completion:nil];
}

- (void)showStatusDN:(id)sender {
    if (self.presentedViewController) { return; }
    CustStatusDN *custStatusDN = [CustStatusDN new];
    custStatusDN.delegate = self;
    custStatusDN.visitPlan = visitPlan;
    custStatusDN.addCust = additionalCusts;
    custStatusDN.selected = statusDNArray;

    custStatusDN.modalPresentationStyle = UIModalPresentationPopover;
    custStatusDN.popoverPresentationController.sourceView = self.statusDNPill;
    custStatusDN.popoverPresentationController.sourceRect = self.statusDNPill.bounds;

    [self presentViewController:custStatusDN animated:YES completion:nil];
}

- (void)showCustomerTypes:(id)sender {
    if (self.presentedViewController) { return; }
    CustomerTypesTableViewController *customerTypesVC = [CustomerTypesTableViewController new];
    customerTypesVC.delegate = self;
    customerTypesVC.selectedTypesArray = typesArray.mutableCopy;

    customerTypesVC.modalPresentationStyle = UIModalPresentationPopover;
    customerTypesVC.popoverPresentationController.sourceView = self.typePill;
    customerTypesVC.popoverPresentationController.sourceRect = self.typePill.bounds;
    [self presentViewController:customerTypesVC animated:YES completion:nil];
}

- (void)showDream:(id)sender {
    if (self.presentedViewController) { return; }
    CustDream *custDream = [CustDream new];
    custDream.delegate = self;
    custDream.visitPlan = visitPlan;
    custDream.addCust = additionalCusts;
    custDream.selected = keyArray;

    custDream.modalPresentationStyle = UIModalPresentationPopover;
    custDream.popoverPresentationController.sourceView = self.statusPill;
    custDream.popoverPresentationController.sourceRect = self.statusPill.bounds;

    [self presentViewController:custDream animated:YES completion:nil];
}

- (void)selectDay:(id)sender {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    [self visitDay:sender];

    dayBtn = sender;
}

- (IBAction)visitDay:(id)sender {
    [AlertWorkerObjc actionSheetWithTitle:nil message:nil sourceView:sender buttons:@[@"Неделя", @"Месяц",  @"Квартал", @"Полугодие", @"Задать", @"Убрать фильтр"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if ([action.title isEqual:@"Убрать фильтр"]) {
            self->fday = nil;
            [self selectWithFilters];
            [self applySnapshot];
        } else {
            if ([action.title isEqual:@"Неделя"]) {
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*7];
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                self->fday = [dateFormatter stringFromDate:dateY];
                [self selectWithFilters];
                [self applySnapshot];
            }

            if ([action.title isEqual:@"Месяц"]) {
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*30];
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                self->fday = [dateFormatter stringFromDate:dateY];
                [self selectWithFilters];
                [self applySnapshot];
            }

            if ([action.title isEqual:@"Квартал"]) {
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*90];
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                self->fday = [dateFormatter stringFromDate:dateY];
                [self selectWithFilters];
                [self applySnapshot];
            }

            if ([action.title isEqual:@"Полугодие"]) {
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*180];
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                self->fday = [dateFormatter stringFromDate:dateY];
                [self selectWithFilters];
                [self applySnapshot];
            }

            if ([action.title isEqual:@"Задать"]) {
                UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"Введите кол-во дней"  message:@"дни визита" preferredStyle:UIAlertControllerStyleAlert];

                [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.keyboardType = UIKeyboardTypePhonePad;
                    [textField becomeFirstResponder];
                }];

                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*[alertVC.textFields.firstObject.text doubleValue]];
                    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    self->fday = [dateFormatter stringFromDate:dateY];
                    [self selectWithFilters];
                    [self populateSelectedArray];
                    [self applySnapshot];
                }];

                [alertVC addAction:okAction];

                [self presentViewController:alertVC animated:YES completion:nil];
            }
        }
    }];
}

- (void)clearFilter {
    NSString *searchText = searchBar.text;

    fcity = nil;
    fkey  = nil;
    fmark = nil;
    fType = nil;
    fday  = nil;

    cityArray = nil;
    markArray = nil;
    typesArray = nil;
    keyArray = nil;
    statusDNArray = nil;
    self.selectedBrandNames = nil;

    [self setPill:self.cityPill active:NO];
    [self setPill:self.statusPill active:NO];
    [self setPill:self.markPill active:NO];
    [self setPill:self.statusDNPill active:NO];
    [self setPill:self.statusDNPill enabled:NO];
    [self setPill:self.typePill active:NO];

    [self selectAllCustomers];
    [self populateSelectedArray];
    [self applySnapshot];

    searchBar.text = searchText;
}

#pragma mark - Route date picker (legacy multi-select add)
- (void)selectDate:(id)sender {
    BOOL isStop = [self IsStop];

    if (isStop == YES) {
        [AlertWorkerObjc alertWithTitle:@"Маршрут закончен"];
        return;
    }

    if (inPseudoEditMode) {
        if (self.presentedViewController) { return; }
        ASPDatePickerViewController *datePickerVC = [ASPDatePickerViewController new];
        datePickerVC.delegate = self;
        datePickerVC.modalPresentationStyle = UIModalPresentationPopover;
        datePickerVC.popoverPresentationController.barButtonItem = aButton;
        [self presentViewController:datePickerVC animated:YES completion:nil];
    }
}

#pragma mark - ASPDatePickerViewControllerDelegate
- (void)datePickerDidCancel {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)datePickerDidPickDate:(NSDate *)date {
    [self datePickerDidCancel];

    self.selectedDate = date;

    buttonTapped        = FALSE;
    _checkboxSelections = 0;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat_dd_MM_YYYY];
    NSString *strDate = [formatter stringFromDate:self.selectedDate];

    if (!self.selectedDate) {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *now            = NSDate.date;
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        strDate = [dateFormatter stringFromDate:now];
    }

    for (int y = 0; y < [custForRoute count]; y++) {
        NSString *custAccount = [custForRoute objectAtIndex:y];
        NSString *custName    = @"null";
        NSString *custAddr    = @"null";

        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            const char *sql = "select Name, FactAddress from CustTable where CustAccount = ?";
            sqlite3_stmt *selectstmt;

            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);

                if (sqlite3_step(selectstmt) == SQLITE_ROW ) {
                    if (sqlite3_column_text(selectstmt, 0))
                        custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];

                    if (sqlite3_column_text(selectstmt, 1))
                        custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
            }
            sqlite3_finalize(selectstmt);
            sqlite3_close(database);
        }
        else
            sqlite3_close(database);

        [self addCustomersToRoute:custAccount custName:custName custAddr:custAddr strDate:strDate];
    }
    [self populateSelectedArray];
    [self applySnapshot];

    [self togglePseudoEditMode:mButton];
}

- (int)getCustInRouteCount:(NSString *)strDate {
    int custInRout = 0;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select count(*) from CustForRoute where DateOfRoute = ?";
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(statement) == SQLITE_ROW )
                custInRout  = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

    return custInRout;
}

- (void)addCustomerToRouteDB:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate {
    int lineNum = [self getCustInRouteCount:strDate];

    NSString *strLineNum = [NSString stringWithFormat:@"%i", lineNum];
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "replace into CustForRoute (CustAccount, DateOfRoute, RegularRoute, CustName, GPSPoint, lineNum, GPSRequest, isSended) Values(?, ?, ?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *addStmt;

        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(addStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [@"No" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [custName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [custAddress UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [strLineNum UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(addStmt, 8, 0);

            sqlite3_step(addStmt);
            sqlite3_finalize(addStmt);
        }
    }
    sqlite3_close(database);
}

- (void)addCustomersToRoute:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate {
    if (lastSend) {
        lastSend = nil;
    }

    lastSend = [[PutClientForRouteRequest alloc] init];
    lastSend.custAccount = custAccount;
    lastSend.date = strDate;
    lastSend.custAddress = custAddress;
    lastSend.custName = custName;
    lastSend.forDelete = NO;
    lastSend.delegate = self;
    lastSend.notShowProgress = YES;
    [self addCustomerToRouteDB:custAccount custName:custName custAddr:custAddress strDate:strDate];
    [lastSend sendCust];
}

- (void)isSended:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;

        const char *sql = "update CustForRoute Set isSended = ? where CustAccount = ? and DateOfRoute = ?";

        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);

        sqlite3_bind_int(updateStmt, 1, 1);
        sqlite3_bind_text(updateStmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);

        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);

        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)removeCustomersFromRoute:(NSString *)custAccount {
    if (lastSend) {
        lastSend = nil;
    }

    lastSend = [[PutClientForRouteRequest alloc] init];
    lastSend.custAccount = custAccount;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat_dd_MM_YYYY];
    NSString *strDate = [formatter stringFromDate:self.selectedDate];
    lastSend.date = strDate;
    lastSend.forDelete = YES;
    lastSend.notShowProgress = YES;
    lastSend.delegate = self;
    [self removeCustomerFromRouteDB:custAccount];
    [lastSend sendCust];
}

- (void)removeCustomerFromRouteDB:(NSString *)custAccount {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *deleteStmt;

        const char *sql = "update CustForRoute Set isSended = ?, IsDeleted = ? where CustAccount = ?";

        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        sqlite3_bind_int(deleteStmt, 1, 0);
        sqlite3_bind_int(deleteStmt, 2, 1);
        sqlite3_bind_text(deleteStmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);

        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)isSendedForDelete:(NSString *)custAccount {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *deleteStmt;

        const char *sql = "delete from CustForRoute where CustAccount = ?";

        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        sqlite3_bind_text(deleteStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);

        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
    }

    sqlite3_close(database);
}

- (void)selectForMark {
    if (buttonTapped) {
        buttonTapped        = FALSE;
        _checkboxSelections = 0;
    } else {
        buttonTapped = YES;
    }

    [custForRoute removeAllObjects];
    [self applySnapshot];
}

- (void)dealloc {
    lastSend.delegate = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"SendNewCustomerNotification" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"updateParent" object:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Per-row DB helpers
- (NSInteger)custTasksCount:(NSString *)custAccount {
    NSInteger countTasks = 0;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;

        sql = "select count(TaskId) from TaskTable where CustAccount = ? and (Status = 'Открытая' or Status = 'В работе')";

        sqlite3_stmt *selectstmt;

        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                if (sqlite3_column_text(selectstmt, 0)) {
                    countTasks = sqlite3_column_int(selectstmt, 0);
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);

    return countTasks;
}

- (BOOL)custWasVisited:(NSString *)custAcc {
    NSCalendar       *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDate           *currDate = NSDate.date;
    NSDateComponents *dComp = [calendar components:( NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay )
                                          fromDate:currDate];

    NSUInteger month = [dComp month];
    NSUInteger year  = [dComp year];

    BOOL visited = FALSE;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        NSString *squl;
        squl = @"select LastVisitDate \n"
                "from CustTable custTbl\n"
                "Left Join CustStatusDN custStatus on custTbl.CustAccount = custStatus.CustAccount\n"
                "where custTbl.CustAccount = ? and (StatusDN = '1' or StatusDN = '2')\n"
                "order by Name asc";
        sql  = [squl UTF8String];
        sqlite3_stmt *selectstmt;

        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);

            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *lvDate   = @"null";

                if (sqlite3_column_text(selectstmt, 0)) {
                    lvDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];

                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    NSDate *dateFromString = [dateFormatter dateFromString:lvDate];

                    NSCalendar       *cal = [NSCalendar autoupdatingCurrentCalendar];
                    NSDateComponents *dC  = [cal components:( NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay )
                                                   fromDate:dateFromString];

                    if ([dC month] == month && [dC year] == year)
                        visited = YES;
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);

    return visited;
}

- (void)showAlertAboutNotSendedNewCusts {
    [AlertWorkerObjc alertWithTitle:@"Переотправить всех не отправленных клиентов?" message:nil buttons:@[@"Да", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            [self sendNewCustomer];
        }
    }];
}

#pragma mark - Search helpers
- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
    [copyCustList           removeAllObjects];
    [copyCustAccList        removeAllObjects];
    [copyCustDetList        removeAllObjects];
    [copyCustSendStatusList removeAllObjects];
    [copyCustPDZList        removeAllObjects];

    if ([searchText length] > 0) {
        searching = YES;
        [self searchTableView];
    } else {
        searching = NO;
    }

    [self applySnapshot];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)sBar {
    [searchBar resignFirstResponder];
    [self doneSearching_Clicked:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [self searchTableView];
    [self applySnapshot];
}

- (void)searchTableView {
    NSString       *searchText                  = searchBar.text;
    NSMutableArray *searchArray                 = [NSMutableArray new];
    NSMutableArray *searchArrayDet              = [NSMutableArray new];
    NSMutableArray *searchArrayCustAcc          = [NSMutableArray new];
    NSMutableArray *searchArrayCustSendStatus   = [NSMutableArray new];
    NSMutableArray *searchArrayCustPDZ          = [NSMutableArray new];

    for (NSDictionary *dictionary in custList) {
        NSArray *array = [dictionary objectForKey:@"CustName"];
        [searchArray addObjectsFromArray:array];
    }

    for (NSDictionary *dictDetail in custDetList) {
        NSArray *array = [dictDetail objectForKey:@"CustAddr"];
        [searchArrayDet addObjectsFromArray:array];
    }

    for (NSDictionary *dictCustAcc in custAccList) {
        NSArray *array = [dictCustAcc objectForKey:@"CustAcc"];
        [searchArrayCustAcc addObjectsFromArray:array];
    }

    for (NSDictionary *dictCustSendStatus in custSendStatusList) {
        NSArray *array = [dictCustSendStatus objectForKey:@"CustSendStatus"];
        [searchArrayCustSendStatus addObjectsFromArray:array];
    }

    for (NSDictionary *dictCustPDZ in custPDZList) {
        NSArray *array = [dictCustPDZ objectForKey:@"PDZ"];
        [searchArrayCustPDZ addObjectsFromArray:array];
    }

    for (unsigned long y = 0; y < [searchArray count]; y++) {
        NSRange titleResultsRange  = [[searchArray objectAtIndex:y] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        NSRange detailResultsRange = [[searchArrayDet objectAtIndex:y] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        NSRange accountResultsRange = [[searchArrayCustAcc objectAtIndex:y] rangeOfString:searchText options:NSCaseInsensitiveSearch];

        if (titleResultsRange.length > 0 || detailResultsRange.length > 0 || accountResultsRange.length > 0) {
            [copyCustDetList        addObject:[searchArrayDet objectAtIndex:y]];
            [copyCustList           addObject:[searchArray objectAtIndex:y]];
            [copyCustAccList        addObject:[searchArrayCustAcc objectAtIndex:y]];
            [copyCustSendStatusList addObject:[searchArrayCustSendStatus objectAtIndex:y]];
            [copyCustPDZList        addObject:[searchArrayCustPDZ objectAtIndex:y]];
        }
    }
}

- (void)doneSearching_Clicked:(id)sender {
    searchBar.text = @"";
    [searchBar resignFirstResponder];

    searching = NO;
    [self applySnapshot];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    if (indexPath.item >= self.displayItems.count) { return; }
    CustListItem *item = self.displayItems[indexPath.item];

    if (inPseudoEditMode) {
        NSString *custAccout = item.custAccount;

        if (indexPath.item < selectedArray.count) {
            BOOL selected = [[selectedArray objectAtIndex:indexPath.item] boolValue];
            [selectedArray replaceObjectAtIndex:indexPath.item withObject:[NSNumber numberWithBool:!selected]];

            if (!selected) {
                [custForRoute addObject:custAccout];
            } else {
                [custForRoute removeObject:custAccout];
            }
        }

        [self applySnapshot];

        aButton.enabled = [custForRoute count] > 0;
        return;
    }

    [self.view endEditing:YES];
    custAddToRouteController                = [[CustAddToRouteController alloc] init];
    custAddToRouteController.custAcc        = item.custAccount;
    custAddToRouteController.custName       = item.name;
    custAddToRouteController.custAddress    = item.address;
    custAddToRouteController.countTasks     = [NSString stringWithFormat:@"%ld", (long)[self custTasksCount:item.custAccount]];
    custAddToRouteController.delegate       = self;

    UINavigationController *infoNav = [[UINavigationController alloc] initWithRootViewController:custAddToRouteController];
    infoNav.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNav.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;

    [self.navigationController presentViewController:infoNav animated:YES completion:nil];
    infoNav.preferredContentSize = CGSizeMake(400, 300);

    custAddToRouteController = nil;
}

- (void)hideCustActionListAndShow:(UIViewController *)vcToShow {
    [self dismissViewControllerAnimated:NO completion:^() {
        [self.navigationController presentViewController:vcToShow animated:NO completion:nil];
    }];
}

- (void)finalizeStatements {
    if (database) sqlite3_close(database);
}

- (void)scrollToTop {
    [self.listCollectionView setContentOffset:CGPointZero animated:YES];
}

- (NSString *)visitStatus:(NSString *)custAccount {
    NSString *status = @"null";

    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;

    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];

    NSString *strDate = [dateFormatter stringFromDate:date];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ?";
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(statement) == SQLITE_ROW ) {
                if (sqlite3_column_text(statement, 0))
                    status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

    return status;
}

#pragma mark - Route start/stop checks
- (BOOL)IsStart {
    BOOL isStart = false;

    NSDate *date = NSDate.date;

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];

    NSString *routeDate = [dateFormat stringFromDate:date];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from StartStop where Date = ? and Status = ?";
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"START" UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(statement) == SQLITE_ROW)
                isStart = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

    return isStart;
}

- (BOOL)IsStop {
    BOOL isStop = false;

    NSDate *date = NSDate.date;

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];

    NSString *routeDate = [dateFormat stringFromDate:date];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from StartStop where Date = ? and Status = ?";
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [routeDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [@"STOP" UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(statement) == SQLITE_ROW)
                isStop = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

    return isStop;
}

#pragma mark - Actions
- (void)createCustomer:(id)sender {
    NewCustomerViewController *newCustomerVC = [[UIStoryboard storyboardWithName:@"NewCustomer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(NewCustomerViewController.class)];

    UINavigationController *newCustomerNavVC = [[UINavigationController alloc] initWithRootViewController:newCustomerVC];
    newCustomerNavVC.modalPresentationStyle = UIModalPresentationFullScreen;

    [self.navigationController presentViewController:newCustomerNavVC animated:YES completion:nil];
}

- (void)requestCustomer:(id)sender {
    MoreCustViewController *fvController = [[MoreCustViewController alloc] initWithNibName:@"MoreCustViewController" bundle:nil];

    UINavigationController *infoNav = [[UINavigationController alloc] initWithRootViewController:fvController];
    infoNav.modalPresentationStyle = UIModalPresentationFormSheet;

    [self.navigationController presentViewController:infoNav animated:YES completion:nil];
}

- (void)customerDelete:(id)sender {
    [AlertWorkerObjc alertWithTitle:@"Вы уверены, что хотите удалить временных клиентов?" message:nil buttons:@[@"Да", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
                static sqlite3_stmt *compiledStatement;

                sqlite3_exec(database, [@"delete from CustTable where AdditionalCust = '1'" UTF8String], NULL, NULL, NULL);

                sqlite3_finalize(compiledStatement);
                sqlite3_close(database);
            }
            else
                sqlite3_close(database);

            [self refresh];
        }
    }];
}

- (void)refresh {
    if (searching) {
        [self searchBar:searchBar textDidChange:searchBar.text];
    } else {
        [self customerAdded];
    }
}

- (void)customerAdded {
    [self selectWithFilters];
    [self populateSelectedArray];
    [self applySnapshot];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!additionalCusts && self.totalBarButton) {
        self.totalBarButton.title = [self totalCustSum];
    }
}

- (void)setEnabled:(BOOL)value forButton:(UIBarButtonItem *)button {
    RWBorderedButton *customViewButton = button.customView;
    [customViewButton setEnabled:value];
}

#pragma mark - request
- (void)sendNewCustomer {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;

        const char *sql = "select CustAccount, Name, FactAddress, Phone, Email, GPSPoint, Note, NewCustomer, SendStatus from CustTable where (SendStatus = 'Error' or SendStatus = 'new') and NewCustomer = 'yes'";

        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc       = @"null";
                NSString *name          = @"null";
                NSString *factAddress   = @"null";
                NSString *phone         = @"null";
                NSString *email         = @"null";
                NSString *GPSPoint      = @"null";
                NSString *note          = @"null";

                if (sqlite3_column_text(selectstmt, 0))
                    custAcc        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];

                if (sqlite3_column_text(selectstmt, 1))
                    name      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];

                if (sqlite3_column_text(selectstmt, 2))
                    factAddress          = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];

                if (sqlite3_column_text(selectstmt, 3))
                    phone      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];

                if (sqlite3_column_text(selectstmt, 4))
                    email  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];

                if (sqlite3_column_text(selectstmt, 5))
                    GPSPoint        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];

                if (sqlite3_column_text(selectstmt, 6))
                    note     = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];

                NSDate *date = NSDate.date;

                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"dd.MM.yyyy HH:mm"];

                NSString *dateString = [dateFormat stringFromDate:date];

                XMLWriter* xmlWriter = [[XMLWriter alloc] init];

                [xmlWriter writeStartElement:@"sam:Value"];

                [xmlWriter writeStartElement:@"sam:Date"];
                [xmlWriter writeCharacters:dateString];
                [xmlWriter writeEndElement];

                [xmlWriter writeStartElement:@"sam:Name"];
                [xmlWriter writeCharacters:name];
                [xmlWriter writeEndElement];

                [xmlWriter writeStartElement:@"sam:FactAddress"];
                [xmlWriter writeCharacters:factAddress];
                [xmlWriter writeEndElement];

                [xmlWriter writeStartElement:@"sam:Phone"];
                [xmlWriter writeCharacters:phone];
                [xmlWriter writeEndElement];

                [xmlWriter writeStartElement:@"sam:Email"];
                [xmlWriter writeCharacters:email];
                [xmlWriter writeEndElement];

                [xmlWriter writeStartElement:@"sam:Contact"];
                [xmlWriter writeCharacters:note];
                [xmlWriter writeEndElement];

                [xmlWriter writeStartElement:@"sam:Location"];
                [xmlWriter writeCharacters:GPSPoint];
                [xmlWriter writeEndElement];

                [xmlWriter writeStartElement:@"sam:Uid"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];

                [xmlWriter writeEndElement];

                NSString* xml = [xmlWriter toString];

                [SVProgressHUD showWithStatus:@"Отправка..."];
                PutNewCustomerRequest    *sendNewCustomer = [PutNewCustomerRequest new];

                sendNewCustomer.custAccount = custAcc;

                [sendNewCustomer sendCustomer:xml];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
}

- (NSArray<NSString *> *)brandNamesForBrandIds:(NSArray *)brandIds {
    if (brandIds.count == 0) { return nil; }

    NSMutableArray<NSString *> *names = [NSMutableArray new];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select BrandName from Brand where BrandId = ?";
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            for (NSString *brandId in brandIds) {
                sqlite3_reset(statement);
                sqlite3_bind_text(statement, 1, [brandId UTF8String], -1, SQLITE_TRANSIENT);

                if (sqlite3_step(statement) == SQLITE_ROW) {
                    if (sqlite3_column_text(statement, 0)) {
                        NSString *name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                        if (name.length > 0) {
                            [names addObject:name];
                        }
                    }
                }
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }

    return names.count > 0 ? names : nil;
}

- (NSString *)lastSalesDateForBrand:(NSString *)custAcc {
    if (self.selectedBrandNames.count == 0) { return @"null"; }

    NSString *salesDate = @"null";

    NSMutableArray *quoted = [NSMutableArray new];
    for (NSString *brandName in self.selectedBrandNames) {
        NSString *escaped = [brandName stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        [quoted addObject:[NSString stringWithFormat:@"'%@'", escaped]];
    }
    NSString *inList = [quoted componentsJoinedByString:@","];

    NSString *squl = [NSString stringWithFormat:
        @"select s.SalesDate from SalesTable s "
         "join SalesLine l on s.SalesId = l.SalesId "
         "where s.CustAccount = ? and l.BrandName in (%@) "
         "order by s.SalesDateSort desc limit 1", inList];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, squl.UTF8String, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(statement) == SQLITE_ROW) {
                if (sqlite3_column_text(statement, 0))
                    salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }

    return salesDate;
}

- (NSString *)getLastSalesDate:(NSString *)custAcc {
    NSString *salesDate = @"null";

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select SalesDate from CustTable where CustAccount = ?";
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(statement) == SQLITE_ROW ) {
                if (sqlite3_column_text(statement, 0))
                    salesDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

    return salesDate;
}

- (BOOL)isLastSalesTP:(NSString *)custAcc {
    NSString *channel   = @"null";
    NSString *salesDate = @"null";
    BOOL     ret        = NO;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select ChannelTypeId, SalesDate from CustTable where CustAccount = ?";
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(statement) == SQLITE_ROW ) {
                if (sqlite3_column_text(statement, 0))
                    channel  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];

                if (sqlite3_column_text(statement, 1))
                    salesDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

    NSCalendar       *myCalendar    = [NSCalendar currentCalendar];
    NSDateFormatter  *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate           *currDate  = NSDate.date;

    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];

    NSDate *myDate = [dateFormatter dateFromString: salesDate];

    NSDateComponents *dateComponents = [myCalendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:myDate];

    if ([self isDateFalls:currDate withYourYear:[dateComponents year] andYourMonth:[dateComponents month]] && [channel isEqualToString:@"ТП"])
        ret = YES;
    else
        ret = false;

    return ret;
}

- (BOOL)isDateFalls:(NSDate *)date withYourYear:(NSInteger)year andYourMonth:(NSInteger)month {
    BOOL ret = NO;

    NSCalendar       *gregorian      = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [gregorian components:(NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];

    if (dateComponents.year == year && dateComponents.month == month)
        ret = YES;
    else
        ret = NO;

    return ret;
}

- (void)updateLastSalesTPDate:(NSString *)custAcc {
    const char *sql_2;

    sql_2 = "select SalesDate, SalesDateSort, ChannelTypeId from SalesTable where CustAccount = ? order by SalesDateSort desc limit 1";

    sqlite3_stmt *selstmt_2;

    if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selstmt_2, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);

        if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
            NSString *salesDate        = @"null";
            NSString *salesDateSort    = @"null";
            NSString *channel          = @"null";

            if (sqlite3_column_text(selstmt_2, 0))
                salesDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];

            if (sqlite3_column_text(selstmt_2, 1))
                salesDateSort  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 1)];

            if (sqlite3_column_text(selstmt_2, 2))
                channel  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 2)];

            const char *sql_3 = "update CustTable Set SalesDate = ?, SalesDateSort = ?, ChannelTypeId = ? where CustAccount = ?";

            sqlite3_stmt *updateStmt;

            if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(updateStmt, 1, [salesDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 2, [salesDateSort UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 3, [channel UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 4, [custAcc UTF8String], -1, SQLITE_TRANSIENT);

                sqlite3_step(updateStmt);
                sqlite3_finalize(updateStmt);
            }
        }
        sqlite3_finalize(selstmt_2);
    }
}

#pragma mark - Button styling methods && Helpers
- (UIBarButtonItem *)spacerButton {
    UIBarButtonItem *spacerButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacerButton.width = 5.0;
    return spacerButton;
}

- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}

@end
