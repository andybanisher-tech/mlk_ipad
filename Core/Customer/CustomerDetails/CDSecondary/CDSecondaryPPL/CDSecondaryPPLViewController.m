//
//  CDSecondaryPPLViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 27.03.2025.
//

#import "CDSecondaryPPLViewController.h"

//VCs
#import "CameraViewController.h"
#import "HomeViewController.h"

//ReusableViews
#import "CDSecondaryPPLCollectionHeaderView.h"

//Cells
#import "CDSecondaryPPLCollectionViewCell.h"

//Custom Objects
#import "Reachability.h"
#import "SendMerchData.h"

#import "sqlite3.h"

#import "GeneratedAssetSymbols.h"

@interface CDSecondaryPPLViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSArray *sortedDataSource;

//Sort
@property (nonatomic, assign) BOOL applyStatusDNSort;

@end

static sqlite3 *database = nil;

@implementation CDSecondaryPPLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self prepareLayout];
    [self prepareDataSource];
    
    //Notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userDidSavePhoto) name:@"BrandImageSaved" object:nil];
}

#pragma mark - UI
- (void)setupNavBar {
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    
    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:@"Отправить данные" attributes:@{
        NSFontAttributeName : [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold]
    }];
    config.attributedTitle = attrTitle;
    config.image = [UIImage systemImageNamed:@"dock.arrow.up.rectangle"];
    config.imagePadding = 2.0;
    config.imagePlacement = NSDirectionalRectEdgeLeading;
    config.preferredSymbolConfigurationForImage = [UIImageSymbolConfiguration configurationWithPointSize:16.0 weight:UIImageSymbolWeightMedium scale:UIImageSymbolScaleLarge];
    
    UIButton *sendDataButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendDataButton addTarget:self action:@selector(sendDataButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    sendDataButton.configuration = config;
    sendDataButton.tintColor = [UIColor colorNamed:ACColorNameMLKBlue];
    
    UIBarButtonItem *sendDataBarButton = [[UIBarButtonItem alloc] initWithCustomView:sendDataButton];
    self.navigationItem.leftBarButtonItem = sendDataBarButton;
}

- (void)prepareLayout {
    //Constants
    CGFloat globalHeaderHeight = 50.0;
    
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> _Nonnull layoutEnvironment) {
        
        UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
        configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
        configuration.itemSeparatorHandler = ^UIListSeparatorConfiguration * _Nonnull(NSIndexPath * _Nonnull indexPath, UIListSeparatorConfiguration * _Nonnull sectionSeparatorConfiguration) {
            sectionSeparatorConfiguration.bottomSeparatorInsets = NSDirectionalEdgeInsetsZero;
            return sectionSeparatorConfiguration;
        };
        
        // Section
        NSCollectionLayoutSection *listSection = [NSCollectionLayoutSection sectionWithListConfiguration:configuration layoutEnvironment:layoutEnvironment];
        
        //GlobalHeader
        NSCollectionLayoutSize *headerSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension absoluteDimension:globalHeaderHeight]];
        NSCollectionLayoutBoundarySupplementaryItem *globalHeader = [NSCollectionLayoutBoundarySupplementaryItem boundarySupplementaryItemWithLayoutSize:headerSize elementKind:UICollectionElementKindSectionHeader alignment:NSRectAlignmentTop absoluteOffset:CGPointMake(0.0, globalHeaderHeight / 2.0)];
        globalHeader.pinToVisibleBounds = YES;
        globalHeader.zIndex = CGFLOAT_MAX;
        
        // Assign Header to only for the first Section
        if (section == 0) {
            listSection.boundarySupplementaryItems = @[globalHeader];
        }
        
        return listSection;
    }];

    self.mainCollectionView.collectionViewLayout = layout;
}

#pragma mark - Prepare Data
- (void)prepareDataSource {
    self.dataSource = [NSMutableArray new];
    
    NSDateFormatter *dateFormatter = NSDateFormatter.new;
    dateFormatter.dateFormat = dateFormat_dd_MM_YYYY;

    NSString *dateStr = [dateFormatter stringFromDate:NSDate.date];

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "SELECT p.BrandId, p.ComDiscount, p.NeedPhoto, p.Delay, b.BrandName, c.Status, CASE WHEN pv.Image IS NOT NULL THEN 1 ELSE 0 END as imageExists FROM PersonalPriceList as p JOIN Brand as b ON p.BrandId = b.BrandId LEFT JOIN CustStatusDNBrand as c ON p.BrandId = c.BrandId AND p.CustAccount = c.CustAccount LEFT JOIN PropertiesValue as pv ON p.BrandId = pv.BrandId AND p.CustAccount = pv.CustAccount AND pv.GroupId = ? AND pv.PropertyId = ? AND pv.Date = ? WHERE p.CustAccount = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            sqlite3_bind_text(selectstmt, 1, @"".UTF8String, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, @"г00000009".UTF8String, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 3, dateStr.UTF8String, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 4, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *ppl = [NSMutableDictionary new];
                
                for (int i = 0; i < sqlite3_column_count(selectstmt); i++) {
                    if (sqlite3_column_text(selectstmt, i)) {
                        NSString *key = [NSString stringWithUTF8String:(char *)sqlite3_column_name(selectstmt, i)];
                        NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, i)];
                        ppl[key] = value;
                    }
                }
                
                [self.dataSource addObject:ppl];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self applySort];
}

#pragma mark - Button Actions
- (void)sendDataButtonTapped {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        [AlertWorkerObjc alertWithTitle:@"Отсутствует интернет соединение"];
    } else {
        SendMerchData *sendData = [SendMerchData new];
        sendData.custAccount = self.custAccount;
        [sendData sendGroupPropertiesValue];
        
        PutTTPropertiesValueRequest *request = [PutTTPropertiesValueRequest new];
        request.custAccount = self.custAccount;
        request.withoutProgress = YES;
        [request sendTTPropertiesValue];
        
        HomeViewController *homeVC = [HomeViewController new];
        homeVC.showSyncProgress = NO;
        [homeVC runSyncFromOtherView:self.custAccount];
    }
}

#pragma mark - Observers
- (void)userDidSavePhoto {
    [self prepareDataSource];
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        CDSecondaryPPLCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass(CDSecondaryPPLCollectionHeaderView.class) forIndexPath:indexPath];

        __weak typeof(self) weakSelf = self;
        headerView.onHeaderSortButtonTapped = ^{
            weakSelf.applyStatusDNSort = !weakSelf.applyStatusDNSort;
            [weakSelf applySort];
        };
        
        return headerView;
    }
    
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.sortedDataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryPPLCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryPPLCollectionViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.sortedDataSource[indexPath.item];
    [cell setPPL:object];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    if (self.isCustInVisit) {
        NSDictionary *object = self.sortedDataSource[indexPath.item];
        
        CameraViewController *cameraVC = [CameraViewController new];
        cameraVC.brandId = object[@"BrandId"];
        cameraVC.custAccount = self.custAccount;
        cameraVC.groupId = @"";
        cameraVC.inVisit = self.isCustInVisit;
        cameraVC.photoType = @"mark";
        cameraVC.propertyId = @"г00000009";
        
        cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:cameraVC animated:YES completion:nil];
    } else {
        [AlertWorkerObjc alertWithTitle:@"Для создания фотографии клиент должен быть в режиме посещения."];
    }
}

#pragma mark - Data Helpers
- (void)applySort {
    if (!self.applyStatusDNSort) {
        self.sortedDataSource = self.dataSource;
    } else {
        self.sortedDataSource = [self.dataSource sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSString *status1 = obj1[@"Status"] ?: @"";
            NSString *status2 = obj2[@"Status"] ?: @"";
            
            // "Работает" statuses first
            BOOL isWorking1 = [status1 isEqualToString:@"Работает"];
            BOOL isWorking2 = [status2 isEqualToString:@"Работает"];
            
            if (isWorking1 != isWorking2) {
                return isWorking1 ? NSOrderedAscending : NSOrderedDescending;
            }
            
            // Empty statuses last
            BOOL isEmpty1 = status1.length == 0;
            BOOL isEmpty2 = status2.length == 0;
            
            if (isEmpty1 != isEmpty2) {
                return isEmpty1 ? NSOrderedDescending : NSOrderedAscending;
            }
            
            // Maintain original order
            return NSOrderedSame;
        }];
    }
    
    [self.mainCollectionView reloadData];
}

@end
