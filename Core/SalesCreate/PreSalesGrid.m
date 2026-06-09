//
//  PreSalesGrid.m
//  MLK
//
//  Created by Rustem Galyamov on 25.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PreSalesGrid.h"
#import "XMLWriter.h"
#import "PutOrdersNewRequest.h"

//Cell Subclass
#import "PresalesProductTableViewCell.h"

//Constants
static const CGFloat kProductCellHeight = 55.0;

static sqlite3 *database = nil;

@interface PreSalesGrid ()
@property (nonatomic, strong) NSMutableArray *itemsArray;

@property (nonatomic, copy) NSString *salesLineTable;

@end

@implementation PreSalesGrid

@synthesize delegate;

@synthesize sumQty, sumAmount, custAccount, comment, deliveryDate, storeID, firmName, firmId, firmMarkup;
@synthesize sendSales;
@synthesize actionCheckQty, actionCheckAmount, actId;
@synthesize isNewText;

#define LABEL_TAG 1 
#define VALUE_TAG 2 
#define FIRST_CELL_IDENTIFIER @"TrailItemCell" 
#define SECOND_CELL_IDENTIFIER @"RegularCell" 


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isConsult) {
        self.salesLineTable = @"tmpConsultSalesLine";
    } else {
        self.salesLineTable = @"tmpSalesLine";
    }
    
    self.tableView = delegate.getTV;
    
    [self createLineList];
    
    isNewText = YES;
}

- (void)createLineList {
    self.itemsArray = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select ItemId, ItemName, AvailQty, Qty, OrigPrice, Price, Discount, LineAmount, ActionType, BrandId, BrandName, StoreID, isBadProduct, FirmId, FirmName, FirmMarkup from %@ where CustAccount = ?", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *object = [NSMutableDictionary new];
                
                NSString *itemID = @"null";
                NSString *itemName = @"null";
                NSString *availQty = @"null";
                NSString *qty = @"null";
                NSString *origPrice = @"null";
                NSString *price = @"null";
                NSString *discount = @"null";
                NSString *lineAmount = @"null";
                NSString *actionType = @"0";
                NSString *brandID = @"null";
                NSString *brandName = @"null";
                NSString *storeID = @"null";
                NSString *isBadProduct;
                NSString *firmID;
                NSString *firmName;
                NSString *firmMarkup;
                
                if (sqlite3_column_text(selectstmt, 0))
                    itemID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    itemName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    availQty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    qty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    origPrice = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    price = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    discount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    lineAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (sqlite3_column_text(selectstmt, 8))
                    actionType = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                if (sqlite3_column_text(selectstmt, 9))
                    brandID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if (sqlite3_column_text(selectstmt, 10))
                    brandName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (sqlite3_column_text(selectstmt, 11))
                    storeID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                if (sqlite3_column_text(selectstmt, 12))
                    isBadProduct = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 12)];
                
                if (sqlite3_column_text(selectstmt, 13))
                    firmID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 13)];
                
                if (sqlite3_column_text(selectstmt, 14))
                    firmName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 14)];
                
                if (sqlite3_column_text(selectstmt, 15))
                    firmMarkup = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 15)];
                
                object[@"itemID"] = itemID;
                object[@"itemName"] = itemName;
                object[@"availQty"] = availQty;
                object[@"qty"] = qty;
                object[@"origPrice"] = origPrice;
                object[@"price"] = price;
                object[@"discount"] = discount;
                object[@"lineAmount"] = lineAmount;
                object[@"actionType"] = actionType;
                object[@"brandID"] = brandID;
                object[@"brandName"] = brandName;
                object[@"StoreID"] = storeID;
                object[@"isBadProduct"] = isBadProduct;
                object[@"firmID"] = firmID;
                object[@"firmName"] = firmName;
                object[@"firmMarkup"] = firmMarkup;
                
                [self.itemsArray addObject:object];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
}

-(NSString *)getSumAmount {
    double total = 0.0;
    for (NSDictionary *object in self.itemsArray) {
        NSString *actionType = object[@"actionType"];
        if ([actionType isEqualToString:@"2"]) {
            continue;
        } else {
            total += [object[@"lineAmount"] doubleValue];
        }
    }
    
    if (total > 0.0) {
        return [NSString stringWithFormat:@"%0.2f", total];
    } else {
        return @"0.00";
    }
}

-(NSString *)getSumQty{
    double total = 0.0;
    for (NSDictionary *object in self.itemsArray) {
        NSString *actionType = object[@"actionType"];
        if ([actionType isEqualToString:@"2"]) {
            continue;
        } else {
            total += [object[@"qty"] doubleValue];
        }
    }
    
    if (total > 0.0) {
        sumQty = [NSString stringWithFormat:@"%0.0f", total];
        return sumQty;
    } else {
        return @"0";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.itemsArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kProductCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PresalesProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PresalesProductTableViewCell class]) forIndexPath:indexPath];
    
    NSDictionary *object = self.itemsArray[indexPath.row];
    
    cell.lblNumber.text = [NSString stringWithFormat:@"%d", (int)(indexPath.row + 1)];
    cell.lblProductCode.text = object[@"itemID"];
    cell.lblBrand.text = object[@"brandName"];
    cell.lblName.text = object[@"itemName"];
    
    cell.lblBadProduct.hidden = ![object[@"isBadProduct"] isEqual:@"1"];
    
    cell.txtQtyField.text = object[@"qty"];
    cell.txtQtyField.tag = indexPath.row + 2;
    cell.txtQtyField.delegate = self;
    cell.txtQtyField.enabled = NO;
    
    [cell setPrice:object[@"price"] discount:object[@"discount"]];
    
    cell.lblSum.text = object[@"lineAmount"];
    
    cell.lblAvailableQty.hidden = self.isConsult;
    cell.lblAvailableQty.text = object[@"availQty"];
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag - 2 inSection:0];
    
    NSString *qtyValue = textField.text;
    if (qtyValue.length == 0 || [qtyValue isEqual: @"0"]) {
        [AlertWorkerObjc alertWithTitle:@"Удаление товара" message:@"Вы действительно хотите удалить товар из заказа?" buttons:@[@"Да", @"Нет"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
            if (index == 0) {
                [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
            } else {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
        
        return YES;
    }
    
    NSMutableDictionary *object = [self.itemsArray[indexPath.row] mutableCopy];

    NSString *priceValue = object[@"price"];
    NSString *discount = object[@"discount"];
    NSString *availQty = object[@"availQty"];
    NSString *actionType = object[@"actionType"];
    
    if (!self.isConsult && [qtyValue doubleValue] > [availQty doubleValue] && ![actionType isEqualToString:@"2"]) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка" message:@"Вы пытаетесь заказать больше, чем доступно"];
        qtyValue = availQty;
        textField.text = qtyValue;
    }
    
    object[@"qty"] = qtyValue;
    
    double new = qtyValue.doubleValue * (100.0 - discount.doubleValue) / 100.0 * priceValue.doubleValue;
    
    NSString *newLineAmount = [NSString stringWithFormat:@"%0.2lf", new];
    object[@"lineAmount"] = newLineAmount;
    
    [self.itemsArray replaceObjectAtIndex:indexPath.row withObject:object];
    
    [self updateTmpSalesLine:object];
    
    [self.delegate gridIsUpdated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    NSIndexPath *indPath = [NSIndexPath indexPathForRow:textField.tag-2 inSection:0];
    
    [self.tableView selectRowAtIndexPath:indPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    /* for backspace */
    /* for backspace */
    if (isNewText == YES) {
        textField.text = @"";
        isNewText = FALSE;
    }
    
    if ([string length] == 0) {
        return YES;
    }
    
    /*  limit to only numeric characters  */
    
    NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    
    for (int y = 0; y < [string length]; y++) {
        unichar c = [string characterAtIndex:y];
        
        if ([myCharSet characterIsMember:c]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)updateTmpSalesLine:(NSDictionary *)object {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        static sqlite3_stmt *updateStmt;
        
        NSString *sqlString = [NSString stringWithFormat:@"update %@ Set Qty = ?, lineAmount = ?, StoreID = ? where CustAccount = ? and ItemId = ?", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [object[@"qty"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [object[@"lineAmount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 3, [object[@"StoreID"] UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(updateStmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 5, [object[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    isNewText = YES;
    
    NSDictionary *object = self.itemsArray[indexPath.row];
    if (![object[@"actionType"] isEqualToString:@"2"] && ![object[@"actionType"] isEqualToString:@"3"]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        UITextField *myTextField = (UITextField *)[cell viewWithTag:indexPath.row+2];
        
        [myTextField setEnabled:YES];
        [myTextField becomeFirstResponder];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {            
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //Delete the object from the table.
        [self.delegate gridIsUpdated];
        
        [self updateArrays:indexPath];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [tableView reloadData];
        
        [self.delegate gridIsUpdated];
    }
}

- (void)updateArrays:(NSIndexPath *)indexPath {
    NSDictionary *object = self.itemsArray[indexPath.row];
    
    if (![object[@"actionType"] isEqualToString:@"0"]) {
        [self removeActionFromTmpSale:custAccount];
    } else {
        [self removeItemFromTmpSale:object];
    }
    
    [self.itemsArray removeObjectAtIndex:indexPath.row];
}

- (void)removeItemFromTmpSale:(NSDictionary *)item{
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *deleteStmt;
        
        NSString *sqlString = [NSString stringWithFormat:@"delete from %@ where CustAccount = ? and ItemId = ?", self.salesLineTable];
              const char *sql = sqlString.UTF8String;
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_text(deleteStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 2, [item[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 3, [item[@"StoreID"] UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
    }
    sqlite3_close(database);
}

- (void)removeActionFromTmpSale:(NSString *)custAccountToDel {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *deleteStmt;
        
        NSString *sqlString = [NSString stringWithFormat:@"delete from %@ where CustAccount = ? and ActionType != '0'", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_text(deleteStmt, 1, [custAccountToDel UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
        sqlite3_close(database);
        //[self.delegate gridIsUpdated];
    } else
        sqlite3_close(database);
}

- (void)createSalesFromTmp:(NSString *)salesId merge:(BOOL)mergeSale {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    BOOL custinvisit  = [self custInVisit:custAccount date:strDate];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *addStmt;

        NSString *salesTable = self.isConsult ? @"ConsultSalesTable" : @"SalesTable";
        NSString *sqlString = [NSString stringWithFormat:@"insert or ignore into %@ (CustAccount, SalesId, SalesDate, StoreID, AmountSum, SalesNum, ChannelTypeId, ContractId, SalesStatus, Comment, SalesUUID, SalesDateSort, DeliveryDate, CreatedTime, ActionId, ActionType, FirmId, FirmName, FirmMarkup, Merge, DeliveryDateSort, Consult) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", salesTable];
        const char *sql = sqlString.UTF8String;
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        //        sqlite3_bind_text(addStmt, 3, [deliveryDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [storeID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [[self getSumAmount] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [@"---" UTF8String], -1, SQLITE_TRANSIENT);
        
        if (custinvisit)
            sqlite3_bind_text(addStmt, 7, [@"ТП" UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(addStmt, 7, [@"ТП телефон" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(addStmt, 8, [@"---" UTF8String], -1, SQLITE_TRANSIENT);
        
        //if (sendSales)
        //    sqlite3_bind_text(addStmt, 8, [@"Отправлен" UTF8String], -1, SQLITE_TRANSIENT);
        //else
        sqlite3_bind_text(addStmt, 9, [@"Открыт" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(addStmt, 10, [comment UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 11, [NSUUID.UUID.UUIDString UTF8String], -1, SQLITE_TRANSIENT);
        
        NSDate *endDate;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        endDate = [dateFormatter dateFromString:strDate];
        [dateFormatter setDateFormat:dateFormat_YYYY_MM_dd];
        
        sqlite3_bind_text(addStmt, 12, [[dateFormatter stringFromDate:endDate] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 13, [deliveryDate UTF8String], -1, SQLITE_TRANSIENT);
        
        NSDate *today = NSDate.date;
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        NSString *currentTime = [dateFormatter stringFromDate:today];
        
        sqlite3_bind_text(addStmt, 14, [currentTime UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(addStmt, 15, [[self getActionId] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 16, [[self getActionType] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 17, [firmId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 18, [firmName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 19, [firmMarkup UTF8String], -1, SQLITE_TRANSIENT);
        
        if (mergeSale)
            sqlite3_bind_text(addStmt, 20, [@"1" UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(addStmt, 20, [@"0" UTF8String], -1, SQLITE_TRANSIENT);
        
        NSDate *dlvDate;
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        dlvDate = [dateFormatter dateFromString:deliveryDate];
        [dateFormatter setDateFormat:dateFormat_YYYY_MM_dd];
        
        sqlite3_bind_text(addStmt, 21, [[dateFormatter stringFromDate:dlvDate]  UTF8String], -1, SQLITE_TRANSIENT);
        
        if (self.isConsult) {
            sqlite3_bind_text(addStmt, 22, [@"1" UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            sqlite3_bind_text(addStmt, 22, [@"0" UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    sqlite3_close(database);
    
    [self createSalesLineFromTmp:salesId];
}

-(BOOL)custInVisit:(NSString *)custAcc date:(NSString *)strDate {
    BOOL visit = FALSE;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                visit = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return visit;
}

- (void)createSalesLineFromTmp:(NSString *)salesId {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (NSDictionary *object in self.itemsArray) {
            NSString *actionType = object[@"actionType"];
            
            if ([actionType isEqualToString:@"2"]) {
                continue;
            } else {
                static sqlite3_stmt *addStmtLine;
                
                NSString *salesLineTable = self.isConsult ? @"ConsultSalesLine" : @"SalesLine";
                NSString *sqlString = [NSString stringWithFormat:@"insert into %@ (SalesId, ItemId, ItemName, BrandName, Qty, Price, LineAmount, OrigPrice, StoreID, Discount, isBadProduct, AvailQty) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", salesLineTable];
                
                const char *sql = sqlString.UTF8String;
                if (sqlite3_prepare_v2(database, sql, -1, &addStmtLine, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                sqlite3_bind_text(addStmtLine, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 2, [object[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 3, [object[@"itemName"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 4, [object[@"brandName"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 5, [object[@"qty"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 6, [object[@"price"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 7, [object[@"lineAmount"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 8, [object[@"origPrice"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 9, [object[@"StoreID"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 10, [object[@"discount"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 11, [object[@"isBadProduct"] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmtLine, 12, [object[@"availQty"] UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_step(addStmtLine);
                sqlite3_finalize(addStmtLine);
            }
        }
        
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
    
    if (sendSales)
        [self sendSales:salesId];
}

- (void)sendSales:(NSString *)salesId {
    XMLWriter* xmlWriter = [[XMLWriter alloc]init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *salesTable = self.isConsult ? @"ConsultSalesTable" : @"SalesTable";
        NSString *sqlString = [NSString stringWithFormat:@"select SalesDate, StoreID, CustAccount, ContractId, AmountSum, ChannelTypeId, SalesStatus, Comment, SalesUUID, DeliveryDate, CreatedTime, ActionId, FirmId, Merge, Consult from %@ where SalesId = ?", salesTable];
        const char *sql = sqlString.UTF8String;

        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *salesDate;
                NSString *storeID;
                NSString *custAcc;
                NSString *contractId;
                NSString *amountSum;
                NSString *channelTypeId;
                NSString *salesStatus;
                NSString *comment;
                NSString *uuid;
                NSString *dlvDate;
                NSString *crTime;
                NSString *actionId;
                NSString *f_id;
                NSString *merge;
                NSString *consult;
                
                if (!sqlite3_column_text(selectstmt, 0))
                    salesDate = @"";
                else
                    salesDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (!sqlite3_column_text(selectstmt, 1)) {
                    storeID = @"";
                } else {
                    storeID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
                
                if (!sqlite3_column_text(selectstmt, 2))
                    custAcc = @"";
                else
                    custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (!sqlite3_column_text(selectstmt, 3))
                    contractId = @"";
                else
                    contractId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (!sqlite3_column_text(selectstmt, 4))
                    amountSum = @"";
                else
                    amountSum = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (!sqlite3_column_text(selectstmt, 5))
                    channelTypeId = @"";
                else
                    channelTypeId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (!sqlite3_column_text(selectstmt, 6))
                    salesStatus = @"";
                else
                    salesStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (!sqlite3_column_text(selectstmt, 7))
                    comment = @"";
                else
                    comment = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (!sqlite3_column_text(selectstmt, 8))
                    uuid = @"";
                else
                    uuid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                if (!sqlite3_column_text(selectstmt, 9))
                    dlvDate = @"";
                else
                    dlvDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if (!sqlite3_column_text(selectstmt, 10))
                    crTime = @"";
                else
                    crTime = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 10)];
                
                if (!sqlite3_column_text(selectstmt, 11))
                    actionId = @"";
                else
                    actionId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 11)];
                
                if (!sqlite3_column_text(selectstmt, 12))
                    f_id = @"";
                else
                    f_id  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 12)];
                
                if (!sqlite3_column_text(selectstmt, 13))
                    merge = @"0";
                else
                    merge = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 13)];
                
                if (!sqlite3_column_text(selectstmt, 14)) {
                    consult = @"0";
                } else {
                    consult = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 14)];
                }

                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:SalesNum"];
                [xmlWriter writeCharacters:salesId];
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
                
                [self updateSalesTable:salesId sendTime:sendTime];
                
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
                
                [xmlWriter writeStartElement:@"sam:Consult"];
                [xmlWriter writeCharacters:consult];
                [xmlWriter writeEndElement];
                
                NSString *salesLineTable = self.isConsult ? @"ConsultSalesLine" : @"SalesLine";
                NSString *sqlString = [NSString stringWithFormat:@"select ItemId, Qty, LineAmount, StoreID, isBadProduct from %@ where SalesId = ?", salesLineTable];
                const char *sql_1 = sqlString.UTF8String;
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
                    
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
                
                salesDate       = nil;
                storeID         = nil;
                custAcc         = nil;
                contractId      = nil;
                amountSum       = nil;
                channelTypeId   = nil;
                salesStatus     = nil;
                comment         = nil;
                uuid            = nil;
                dlvDate         = nil;
                crTime          = nil;
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    setSalesToServer = [PutOrdersNewRequest new];
    setSalesToServer.isConsult = self.isConsult;
    setSalesToServer.salesId = salesId;
    [setSalesToServer sendSales:xml];
}

- (void)updateSalesTable:(NSString *)salesId sendTime:(NSString*)sendTime {
    NSString *salesTable = self.isConsult ? @"ConsultSalesTable" : @"SalesTable";
    NSString *sqlString = [NSString stringWithFormat:@"update %@ Set SendTime = ? where SalesId = ?", salesTable];
    const char *sql_2 = sqlString.UTF8String;
    
    sqlite3_stmt *updateStmt;
    
    if (sqlite3_prepare_v2(database, sql_2, -1, &updateStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(updateStmt, 1, [sendTime UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *actionType = self.itemsArray[indexPath.row][@"actionType"];
    
    if ([actionType isEqualToString:@"0"]) {
        cell.backgroundColor = [UIColor colorWithRed:241.f/255.f green:241.f/255.f blue:241.f/255.f alpha:1];
    } else if ([actionType isEqualToString:@"2"]) {
        UIColor *mycolor= [UIColor colorWithRed:245.0/255.0 green:222.0/255.0 blue:179.0/255.0 alpha:1.0];
        cell.backgroundColor = mycolor;
    } else if ([actionType isEqualToString:@"1"] || [actionType isEqualToString:@"3"]) {
        UIColor *mycolor= [UIColor colorWithRed:144.0/255.0 green:238.0/255.0 blue:144.0/255.0 alpha:1.0];
        cell.backgroundColor = mycolor;
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

+ (void)finalizeStatements {
    if (database)
        sqlite3_close(database);
}

- (BOOL)noSalesLine {
    return self.itemsArray.count < 1;
}

- (void)refreshData{
    [self createLineList];
}

-(NSString *)getActionId {
    NSString *act_Id = @"null";
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select ActionId from %@ where CustAccount = ? and ActionType != '0'", self.salesLineTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                act_Id = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return act_Id;
}

- (NSInteger)getCountLine {
    return self.itemsArray.count;
}

- (NSString *)getStoreID {
    return self.itemsArray.firstObject[@"StoreID"];
}

- (NSString *)getFirmID {
    return self.itemsArray.firstObject[@"firmID"];
}

- (NSString *)getFirmName {
    return self.itemsArray.firstObject[@"firmName"];
}

- (NSString *)getFirmMarkup {
    return self.itemsArray.firstObject[@"firmMarkup"];
}

- (NSString *)getActionType {
    NSString *actType = @"null";
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *sqlString = [NSString stringWithFormat:@"select ActionType from %@ where CustAccount = ? and ActionType != '0'", self.salesLineTable];
        const char *sql = sqlString.UTF8String;

        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                actType = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return actType;
}

- (void)getCheckParam:(NSString *)a_Id {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select ActionAmountSum, ActionAmountQty from ActionTable where ActionId = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [a_Id UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW) {
                actionCheckAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                
                actionCheckQty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
}

- (void)fillCheckParms {
    actId = [self getActionId];
    
    if (actId != nil)
        [self getCheckParam:actId];
}

-(NSString*)getCheckedAmount {
    return actionCheckAmount;
}

-(NSString*)getCheckedQty{
    return actionCheckQty;
}


@end
