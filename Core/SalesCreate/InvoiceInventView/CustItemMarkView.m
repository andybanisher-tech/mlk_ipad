//
//  CustItemMarkView.m
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "CustItemMarkView.h"
#import "GroupView.h"

static sqlite3      *database = nil;

@implementation CustItemMarkView

@synthesize delegate;
@synthesize custAccount;
@synthesize filterByStatusDN;


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    self.tableView.frame = CGRectMake(0, 0, 300, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
    
    if (!self.selectedBrandID && !self.selectedGroupID) {
        selectedIndex = -1;
    }
    
    if (selectedIndex > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self->selectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        });
    }
    [self reloadVisibleCells];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ((self.selectedBrandID || self.selectedGroupID) && selectedIndex) {
        GroupView *fvController = [[GroupView alloc] initWithNibName: @"GroupView" bundle: nil];
        fvController.requiredGroupIDsArray = self.requiredGroupIDsArray;
        fvController.selectedBrandID = self.brandsArray[selectedIndex][@"brandID"];
        fvController.selectedGroupID = self.selectedGroupID;
        fvController.isViewPushed = NO;
        fvController.delegate = self;
        
        fvController.modalPresentationStyle = UIModalPresentationPopover;

        if (fvController.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
            fvController = nil;
        } else {
            CGRect myRect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
            fvController.popoverPresentationController.sourceView = self.view;
            fvController.popoverPresentationController.sourceRect = myRect;
            fvController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
            [self presentViewController:fvController animated:YES completion:nil];
        }
        infoNavController = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.selectedBrandID = nil;
    self.selectedGroupID = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createBrandsArray];
}

- (void)createBrandsArray{
    self.brandsArray = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        //const char *sql = "select BrandId, BrandName from Brand order by BrandName asc";
        //const char *sql = "select BrandId from PersonalPriceList where CustAccount = ? inner join (select BrandName from Brand where Brand.BrandId == PersonalPriceList.BrandId order by BrandName)";
        const char *sql = "select BrandId from PersonalPriceList where CustAccount = ? and PersonalPriceList.Active = '1'";
        
        NSString *requiredIDsQueryString = [self.requiredBrandIDsArray componentsJoinedByString:@"','"];
        if (requiredIDsQueryString) {
            NSString *sqlQuery = [NSString stringWithFormat:@"select BrandId from PersonalPriceList where CustAccount = ? and PersonalPriceList.Active = '1' and BrandId IN ('%@')", requiredIDsQueryString];
            sql = [sqlQuery UTF8String];
        }
        
        if (filterByStatusDN.length > 0) {
            NSString *sqlQuery = [NSString stringWithFormat:@"select priceList.BrandId from PersonalPriceList priceList Join CustStatusDNBrand sDNBrand on (priceList.CustAccount = sDNBrand.CustAccount and priceList.BrandId = sDNBrand.BrandId) Join Brand on (Brand.BrandId = sDNBrand.BrandId) where priceList.CustAccount = ? and priceList.Active = '1' and (%@) order by Brand.BrandName", filterByStatusDN];
            sql = [sqlQuery UTF8String];
        }
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *brandObject = [NSMutableDictionary new];
                
                NSString *brandID   = @"null";
                NSString *brandName = @"null";
                NSString *statusDN  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    brandID  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                const char *sql_1;
                
                sql_1 = "select BrandName from Brand where BrandId = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt, 1, [brandID UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt) == SQLITE_ROW)
                    {
                        if (sqlite3_column_text(selstmt, 0))
                            brandName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                    }
                }
                sqlite3_finalize(selstmt);
                
                
                
                const char *sql_2;
                
                sql_2 = "SELECT Status FROM CustStatusDNBrand where BrandId = ? and CustAccount = ?";
                
                sqlite3_stmt *selstmt2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt2, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt2, 1, [brandID UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt2, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt2) == SQLITE_ROW)
                    {
                        if (sqlite3_column_text(selstmt2, 0))
                            statusDN  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt2, 0)];
                    }
                }
                sqlite3_finalize(selstmt2);
                
                brandObject[@"brandID"] = brandID;
                brandObject[@"brandName"] = brandName;
                brandObject[@"statusDN"] = statusDN;
                
                [self.brandsArray addObject:brandObject];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    if (self.brandsArray.count > 0) {
        [self.brandsArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1[@"brandName"] compare: obj2[@"brandName"]];
        }];
        
        NSDictionary *brandObject = @{@"brandName" : @"Убрать фильтр"};
        [self.brandsArray insertObject:brandObject atIndex:0];
    }
    
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.brandsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary *object = self.brandsArray[indexPath.row];
    
    cell.textLabel.text = object[@"brandName"];
    
    if (indexPath.row == 0) {
        cell.textLabel.textColor = [UIColor blueColor];
        cell.backgroundColor = UIColor.lightGrayColor;
    } else {
        cell.backgroundColor = UIColor.whiteColor;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    NSString *statusDN = object[@"statusDN"];
    if ([statusDN containsString:@"Работает"] ||
        [statusDN containsString:@"Новый"] ||
        [statusDN containsString:@"Новый(Запуск)"] ||
        [statusDN containsString:@"Закрытие"]) {
        cell.backgroundColor = [ASPFunctions colorFromHex:@"00b4ff"];
    }
    
    if (selectedIndex == indexPath.row) {
        cell.backgroundColor = UIColor.lightGrayColor;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != selectedIndex) {
        selectedIndex = indexPath.row;
        [self reloadVisibleCells];
    }
    
    if (indexPath.row > 0) {
        NSDictionary *object = self.brandsArray[indexPath.row];
        
        GroupView *fvController = [[GroupView alloc] initWithNibName:@"GroupView" bundle: nil];
        fvController.requiredGroupIDsArray = self.requiredGroupIDsArray;
        fvController.selectedBrandID = object[@"brandID"];
        fvController.selectedGroupID = self.selectedGroupID;
        fvController.isViewPushed = NO;
        fvController.delegate     = self;
        
        fvController.modalPresentationStyle = UIModalPresentationPopover;
        
        if (fvController.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
            fvController = nil;
        } else {
            CGRect myRect = [tableView rectForRowAtIndexPath:indexPath];
            fvController.popoverPresentationController.sourceView = self.view;
            fvController.popoverPresentationController.sourceRect = myRect;
            fvController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft;
            [self presentViewController:fvController animated:YES completion:nil];
        }
        infoNavController = nil;
    } else {
        self.selectedBrandID = nil;
        [self.delegate markIsSelected:nil];
    }
}

- (void)markIsSelected:(NSString *)brand {
    if (self.delegate) {
        if ([brand isEqualToString:@"Убрать фильтр"]) {
            [self.delegate markIsSelected:nil];
        } else {
            [self.delegate markIsSelected:brand];
        }
    }
}

- (void)groupIsSelected:(NSString *)groupId {
    if (self.delegate) {
        [self.delegate groupIsSelected:groupId];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Helpers
- (void)reloadVisibleCells {
    NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
    if (visibleIndexPaths && visibleIndexPaths.count > 0) {
        [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
