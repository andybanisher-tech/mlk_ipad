//
//  CDSecondaryPassportViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 28.03.2025.
//

#import "CDSecondaryPassportViewController.h"

//VCs
#import "CameraViewController.h"
#import "HomeViewController.h"
#import "CDSecondaryPassportValuePickerViewController.h"

//ReusableViews
#import "CDSecondaryPassportCollectionHeaderView.h"

//Cells
#import "CDSecondaryPassportCollectionViewCell.h"

//Custom Objects
#import "Reachability.h"
#import "SendMerchData.h"

//Requests
#import "GetPropertiesListRequest.h"
#import "PutTTPropertiesValueRequest.h"

#import "sqlite3.h"

@interface CDSecondaryPassportViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, CDSecondaryPassportValuePickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

static sqlite3 *database = nil;

@implementation CDSecondaryPassportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareLayout];
    [self prepareDataSource];
    
    //Notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(ttPropetriesDidUpdate) name:@"ttPropertiesUpdated" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userDidSavePhoto) name:kTTPhotoSaved object:nil];
}

#pragma mark - UI
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

#pragma mark - Prepare Data
- (void)prepareDataSource {
    self.dataSource = [NSMutableArray new];
    NSMutableArray *requiredItems = [NSMutableArray new];
    NSMutableArray *additionalItems = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "SELECT mp.PropertyId, mp.PropertyType, mp.PropertyName, mp.isMultiple, mp.isRequired, CASE WHEN tpv.Value IS NULL THEN '' ELSE tpv.Value END AS Value, tpv.SendStatus, CASE WHEN tpv.ElementListId IS NULL THEN '' ELSE tpv.ElementListId END AS ElementListId, CASE WHEN tpv.Image IS NOT NULL THEN 1 ELSE 0 END AS imageExists FROM MerchTTProperties AS mp JOIN CustTable AS ct ON ct.CustAccount = ? AND ct.TTId = mp.TTId LEFT JOIN TTPropertiesValue AS tpv ON mp.PropertyId = tpv.PropertyId AND tpv.CustAccount = ct.CustAccount ORDER BY mp.PropertyName";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            sqlite3_bind_text(selectstmt, 1, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *passport = [NSMutableDictionary new];
                
                for (int i = 0; i < sqlite3_column_count(selectstmt); i++) {
                    if (sqlite3_column_text(selectstmt, i)) {
                        NSString *key = [NSString stringWithUTF8String:(char *)sqlite3_column_name(selectstmt, i)];
                        NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, i)];
                        
                        passport[key] = value;
                    }
                }
                
                if ([passport[@"isRequired"] boolValue]) {
                    [requiredItems addObject:passport];
                } else {
                    [additionalItems addObject:passport];
                }
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    if (requiredItems.count > 0) {
        [self.dataSource addObject:@{@"title" : @"ОБЯЗАТЕЛЬНЫЕ", @"items" : requiredItems}];
    }
    if (additionalItems.count > 0) {
        [self.dataSource addObject:@{@"title" : @"ДОПОЛНИТЕЛЬНЫЕ", @"items" : additionalItems}];
    }
    
    [self.mainCollectionView reloadData];
}

#pragma mark - Button Actions
- (IBAction)sendDataButtonTapped:(id)sender {
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

- (IBAction)updateFrom1CButtonTapped:(id)sender {
    [SVProgressHUD showWithStatus:@"Обновление из 1С"];
    
    GetPropertiesListRequest *propertiesListRequest = [GetPropertiesListRequest new];
    propertiesListRequest.syncTTPropertiesOnly = YES;
    [propertiesListRequest propListReq];
}

#pragma mark - Observers
- (void)ttPropetriesDidUpdate {
    [SVProgressHUD showSuccessWithStatus:@"Обновление прошло успешно"];
    [self prepareDataSource];
}

- (void)userDidSavePhoto {
    [self prepareDataSource];
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        CDSecondaryPassportCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass(CDSecondaryPassportCollectionHeaderView.class) forIndexPath:indexPath];
        
        NSDictionary *object = self.dataSource[indexPath.section];
        [headerView setTitle:object[@"title"]];
        
        return headerView;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.dataSource.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.dataSource[section][@"items"] count];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryPassportCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryPassportCollectionViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.section][@"items"][indexPath.item];
    [cell setData:object];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    NSDictionary *object = self.dataSource[indexPath.section][@"items"][indexPath.item];
    [self handleObjectSelection:object];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Allow only numbers
    NSCharacterSet *nonNumberSet = NSCharacterSet.decimalDigitCharacterSet.invertedSet;
    return [string stringByTrimmingCharactersInSet:nonNumberSet].length > 0 || [string isEqualToString:@""];
}

#pragma mark - CDSecondaryPassportValuePickerViewControllerDelegate
- (void)userDidPickValues:(NSArray *)values listIDs:(NSArray *)listIDs propertyID:(NSString *)propertyID {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString *value = [values componentsJoinedByString:@","];
    NSString *listID = [listIDs componentsJoinedByString:@","];
    [self saveValue:value propertyID:propertyID elementListID:listID];
}

#pragma mark - Working with data
- (void)handleObjectSelection:(NSDictionary *)object {
    NSString *type = object[@"PropertyType"];
    NSString *propertyID = object[@"PropertyId"];
    
    if ([type localizedStandardContainsString:@"list"]) {
        [self showPassportValuePickerVC:object];
    } else if ([type localizedStandardContainsString:@"bool"]) {
        [self saveBoolValue:object[@"Value"] propertyID:propertyID];
    } else if ([type localizedStandardContainsString:@"photo"]) {
        [self makePhoto:propertyID];
    } else if ([type localizedStandardContainsString:@"integer"] || [type localizedStandardContainsString:@"string"]){
        [self showTextValuePicker:object[@"Value"] propertyID:propertyID propertyType:type];
    }
}

- (void)saveBoolValue:(NSString *)value propertyID:(NSString *)propertyID {
    NSString *boolValue;
    if ([value localizedStandardContainsString:@"yes"]) {
        boolValue = @"No";
    } else {
        boolValue = @"Yes";
    }
    
    [self saveValue:boolValue propertyID:propertyID elementListID:@"null"];
}

- (void)makePhoto:(NSString *)propertyID {
    if (self.isCustInVisit) {
        CameraViewController *cameraVC = [CameraViewController new];
        cameraVC.custAccount = self.custAccount;
        cameraVC.inVisit = self.isCustInVisit;
        cameraVC.photoType = @"tt";
        cameraVC.propertyId = propertyID;
        
        cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:cameraVC animated:YES completion:nil];
    } else {
        [AlertWorkerObjc alertWithTitle:@"Для создания фотографии клиент должен быть в режиме посещения."];
    }
}

- (void)showPassportValuePickerVC:(NSDictionary *)object {
    CDSecondaryPassportValuePickerViewController *valuePickerVC = [[UIStoryboard storyboardWithName:@"CDSecondaryPassport" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CDSecondaryPassportValuePickerViewController.class)];
    valuePickerVC.delegate = self;
    
    NSString *value = object[@"Value"];
    valuePickerVC.selectedValues = value.length > 0 ? [value componentsSeparatedByString:@","].mutableCopy : [NSMutableArray new];
    NSString *elementListID = object[@"ElementListId"];
    valuePickerVC.selectedListIDs = elementListID.length > 0 ? [elementListID componentsSeparatedByString:@","].mutableCopy : [NSMutableArray new];
    valuePickerVC.propertyID = object[@"PropertyId"];
    valuePickerVC.isMultiple = [object[@"isMultiple"] boolValue];
    valuePickerVC.title = object[@"PropertyName"];
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:valuePickerVC];
    
    [self presentViewController:navVC animated:YES completion:nil];
}

- (void)showTextValuePicker:(NSString *)value propertyID:(NSString *)propertyID propertyType:(NSString *)propertyType {
    __weak typeof(self) weakSelf = self;
    
    NSString *title;
    UIKeyboardType keyboardType;
    id textFieldDelegate;
    if ([propertyType localizedStandardContainsString:@"integer"]) {
        title = @"Введите значение";
        keyboardType = UIKeyboardTypeNumberPad;
        textFieldDelegate = weakSelf;
    } else {
        title = @"Введите текст";
        keyboardType = UIKeyboardTypeDefault;
    }
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.delegate = textFieldDelegate;
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        textField.keyboardType = keyboardType;
        textField.text = value;
    }];
    
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Готово" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *newValue = alertVC.textFields.firstObject.text;
        [weakSelf saveValue:newValue propertyID:propertyID elementListID:@"null"];
    }];
    [alertVC addAction:doneAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:cancelAction];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)saveValue:(NSString *)value propertyID:(NSString *)propertyID elementListID:(NSString *)elementListID {
    NSDateFormatter *dateFormatter = NSDateFormatter.new;
    NSDate *date = NSDate.date;
    
    dateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    NSString *dateStr = [dateFormatter stringFromDate:date];
    
    dateFormatter.dateFormat = @"HH:mm:ss";
    NSString *timeStr = [dateFormatter stringFromDate:date];
    
    NSString *dateTimeStr = [NSString stringWithFormat:@"%@ %@", dateStr, timeStr];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *saveStmt;
        
        const char *sql = "INSERT INTO TTPropertiesValue (PropertyId, Value, Date, CustAccount, SendStatus, ttId, CreatedDateTime, ElementListId) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(PropertyId, CustAccount, Date) DO UPDATE SET Value = excluded.Value, SendStatus = excluded.SendStatus, ElementListId = excluded.ElementListId, ttId = excluded.ttId, CreatedDateTime = excluded.CreatedDateTime, Date = excluded.Date";
        
        if (sqlite3_prepare_v2(database, sql, -1, &saveStmt, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        }
        
        sqlite3_bind_text(saveStmt, 1, propertyID.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(saveStmt, 2, value.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(saveStmt, 3, dateStr.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(saveStmt, 4, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(saveStmt, 5, @"New".UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(saveStmt, 6, self.ttID.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(saveStmt, 7, dateTimeStr.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(saveStmt, 8, elementListID.UTF8String, -1, SQLITE_TRANSIENT);
        
        sqlite3_step(saveStmt);
        sqlite3_finalize(saveStmt);
    }
    sqlite3_close(database);
    
    [self prepareDataSource];
}

@end
