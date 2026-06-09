//
//  CDSecondaryCommentsViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 27.03.2025.
//

#import "CDSecondaryCommentsViewController.h"

//Cells
#import "CDSecondaryCommentCollectionViewCell.h"

//Requests
#import "PutCommentsRequest.h"

#import "sqlite3.h"

@interface CDSecondaryCommentsViewController () <UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

static sqlite3 *database = nil;

@implementation CDSecondaryCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self prepareLayout];
    [self prepareDataSource];
}

#pragma mark - UI
- (void)setupNavBar {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *buttons = self.navigationItem.rightBarButtonItems.mutableCopy;
        UIBarButtonItem *addCommentButton = [[UIBarButtonItem alloc] initWithTitle:@"+ Добавить заметку" style:UIBarButtonItemStylePlain target:self action:@selector(addCommentButtonTapped)];
        [buttons addObject:addCommentButton];
        self.navigationItem.rightBarButtonItems = buttons;
    });
}

- (void)prepareLayout {
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    configuration.headerMode = UICollectionLayoutListHeaderModeSupplementary;
    configuration.itemSeparatorHandler = ^UIListSeparatorConfiguration * _Nonnull(NSIndexPath * _Nonnull indexPath, UIListSeparatorConfiguration * _Nonnull sectionSeparatorConfiguration) {
        sectionSeparatorConfiguration.bottomSeparatorInsets = NSDirectionalEdgeInsetsZero;
        return sectionSeparatorConfiguration;
    };
    
    __weak typeof(self) weakSelf = self;
    configuration.trailingSwipeActionsConfigurationProvider = ^UISwipeActionsConfiguration * _Nullable(NSIndexPath * _Nonnull indexPath) {
        return [weakSelf swipeActionsForIndexPath:indexPath];
    };
    
    UICollectionViewCompositionalLayout *layout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];

    self.mainCollectionView.collectionViewLayout = layout;
}

- (UISwipeActionsConfiguration *)swipeActionsForIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self removeCommentAtIndexPath:indexPath];
        
        completionHandler(YES);
    }];
    
    removeAction.image = [UIImage systemImageNamed:@"trash"];
    
    return [UISwipeActionsConfiguration configurationWithActions:@[removeAction]];
}

#pragma mark - Button Actions
- (void)addCommentButtonTapped {
    __weak typeof(self) weakSelf = self;
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Новая заметка" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        textField.placeholder = @"Заметка";
    }];
    
    UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"Добавить" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *comment = alertVC.textFields.firstObject.text;
        if ([comment stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0) {
            [weakSelf addComment:comment];
        }
    }];
    [alertVC addAction:addAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:cancelAction];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Prepare Data
- (void)prepareDataSource {
    self.dataSource = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Date, UserId, Description, SendStatus, CommentId, Time from CustComment where CustAccount = ? and CommentType = ? and ForDelete = '0' order by substr(Date,7) || substr(Date,4,2) || substr(Date,1,2) desc, time(Time) desc";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            
            sqlite3_bind_text(selectstmt, 1, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, @"cust".UTF8String, -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *comment = [NSMutableDictionary new];
                
                for (int i = 0; i < sqlite3_column_count(selectstmt); i++) {
                    if (sqlite3_column_text(selectstmt, i)) {
                        NSString *key = [NSString stringWithUTF8String:(char *)sqlite3_column_name(selectstmt, i)];
                        NSString *value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, i)];
                        comment[key] = value;
                    }
                }
                
                [self.dataSource addObject:comment];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self.mainCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CDSecondaryCommentsSectionHeaderView" forIndexPath:indexPath];
        return headerView;
    }
    
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryCommentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryCommentCollectionViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.item];
    [cell setComment:object];
    
    return cell;
}

#pragma mark - Working with Data
- (void)addComment:(NSString *)comment {
    NSString *uuid = NSUUID.UUID.UUIDString;
    
    NSDateFormatter *dateFormatter = NSDateFormatter.new;
    NSDate *date = NSDate.date;
    
    dateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    NSString *dateStr = [dateFormatter stringFromDate:date];
    
    dateFormatter.dateFormat = @"HH:mm:ss";
    NSString *timeStr = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *addStmt;
        
        const char *sql = "insert or ignore into CustComment (CustAccount, CommentId, Description, UserId, Date, CommentType, SendStatus, Time, ForDelete) Values(?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, self.custAccount.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, uuid.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, comment.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, LocalAuthWorker.emple.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, dateStr.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, @"cust".UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, @"New".UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, timeStr.UTF8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 9, [@"0" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    sqlite3_close(database);
    
    [self sendPutCommentsRequest:uuid];

    [self prepareDataSource];
}

- (void)removeCommentAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.dataSource[indexPath.item];
   
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *updateStmt;
        
        const char *sql = "update CustComment Set ForDelete = '1', SendStatus = 'New' where CommentId = ?";
        
        if (sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(updateStmt, 1, [object[@"CommentId"] UTF8String], -1, SQLITE_TRANSIENT);

        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
    
    [self.dataSource removeObjectAtIndex:indexPath.row];
    [self.mainCollectionView deleteItemsAtIndexPaths:@[indexPath]];
    
    [self sendPutCommentsRequest:object[@"CommentId"]];
}

#pragma mark - Networking
- (void)sendPutCommentsRequest:(NSString *)commentID {
    PutCommentsRequest *putComments = [PutCommentsRequest new];
    putComments.custAccount = self.custAccount;
    putComments.commentId = commentID;
    putComments.notShowProgress = YES;
    [putComments sendComments];
}

@end
