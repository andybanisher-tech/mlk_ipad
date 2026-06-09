//
//  CDPrimaryViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 30.08.2024.
//

#import "CDPrimaryViewController.h"

//CDSecondary VCs
#import "CDSecondaryMainViewController.h"
#import "CDSecondaryContactsViewController.h"
#import "CDSecondaryReferralCodeViewController.h"
#import "CDSecondaryReferralOrdersViewController.h"
#import "CDSecondaryPassportViewController.h"
#import "CDSecondaryBrandSalesPlanViewController.h"
#import "CDSecondaryAvailablePromosViewController.h"
#import "CDSecondaryTasksViewController.h"
#import "CDSecondaryCommentsViewController.h"
#import "CDSecondaryOrdersHistoryViewController.h"
#import "CDSecondaryPPLViewController.h"

//VCs
#import "AppDelegate.h"
#import "HomeViewController.h"
#import "SalesCreateView.h"
#import "ASPPDFReaderViewController.h"
#import "CustViewController.h"

//ReusableViews
#import "CDPrimaryCollectionHeaderView.h"

//Cells
#import "CDPrimaryHeaderCollectionViewCell.h"
#import "CDPrimaryCollectionViewCell.h"

//Requests
#import "PutClientsForPDZRequest.h"
#import "PDZFileRequest.h"

//Custom Objects//Custom Objects
#import "CDPrimarySection.h"
#import "CDPrimarySectionItem.h"

#import "sqlite3.h"

#import "GeneratedAssetSymbols.h"

@interface CDPrimaryViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;

@property (nonatomic, strong) NSMutableDictionary *customerDetails;
@property (nonatomic, strong) NSArray<CDPrimarySection *> *dataSource;

@end

static sqlite3 *database = nil;

@implementation CDPrimaryViewController {
    NSIndexPath *_selectedIndexPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self prepareLayout];
    [self prepareObservers];
    [self prepareData];
}

#pragma mark - Setup UI
- (void)setupNavBar {
    self.navigationItem.title = @"Карточка клиента";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    UINavigationBarAppearance *navBarAppearance = [UINavigationBarAppearance new];
    [navBarAppearance configureWithOpaqueBackground];
    navBarAppearance.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F7"];
    navBarAppearance.shadowColor = UIColor.clearColor;
    navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName : [ASPFunctions colorFromHex:@"4F4F4F"]};
    navBarAppearance.largeTitleTextAttributes = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:24.0], NSForegroundColorAttributeName : [ASPFunctions colorFromHex:@"4F4F4F"]};
    self.navigationController.navigationBar.standardAppearance = navBarAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
}

- (void)prepareLayout {
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> _Nonnull layoutEnvironment) {
        
        UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
        configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
        configuration.itemSeparatorHandler = ^UIListSeparatorConfiguration * _Nonnull(NSIndexPath * _Nonnull indexPath, UIListSeparatorConfiguration * _Nonnull sectionSeparatorConfiguration) {
            sectionSeparatorConfiguration.bottomSeparatorInsets = NSDirectionalEdgeInsetsZero;
            return sectionSeparatorConfiguration;
        };
        
        // Assign Header to only for the third Section
        if (section == 2) {
            configuration.headerMode = UICollectionLayoutListHeaderModeSupplementary;
        } else {
            configuration.headerMode = UICollectionLayoutListHeaderModeNone;
        }
        
        // Section
        NSCollectionLayoutSection *listSection = [NSCollectionLayoutSection sectionWithListConfiguration:configuration layoutEnvironment:layoutEnvironment];
        
        return listSection;
    }];
    
    self.mainCollectionView.collectionViewLayout = layout;
}

- (void)prepareObservers {
    //Observers
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pdzFileReceived:) name:@"pdzFileReceived" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(pdzFileRequestFailed:) name:@"pdzFileRequestFailed" object:nil];
}

#pragma mark - Data preparation
- (void)prepareData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *custDetails = @{@"CustAccount" : @{@"value" : self.custAccount, @"sort" : @(0)}}.mutableCopy;
        
        NSDateFormatter *dateFormatter = NSDateFormatter.new;
        dateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
        NSString *strDate = [dateFormatter stringFromDate:NSDate.date];
        
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            sqlite3_stmt *selectstmt;
            
            const char *sql = "select ct.Property6Name, ct.Name, ct.FactAddress, ct.Address, ct.LegalName, ct.INN, ct.KPP, ct.BankName, ct.BankAccount, ct.PDZAmount, ct.TTId, cfr.Status, CASE WHEN cfr.CustAccount IS NOT NULL THEN 1 ELSE 0 END as isInRoute, (SELECT COUNT(TaskId) FROM TaskTable WHERE CustAccount = ct.CustAccount AND Status IN ('Открытая', 'В работе')) AS tasksCount from CustTable as ct LEFT JOIN CustForRoute as cfr ON ct.CustAccount = cfr.CustAccount AND cfr.DateOfRoute = ? WHERE ct.CustAccount = ?";
            
            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, strDate.UTF8String, -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(selectstmt, 2, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(selectstmt) != SQLITE_DONE) {
                    for (int i = 0; i < sqlite3_column_count(selectstmt); i++) {
                        if (sqlite3_column_text(selectstmt, i)) {
                            NSString *key = [NSString stringWithUTF8String:(char *)sqlite3_column_name(selectstmt, i)];
                            NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, i)];
                            custDetails[key] = @{@"value" : value, @"sort" : @(i + 1)};
                        }
                    }
                }
            }
            sqlite3_finalize(selectstmt);
        }
        sqlite3_close(database);
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.customerDetails = custDetails;
            [self prepareDataSource];
            [self getBonusBalance];
        });
    });
}

- (void)prepareDataSource {
    self.dataSource = @[
        [self firstSection],
        [self secondSection],
        [self thirdSection],
        [self fourthSection],
        [self fifthSection],
        [self sixthSection]
    ];
    
    [self.mainCollectionView reloadData];
    
    NSIndexPath *indexPathToSelect = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.mainCollectionView selectItemAtIndexPath:indexPathToSelect animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.mainCollectionView didSelectItemAtIndexPath:indexPathToSelect];
}

#pragma mark - Networking
- (void)getBonusBalance {
    [APIWorker.sharedInstance getBonusBalance:self.custAccount completion:^(NSDictionary * _Nullable data, NSError * _Nullable error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        } else {
            [self updateBonusBalance:[data[@"SumBonus"] integerValue]];
        }
    }];
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        CDPrimaryCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass(CDPrimaryCollectionHeaderView.class) forIndexPath:indexPath];
        
        CDPrimarySection *object = self.dataSource[indexPath.section];
        [headerView setTitle:object.title];
        
        return headerView;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.dataSource.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource[section].items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDPrimarySectionItem *item = self.dataSource[indexPath.section].items[indexPath.row];
    
    if ([item.type isEqual:@"fullInfo"]) {
        CDPrimaryHeaderCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDPrimaryHeaderCollectionViewCell.class) forIndexPath:indexPath];
        [cell setItem:item];
        
        return cell;
    } else {
        CDPrimaryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDPrimaryCollectionViewCell.class) forIndexPath:indexPath];
        [cell setItem:item];
        
        return cell;
    }
}

#pragma mark - UICollectionViewDelegate
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    CDPrimarySectionItem *selectedItem = self.dataSource[indexPath.section].items[indexPath.row];
    NSString *type = selectedItem.type;
    
    if ([type isEqual:@"addToRoute"] ||
        [type isEqual:@"referralCode"] ||
        [type isEqual:@"createOrder"] ||
        [type isEqual:@"consult"] ||
        [type isEqual:@"refreshRemains"] ||
        [type isEqual:@"pdz"] ||
        [type isEqual:@"requestPDZ"]) {
        [self handleActionType:type];
        
        return NO;
    }
    
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_selectedIndexPath &&
        _selectedIndexPath.section == indexPath.section &&
        _selectedIndexPath.item == indexPath.item) {
        if (![self.splitViewController.viewControllers.lastObject isKindOfClass:UINavigationController.class]) { return; }
        
        UINavigationController *secondaryNavVC = self.splitViewController.viewControllers.lastObject;
        [secondaryNavVC popToRootViewControllerAnimated:YES];
    } else {
        _selectedIndexPath = indexPath;
        CDPrimarySectionItem *selectedItem = self.dataSource[indexPath.section].items[indexPath.row];
        [self handleNavigationType:selectedItem.type title:selectedItem.title];
    }
}

#pragma mark - Selection Handlers
- (void)handleNavigationType:(NSString *)type title:(NSString *)title {
    if (![self.splitViewController.viewControllers.lastObject isKindOfClass:UINavigationController.class]) { return; }
    
    UIViewController *detailVC;
    
    if ([type isEqual:@"fullInfo"]) {
        title = @"Полная информация";
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryMain" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryMainViewController.class)];
        [(CDSecondaryMainViewController *)detailVC setCustomerDetails:self.customerDetails];
    } else if ([type isEqual:@"contacts"]) {
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryContacts" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryContactsViewController.class)];
        [(CDSecondaryContactsViewController *)detailVC setCustAccount:self.custAccount];
    } else if ([type isEqual:@"referralOrders"]) {
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryReferralProgram" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryReferralOrdersViewController.class)];
        [(CDSecondaryReferralOrdersViewController *)detailVC setCustAccount:self.custAccount];
    } else if ([type isEqual:@"passport"]) {
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryPassport" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryPassportViewController.class)];
        [(CDSecondaryPassportViewController *)detailVC setCustAccount:self.custAccount];
        
        NSString *status = self.customerDetails[@"Status"][@"value"];
        NSString *ttID = self.customerDetails[@"TTId"][@"value"];
        
        [(CDSecondaryPassportViewController *)detailVC setTtID:ttID];
        [(CDSecondaryPassportViewController *)detailVC setIsCustInVisit:[status isEqual:@"visit"]];
    } else if ([type isEqual:@"brandSalesPlan"]) {
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryBrandSalesPlan" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryBrandSalesPlanViewController.class)];
        [(CDSecondaryBrandSalesPlanViewController *)detailVC setCustAccount:self.custAccount];
    } else if ([type isEqual:@"availablePromos"]) {
        CDSecondaryAvailablePromosViewController *promosVC = [CDSecondaryAvailablePromosViewController new];
        promosVC.custAccount = self.custAccount;
        detailVC = promosVC;
    } else if ([type isEqual:@"tasks"]) {
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryTasks" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryTasksViewController.class)];
        
        NSString *name = self.customerDetails[@"Name"][@"value"];
        NSString *status = self.customerDetails[@"Status"][@"value"];
        
        [(CDSecondaryTasksViewController *)detailVC setCustAccount:self.custAccount];
        [(CDSecondaryTasksViewController *)detailVC setCustName:name];
        [(CDSecondaryTasksViewController *)detailVC setIsCustInVisit:[status isEqual:@"visit"]];
    } else if ([type isEqual:@"comments"]) {
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryComments" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryCommentsViewController.class)];
        [(CDSecondaryCommentsViewController *)detailVC setCustAccount:self.custAccount];
    } else if ([type isEqual:@"ordersHistory"]) {
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryOrdersHistory" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryOrdersHistoryViewController.class)];
        
        NSString *name = self.customerDetails[@"Name"][@"value"];
        
        [(CDSecondaryOrdersHistoryViewController *)detailVC setCustAccount:self.custAccount];
        [(CDSecondaryOrdersHistoryViewController *)detailVC setCustName:name];
    } else if ([type isEqual:@"ppl"]) {
        detailVC = [[UIStoryboard storyboardWithName:@"CDSecondaryPPL" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryPPLViewController.class)];
        
        NSString *status = self.customerDetails[@"Status"][@"value"];
        
        [(CDSecondaryPPLViewController *)detailVC setCustAccount:self.custAccount];
        [(CDSecondaryPPLViewController *)detailVC setIsCustInVisit:[status isEqual:@"visit"]];
    }
    
    UINavigationController *secondaryNavVC = self.splitViewController.viewControllers.lastObject;
    detailVC.title = title;
    secondaryNavVC.viewControllers = @[detailVC];
}

- (void)handleActionType:(NSString *)type {
    if ([type isEqual:@"addToRoute"]) {
        [self addCustomerToRouteIfNeeded];
    } else if ([type isEqual:@"referralCode"]) {
        CDSecondaryReferralCodeViewController *referralCodeVC = [[UIStoryboard storyboardWithName:@"CDSecondaryReferralProgram" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryReferralCodeViewController.class)];
        [referralCodeVC setCustAccount:self.custAccount];
        [self presentViewController:referralCodeVC animated:YES completion:nil];
    } else if ([type isEqual:@"createOrder"] || [type isEqual:@"consult"]) {
        SalesCreateView *salesCreateVC = [[SalesCreateView alloc] initWithNibName:@"SalesCreateView" bundle: nil];
        
        NSString *name = self.customerDetails[@"Name"][@"value"];
        salesCreateVC.custName = name;
        salesCreateVC.custAccount = self.custAccount;
        salesCreateVC.isConsult = [type isEqual:@"consult"];
        
        UINavigationController *salesCreateNavVC = [[UINavigationController alloc] initWithRootViewController:salesCreateVC];
        salesCreateNavVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:salesCreateNavVC animated:YES completion:nil];
    } else if ([type isEqual:@"refreshRemains"]) {
        AppDelegate *appDelegateIPad = (AppDelegate *)UIApplication.sharedApplication.delegate;
        HomeViewController *homeViewController = appDelegateIPad.homeViewController;
        [homeViewController syncRemains];
    } else if ([type isEqual:@"pdz"]) {
        [self getPDZFile];
    } else if ([type isEqual:@"requestPDZ"]) {
        [self handlePDZRequestAction];
    }
}

#pragma mark - ActionType Helpers
- (void)addCustomerToRouteIfNeeded {
    BOOL isInRouteValue = [self.customerDetails[@"isInRoute"][@"value"] boolValue];
    if (isInRouteValue) { return; }
    
    NSMutableDictionary *isInRoute = [self.customerDetails[@"isInRoute"] mutableCopy];
    isInRoute[@"value"] = @(1);
    self.customerDetails[@"isInRoute"] = isInRoute;
    
    NSString *custName = self.customerDetails[@"Name"][@"value"];
    NSString *custAddress = self.customerDetails[@"Address"][@"value"];
    
    NSDateFormatter *dateFormatter = NSDateFormatter.new;
    dateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    
    NSString *strDate = [dateFormatter stringFromDate:NSDate.date];
    
    CustViewController *custVC = [CustViewController new];
    [custVC addCustomersToRoute:self.custAccount custName:custName custAddr:custAddress strDate:strDate];
    
    NSIndexPath *targetIndexPath;
    for (int i = 0; i < self.dataSource.count; i++) {
        NSArray *sectionItems = self.dataSource[i].items;
        
        CDPrimarySectionItem *addToRouteItem = [ASPFunctions firstObjectInArray:sectionItems where:^BOOL(CDPrimarySectionItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.type isEqual:@"addToRoute"];
        }];
        
        if (addToRouteItem) {
            addToRouteItem.title = @"В маршруте ✅";
            
            NSInteger item = [sectionItems indexOfObject:addToRouteItem];
            targetIndexPath = [NSIndexPath indexPathForItem:item inSection:i];
            
            break;
        } else {
            continue;
        }
    }
    
    [self reloadWithAnimationItemsAtIndexPaths:@[targetIndexPath]];
}

- (void)updateBonusBalance:(NSInteger)balance {
    NSIndexPath *targetIndexPath;
    for (int i = 0; i < self.dataSource.count; i++) {
        NSArray *sectionItems = self.dataSource[i].items;
        
        CDPrimarySectionItem *addToRouteItem = [ASPFunctions firstObjectInArray:sectionItems where:^BOOL(CDPrimarySectionItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.type isEqual:@"referralOrders"];
        }];
        
        if (addToRouteItem) {
            addToRouteItem.subtitle = [NSString stringWithFormat:@"Баланс баллов: %ld", (long)balance];
            
            NSInteger item = [sectionItems indexOfObject:addToRouteItem];
            targetIndexPath = [NSIndexPath indexPathForItem:item inSection:i];
            
            break;
        } else {
            continue;
        }
    }
    
    [self reloadWithAnimationItemsAtIndexPaths:@[targetIndexPath]];
}

- (void)handlePDZRequestAction {
    if ([self alreadyRequestedPDZ]) {
        [self getPDZFile];
    } else {
        [self requestPDZFileWithAlert];
    }
}

#pragma mark PDZ
- (BOOL)alreadyRequestedPDZ {
    NSDate *lastRequestDate = [PersistenceWorker load:[NSString stringWithFormat:@"pdzFileRequestDate_%@", self.custAccount]];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    return lastRequestDate && [calendar isDateInToday:lastRequestDate];
}

- (void)requestPDZFileWithAlert {
    [AlertWorkerObjc alertWithTitle:@"Запросить отчёт ПДЗ?" message:@"Подготовка отчёта может занять до 10 минут" buttons:@[@"Запросить", @"Отменить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index == 0) {
            [self sendPDZFileRequest];
        }
    }];
}

- (void)sendPDZFileRequest {
    [PersistenceWorker save:NSDate.date key:[NSString stringWithFormat:@"pdzFileRequestDate_%@", self.custAccount]];
    
    PutClientsForPDZRequest *sendPDZ = [PutClientsForPDZRequest new];
    [sendPDZ sendPDZ:self.custAccount];
    
    NSMutableArray *targetIndexPaths = [NSMutableArray new];
    for (int i = 0; i < self.dataSource.count; i++) {
        NSArray *sectionItems = self.dataSource[i].items;
        
        CDPrimarySectionItem *pdzItem = [ASPFunctions firstObjectInArray:sectionItems where:^BOOL(CDPrimarySectionItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.type isEqual:@"pdz"];
        }];
        
        if (pdzItem) {
            pdzItem.isEnabled = YES;
            
            CDPrimarySectionItem *requestPDZItem = [ASPFunctions firstObjectInArray:sectionItems where:^BOOL(CDPrimarySectionItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj.type isEqual:@"requestPDZ"];
            }];
            requestPDZItem.title = @"Проверить готовность отчёта";
            
            NSInteger pdzIndex = [sectionItems indexOfObject:pdzItem];
            NSIndexPath *pdzIndexPath = [NSIndexPath indexPathForItem:pdzIndex inSection:i];
   
            NSInteger requestPDZIndex = [sectionItems indexOfObject:requestPDZItem];
            NSIndexPath *requestPDZIndexPath = [NSIndexPath indexPathForItem:requestPDZIndex inSection:i];
            
            [targetIndexPaths addObjectsFromArray:@[pdzIndexPath, requestPDZIndexPath]];
            
            break;
        } else {
            continue;
        }
    }
    
    [self reloadWithAnimationItemAtIndexPath:targetIndexPaths delay:0.5];
}

- (void)getPDZFile {
    PDZFileRequest *pdzFileRequest = [PDZFileRequest new];
    pdzFileRequest.custAccount = self.custAccount;
    [pdzFileRequest fileReq];
}

#pragma mark - Notifications
- (void)pdzFileReceived:(NSNotification *)notification {
    if ([notification.object isKindOfClass:NSData.class]) {
        ASPPDFReaderViewController *pdfReaderVC = [[ASPPDFReaderViewController alloc] initWithPdfData:notification.object];
        [self presentViewController:pdfReaderVC animated:YES completion:nil];
    }
}

- (void)pdzFileRequestFailed:(NSNotification *)notification {
    if ([notification.object isKindOfClass:NSString.class]) {
        [AlertWorkerObjc alertWithTitle:@"Отчёт ещё не готов" message:@"Запросить повторно?\nПодготовка отчёта может занять до 10 минут" buttons:@[@"Подождать", @"Запросить"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
            if (index == 1) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self sendPDZFileRequest];
                });
            }
        }];
    }
}

#pragma mark - Data Helpers
- (CDPrimarySection *)firstSection {
    CDPrimarySectionItem *fullInfoItem = [CDPrimarySectionItem new];
    fullInfoItem.type = @"fullInfo";
    fullInfoItem.title = self.customerDetails[@"Name"][@"value"];
    
    NSString *subtitle = self.customerDetails[@"CustAccount"][@"value"];
    NSString *property6Name = self.customerDetails[@"Property6Name"][@"value"];
    
    if (property6Name.length > 0) {
        subtitle = [NSString stringWithFormat:@"%@, %@", subtitle, property6Name];
    }
    fullInfoItem.subtitle = subtitle;
    
    CDPrimarySectionItem *addToRouteItem = [CDPrimarySectionItem new];
    addToRouteItem.type = @"addToRoute";
    
    BOOL isInRoute = [self.customerDetails[@"isInRoute"][@"value"] boolValue];
    addToRouteItem.title = isInRoute ? @"В маршруте ✅" : @"Добавить в маршрут";
    
    return [[CDPrimarySection alloc] initWithTitle:nil items:@[fullInfoItem, addToRouteItem]];
}

- (CDPrimarySection *)secondSection {
    CDPrimarySectionItem *contactsItem = [CDPrimarySectionItem new];
    contactsItem.type = @"contacts";
    contactsItem.icon = [UIImage imageNamed:ACImageNameCDContacts];
    contactsItem.title = @"Контакты";
    
    return [[CDPrimarySection alloc] initWithTitle:nil items:@[contactsItem]];
}

- (CDPrimarySection *)thirdSection {
    CDPrimarySectionItem *referralCodeItem = [CDPrimarySectionItem new];
    referralCodeItem.type = @"referralCode";
    referralCodeItem.icon = [UIImage imageNamed:ACImageNameCDReferralCode];
    referralCodeItem.title = @"Код для клиентов";
    
    CDPrimarySectionItem *referralOrdersItem = [CDPrimarySectionItem new];
    referralOrdersItem.type = @"referralOrders";
    referralOrdersItem.icon = [UIImage imageNamed:ACImageNameCDReferralOrders];
    referralOrdersItem.title = @"Заказы клиентов";
    
    return [[CDPrimarySection alloc] initWithTitle:@"Реферальная программа" items:@[referralCodeItem, referralOrdersItem]];
}

- (CDPrimarySection *)fourthSection {
    CDPrimarySectionItem *passportItem = [CDPrimarySectionItem new];
    passportItem.type = @"passport";
    passportItem.icon = [UIImage imageNamed:ACImageNameCDPassport];
    passportItem.title = @"Паспорт точки";
    
    CDPrimarySectionItem *availablePromosItem = [CDPrimarySectionItem new];
    availablePromosItem.type = @"availablePromos";
    availablePromosItem.icon = [self availablePromosIcon];
    availablePromosItem.title = @"Доступные акции";

    CDPrimarySectionItem *brandSalesPlanItem = [CDPrimarySectionItem new];
    brandSalesPlanItem.type = @"brandSalesPlan";
    brandSalesPlanItem.icon = [UIImage imageNamed:ACImageNameCDBrandSalesPlan];
    brandSalesPlanItem.title = @"План по марке";
    
    CDPrimarySectionItem *tasksItem = [CDPrimarySectionItem new];
    tasksItem.type = @"tasks";
    tasksItem.icon = [UIImage imageNamed:ACImageNameCDTasks];
    tasksItem.title = @"Задачи";
    
    NSInteger tasksCount = [self.customerDetails[@"tasksCount"][@"value"] integerValue];
    
    if (tasksCount > 0) {
        tasksItem.titleDetail = [NSString stringWithFormat:@"(%ld)", (long)tasksCount];
    }
    
    CDPrimarySectionItem *commentsItem = [CDPrimarySectionItem new];
    commentsItem.type = @"comments";
    commentsItem.icon = [UIImage imageNamed:ACImageNameCDComments];
    commentsItem.title = @"Заметки";
    
    return [[CDPrimarySection alloc] initWithTitle:nil items:@[passportItem, availablePromosItem, brandSalesPlanItem, tasksItem, commentsItem]];
}

- (CDPrimarySection *)fifthSection {
    CDPrimarySectionItem *ordersHistoryItem = [CDPrimarySectionItem new];
    ordersHistoryItem.type = @"ordersHistory";
    ordersHistoryItem.icon = [UIImage imageNamed:ACImageNameCDOrdersHistory];
    ordersHistoryItem.title = @"История заказов";
    
    CDPrimarySectionItem *createOrderItem = [CDPrimarySectionItem new];
    createOrderItem.type = @"createOrder";
    createOrderItem.icon = [UIImage imageNamed:ACImageNameCDCreateOrder];
    createOrderItem.title = @"Создать заказ...";
    createOrderItem.titleColor = [UIColor colorNamed:ACColorNameMLKLightBlue];
    
    CDPrimarySectionItem *consultItem = [CDPrimarySectionItem new];
    consultItem.type = @"consult";
    consultItem.icon = [UIImage imageNamed:ACImageNameCDConsult];
    consultItem.title = @"Консультация";
    consultItem.titleColor = [UIColor colorNamed:ACColorNameMLKLightBlue];
    
    NSString *status = self.customerDetails[@"Status"][@"value"];
    NSString *consult = [PersistenceWorker load:@"consult"];
    consultItem.isEnabled = [status isEqual:@"visit"] && [consult isEqual:@"1"];
    
    CDPrimarySectionItem *refreshRemainsItem = [CDPrimarySectionItem new];
    refreshRemainsItem.type = @"refreshRemains";
    refreshRemainsItem.title = @"Обновить остатки";
    refreshRemainsItem.titleColor = [UIColor colorNamed:ACColorNameMLKLightBlue];
    
    return [[CDPrimarySection alloc] initWithTitle:nil items:@[ordersHistoryItem, createOrderItem, consultItem, refreshRemainsItem]];
}

- (CDPrimarySection *)sixthSection {
    CDPrimarySectionItem *pplItem = [CDPrimarySectionItem new];
    pplItem.type = @"ppl";
    pplItem.icon = [UIImage imageNamed:ACImageNameCDPPL];
    pplItem.title = @"Персональный прайс-лист";
    
    CDPrimarySectionItem *pdzItem = [CDPrimarySectionItem new];
    pdzItem.type = @"pdz";
    pdzItem.icon = [UIImage imageNamed:ACImageNameCDPDZ];
    
    NSString *pdzAmount = self.customerDetails[@"PDZAmount"][@"value"];
    if (pdzAmount.doubleValue != 0.0) {
        pdzItem.title = @"отчёт ПДЗ:";
        pdzItem.titleDetail = [NSString stringWithFormat:@"%@ руб.", pdzAmount];
    } else {
        pdzItem.title = @"отчёт ПДЗ";
    }
    pdzItem.isEnabled = [self alreadyRequestedPDZ];
    
    CDPrimarySectionItem *requestPDZItem = [CDPrimarySectionItem new];
    requestPDZItem.type = @"requestPDZ";
    requestPDZItem.title = [self alreadyRequestedPDZ] ? @"Проверить готовность отчёта" : @"Запросить отчёт ПДЗ";
    requestPDZItem.titleColor = [UIColor colorNamed:ACColorNameMLKLightBlue];
    
    return [[CDPrimarySection alloc] initWithTitle:nil items:@[pplItem, pdzItem, requestPDZItem]];
}

- (UIImage *)availablePromosIcon {
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:22.0 weight:UIImageSymbolWeightSemibold];
    UIImage *symbol = [UIImage systemImageNamed:@"megaphone.fill" withConfiguration:cfg];
    return [symbol imageWithTintColor:UIColor.systemRedColor renderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - UI Helpers
- (void)reloadWithAnimationItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [self reloadWithAnimationItemAtIndexPath:indexPaths delay:0.0];
}

- (void)reloadWithAnimationItemAtIndexPath:(NSArray<NSIndexPath *> *)indexPaths delay:(NSTimeInterval)delay {
    if (indexPaths.count < 1) { return; }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mainCollectionView performBatchUpdates:^{
            [self.mainCollectionView reloadItemsAtIndexPaths:indexPaths];
        } completion:nil];
    });
}

@end
