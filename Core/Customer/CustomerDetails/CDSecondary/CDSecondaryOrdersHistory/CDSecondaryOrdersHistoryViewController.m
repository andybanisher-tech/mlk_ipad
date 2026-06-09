//
//  CDSecondaryOrdersHistoryViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 25.09.2024.
//

#import "CDSecondaryOrdersHistoryViewController.h"

//VCs
#import "SalesLineView.h"

//Cells
#import "CDSecondaryOrdersHistoryCollectionViewCell.h"

//Requests
#import "GetOrdersRequest.h"
#import "PutOrdersNewRequest.h"

//Custom Objects
#import "XMLWriter.h"

#import "sqlite3.h"

@interface CDSecondaryOrdersHistoryViewController () <UICollectionViewDataSource, UICollectionViewDelegate, SalesLineViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

static sqlite3 *database = nil;

@implementation CDSecondaryOrdersHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareLayout];
    [self prepareObservers];
    [self prepareDataSource];
}

#pragma mark - Setup UI
- (void)prepareLayout {
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    configuration.headerMode = UICollectionLayoutListHeaderModeSupplementary;
    configuration.itemSeparatorHandler = ^UIListSeparatorConfiguration * _Nonnull(NSIndexPath * _Nonnull indexPath, UIListSeparatorConfiguration * _Nonnull sectionSeparatorConfiguration) {
        sectionSeparatorConfiguration.bottomSeparatorInsets = NSDirectionalEdgeInsetsZero;
        return sectionSeparatorConfiguration;
    };
    
    UICollectionViewCompositionalLayout *layout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];
    self.mainCollectionView.collectionViewLayout = layout;
}

- (void)prepareObservers {
    //Observers
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(salesUpdated:) name:@"SalesUpdated" object:nil];
     [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(salesSended:) name:@"SalesSended" object:nil];
}

#pragma mark - Data preparation
- (void)prepareDataSource {
    self.dataSource = [NSMutableArray new];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            sqlite3_stmt *selectstmt;
            
            const char *sql = "select SalesId, ContractId, SalesDate, AmountSum, SalesNum, ChannelTypeId, SalesStatus, ActionType, Num1C, DeliveryDate from SalesTable where CustAccount = ?";
            
            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
                
                while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                    NSMutableDictionary *order = [NSMutableDictionary new];
                    
                    for (int i = 0; i < sqlite3_column_count(selectstmt); i++) {
                        if (sqlite3_column_text(selectstmt, i)) {
                            NSString *key = [NSString stringWithUTF8String:(char *)sqlite3_column_name(selectstmt, i)];
                            order[key] = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, i)];
                        }
                    }
                    
                    [self.dataSource addObject:order];
                }
            }
            sqlite3_finalize(selectstmt);
        }
        sqlite3_close(database);
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self.mainCollectionView reloadData];
        });
    });
}

- (BOOL)salesLineExists:(NSString *)salesID {
    BOOL exists = NO;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select 1 from SalesLine where SalesId = ?";
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, salesID.UTF8String, -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                exists = YES;
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    return exists;
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CDSecondaryOrdersHistorySectionHeaderView" forIndexPath:indexPath];
        return headerView;
    }
    
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryOrdersHistoryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryOrdersHistoryCollectionViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.item];
    [cell setOrder:object];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    NSDictionary *order = self.dataSource[indexPath.item];
    if ([self salesLineExists:order[@"SalesId"]]) {
        [self openSalesLine:order];
    } else {
        [self requestSalesLine:order[@"Num1C"]];
    }
}

#pragma mark - Selection Handlers
- (void)requestSalesLine:(NSString *)salesNum1C {
    GetOrdersRequest *salesLineRequest = [GetOrdersRequest new];
    salesLineRequest.synsSalesLine = YES;
    salesLineRequest.syncNum1C = salesNum1C;
    
    [salesLineRequest salesLineReq:salesNum1C];
}

- (void)openSalesLine:(NSDictionary *)order {
    SalesLineView *salesLineVC = [[SalesLineView alloc] initWithNibName: @"SalesLineView" bundle: nil];
    salesLineVC.delegate = self;
    
    salesLineVC.customer = self.custName;
    salesLineVC.salesId = order[@"SalesId"];
    salesLineVC.sumAmount = order[@"AmountSum"];
    salesLineVC.num1C = order[@"Num1C"];
    
    BOOL isOpen = [order[@"SalesStatus"] isEqual:@"Открыт"] || [order[@"SalesStatus"] isEqual:@"Ошибка"];
    salesLineVC.isOpen = isOpen && !order[@"Num1C"];
    
    UINavigationController *salesLineNavVC = [[UINavigationController alloc] initWithRootViewController:salesLineVC];
    salesLineNavVC.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:salesLineNavVC animated:YES completion:nil];
}

#pragma mark - SalesLineViewDelegate
- (void)userDidSendSales:(NSString *)salesID {
    [self sendSales:salesID salesUUID:nil];
}

- (void)sendSales:(NSString *)salesID salesUUID:(nullable NSString *)salesUUID {
    [SVProgressHUD showWithStatus:@"Отправка..."];
    
    XMLWriter* xmlWriter = [XMLWriter new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select SalesDate, StoreID, CustAccount, ContractId, AmountSum, ChannelTypeId, SalesStatus, Comment, SalesUUID, DeliveryDate, CreatedTime, ActionId, FirmId, Merge from SalesTable where SalesId = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [salesID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *salesDate = @"";
                NSString *storeID = @"";
                NSString *custAcc = @"";
                NSString *contractId = @"";
                NSString *amountSum = @"";
                NSString *channelTypeId = @"";
                NSString *salesStatus = @"";
                NSString *comment = @"";
                NSString *uuid = @"";
                NSString *dlvDate = @"";
                NSString *crTime = @"";
                NSString *actionId = @"";
                NSString *f_id = @"";
                NSString *merge = @"0";
                
                if (sqlite3_column_text(selectstmt, 0)) {
                    salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                }
                    
                if (sqlite3_column_text(selectstmt, 1)) {
                    storeID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
                    
                if (sqlite3_column_text(selectstmt, 2)) {
                    custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                }
   
                if (sqlite3_column_text(selectstmt, 3)) {
                    contractId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                }
                    
                if (sqlite3_column_text(selectstmt, 4)) {
                    amountSum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                }
                    
                if (sqlite3_column_text(selectstmt, 5)) {
                    channelTypeId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                }
                
                if (sqlite3_column_text(selectstmt, 6)) {
                    salesStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                }
                
                if (sqlite3_column_text(selectstmt, 7)) {
                    comment = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                }
                    
                if (salesUUID) {
                    uuid = salesUUID;
                } else if (sqlite3_column_text(selectstmt, 8)) {
                    uuid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                }
                
                if (sqlite3_column_text(selectstmt, 9)) {
                    dlvDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                }
                
                if (sqlite3_column_text(selectstmt, 10)) {
                    crTime = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                }
                
                if (sqlite3_column_text(selectstmt, 11)) {
                    actionId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                }
                
                if (sqlite3_column_text(selectstmt, 12)) {
                    f_id = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 12)];
                }
                   
                if (sqlite3_column_text(selectstmt, 13)) {
                    merge = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 13)];
                }
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:SalesNum"];
                [xmlWriter writeCharacters:salesID];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesDate"];
                [xmlWriter writeCharacters:salesDate];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:StoreID"];
                [xmlWriter writeCharacters:storeID];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ContractID"];
                [xmlWriter writeCharacters:contractId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:AmountSum"];
                [xmlWriter writeCharacters:amountSum];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ChannelTypeID"];
                [xmlWriter writeCharacters:channelTypeId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesStatus"];
                [xmlWriter writeCharacters:salesStatus];
                [xmlWriter writeEndElement];

                [xmlWriter writeStartElement:@"sam:Comment"];
                [xmlWriter writeCharacters:comment];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:SalesUUID"];
                [xmlWriter writeCharacters:uuid];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:DeliveryDate"];
                [xmlWriter writeCharacters:dlvDate];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CreatedTime"];
                [xmlWriter writeCharacters:crTime];
                [xmlWriter writeEndElement];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                NSDate *today = NSDate.date;
                [dateFormatter setDateFormat:@"HH:mm:ss"];
                NSString *sendTime = [dateFormatter stringFromDate:today];
                
                [self updateSalesTable:salesID sendTime:sendTime];
                
                [xmlWriter writeStartElement:@"sam:SendTime"];
                [xmlWriter writeCharacters:sendTime];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ActionID"];
                [xmlWriter writeCharacters:actionId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:FirmID"];
                [xmlWriter writeCharacters:f_id];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:NoMerge"];
                [xmlWriter writeCharacters:merge];
                [xmlWriter writeEndElement];
                
                const char *sql_1;
                
                sql_1 = "select ItemId, Qty, LineAmount, StoreID, isBadProduct from SalesLine where SalesId = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK) {
                    sqlite3_bind_text(selstmt, 1, [salesID UTF8String], -1, SQLITE_TRANSIENT);
                    
                    while (sqlite3_step(selstmt) == SQLITE_ROW) {
                        NSString *itemID = @"null";
                        NSString *qty = @"null";
                        NSString *lineAmount = @"null";
                        NSString *storeID = @"null";
                        NSString *isBadProduct;
                        
                        if (sqlite3_column_text(selstmt, 0))
                            itemID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                        
                        if (sqlite3_column_text(selstmt, 1))
                            qty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 1)];
                        
                        if (sqlite3_column_text(selstmt, 2))
                            lineAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 2)];
                        
                        if (sqlite3_column_text(selstmt, 3))
                            storeID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 3)];
                        
                        if (sqlite3_column_text(selstmt, 4))
                            isBadProduct = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 4)];
                        
                        [xmlWriter writeStartElement:@"sam:SalesLines"];
                        
                        if ([isBadProduct isEqual:@"Y"]) {
                            NSArray *itemIDComponents = [itemID componentsSeparatedByString:@"/"];
                            itemID = itemIDComponents.firstObject;
                        }
                        [xmlWriter writeStartElement:@"sam:ItemID"];
                        [xmlWriter writeCharacters:itemID];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:Qty"];
                        [xmlWriter writeCharacters:qty];
                        [xmlWriter writeEndElement];
                        
                        NSString *price = [NSString stringWithFormat:@"%0.2lf", lineAmount.doubleValue / qty.doubleValue];
                        [xmlWriter writeStartElement:@"sam:Price"];
                        [xmlWriter writeCharacters:price];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:LineAmount"];
                        [xmlWriter writeCharacters:lineAmount];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeStartElement:@"sam:StoreID"];
                        [xmlWriter writeCharacters:storeID];
                        [xmlWriter writeEndElement];
                        
                        [xmlWriter writeEndElement];
                        
                        itemID = nil;
                        qty = nil;
                        lineAmount = nil;
                        storeID = nil;
                        isBadProduct = nil;
                    }
                }
                sqlite3_finalize(selstmt);
                
                [xmlWriter writeEndElement];
                
                salesDate = nil;
                storeID = nil;
                custAcc = nil;
                contractId = nil;
                amountSum = nil;
                channelTypeId = nil;
                salesStatus = nil;
                comment = nil;
                uuid = nil;
                dlvDate = nil;
                crTime = nil;
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];

    PutOrdersNewRequest *setSalesToServer = [PutOrdersNewRequest new];
    [setSalesToServer sendSales:xml];
    setSalesToServer.salesId = salesID;
}

- (void)updateSalesTable:(NSString *)salesId sendTime:(NSString *)sendTime {
    const char *sql_2 = "update SalesTable Set SendTime = ? where SalesId = ?";
    
    sqlite3_stmt *updateStmt;
    
    if (sqlite3_prepare_v2(database, sql_2, -1, &updateStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(updateStmt, 1, [sendTime UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
}

#pragma mark - Notifications
- (void)salesUpdated:(NSNotification *)notification {
    NSString *updatedSalesNum1C = notification.object;
    NSDictionary *order = [ASPFunctions firstObjectInArray:self.dataSource where:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj[@"Num1C"] isEqual:updatedSalesNum1C];
    }];
    
    if (order) {
        [self openSalesLine:order];
    }
}

- (void)salesSended:(NSNotification *)notification {
    if (self.parentViewController.presentedViewController) {
        NSDictionary *object = notification.object;
        if ([object[@"salesStatus"] localizedStandardContainsString:@"новый заказ"]) {
            [SVProgressHUD dismiss];
            [AlertWorkerObjc alertWithTitle:@"Изменение реализации невозможно, создать новый заказ?" message:nil buttons:@[@"Да", @"Нет"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
                if (index == 0) {
                    [self sendSales:object[@"salesID"] salesUUID:NSUUID.UUID.UUIDString];
                }
            }];
        } else {
            [SVProgressHUD showInfoWithStatus:object[@"salesStatus"]];
            [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

@end
