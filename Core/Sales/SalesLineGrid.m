//
//  SalesLineGrid.m
//  MLK
//
//  Created by Rustem Galyamov on 03.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SalesLineGrid.h"

//Cell Subclass
#import "PresalesProductTableViewCell.h"

//Constants
static const CGFloat kProductCellHeight = 55.0;

static sqlite3 *database = nil;

@interface SalesLineGrid ()
@property (nonatomic, strong) NSMutableArray *itemsArray;

@end

@implementation SalesLineGrid

@synthesize sumQty, sumAmount, salesId;
@synthesize delegate;
@synthesize isOpen, isNewText;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    isNewText = YES;
    
    self.tableView = delegate.getTV;
    
    [self createLineList];
    
    NSString *zakaz = [PersistenceWorker load:@"zakaz"];
    
    if (![zakaz isEqualToString:@"1"])
        isOpen = NO;
}

- (void)createLineList {
    self.itemsArray = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
        sql = "select ItemId, ItemName, BrandName, Qty, Price, LineAmount, StoreID, Discount, isBadProduct, AvailQty from SalesLine where SalesId = ?";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *object = [NSMutableDictionary new];
                
                NSString *itemID  = @"null";
                NSString *itemName = @"null";
                NSString *brandName = @"null";
                NSString *qty = @"null";
                NSString *price = @"null";
                NSString *lineAmount = @"null";
                NSString *storeID = @"null";
                NSString *discount = @"null";
                NSString *isBadProduct = @"null";
                NSString *availQty = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    itemID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    itemName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    brandName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    qty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    price = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    lineAmount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    storeID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    discount = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (sqlite3_column_text(selectstmt, 8))
                    isBadProduct = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                if (sqlite3_column_text(selectstmt, 9))
                    availQty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                if ([itemName isEqualToString:@"null"]) {
                    itemName = @"Номенклатура закрыта";
                }
                
                object[@"itemID"] = itemID;
                object[@"itemName"] = itemName;
                object[@"brandName"] = brandName;
                object[@"qty"] = qty;
                object[@"price"] = price;
                object[@"lineAmount"] = lineAmount;
                object[@"storeID"] = storeID;
                object[@"discount"] = discount;
                object[@"isBadProduct"] = isBadProduct;
                object[@"availQty"] = availQty;
                
                [self.itemsArray addObject:object];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
    
    [self.tableView reloadData];
}   

- (NSString *)getSumAmount {
    double total = 0.0;
    for (NSDictionary *object in self.itemsArray) {
        total += [object[@"lineAmount"] doubleValue];
    }
    
    sumAmount = [NSString stringWithFormat:@"%0.2f", total];
    
    return sumAmount;
}

- (NSString *)getSumQty{
    double total = 0.0;
    for (NSDictionary *object in self.itemsArray) {
        total += [object[@"qty"] doubleValue];
    }
    
    sumQty = [NSString stringWithFormat:@"%0.0f", total];
    
    return sumQty;
}

- (NSInteger)getCountLine {
    return self.itemsArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kProductCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.itemsArray.count;
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
    cell.lblAvailableQty.text = object[@"availQty"];
    
    return cell;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (isOpen)
        return YES;
    else
        return NO;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag - 2 inSection:0];
    
    NSMutableDictionary *object = [self.itemsArray[indexPath.row] mutableCopy];
    
    NSString *qtyValue = textField.text;
    NSString *priceValue = object[@"price"];
    NSString *discount = object[@"discount"];
    NSString *availQty = object[@"availQty"];
    NSString *actionType = object[@"actionType"];
    
    if (([qtyValue doubleValue] > [availQty doubleValue]) & ![actionType isEqualToString:@"2"]) {
        [AlertWorkerObjc alertWithTitle:@"Ошибка" message:@"Вы пытаетесь заказать больше, чем доступно"];
        
        qtyValue = availQty;
        
        textField.text = qtyValue;
    }
    
    object[@"qty"] = qtyValue;
    
    double new = qtyValue.doubleValue * (100.0 - discount.doubleValue) / 100.0 * priceValue.doubleValue;
    
    NSString *newLineAmount = [NSString stringWithFormat:@"%0.2lf", new];
    object[@"lineAmount"] = newLineAmount;
    
    [self.itemsArray replaceObjectAtIndex:indexPath.row withObject:object];
    
    [self updateSalesLine:object];
    [self updateSalesTable];
    
    [self.delegate gridIsUpdated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (isNewText == YES) {
        textField.text = @"";
        isNewText = FALSE;
    }
    
    /* for backspace */
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

- (void)updateSalesLine:(NSDictionary *)object {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;
        
        const char *sql = "update SalesLine Set Qty = ?, lineAmount = ? where SalesId = ? and ItemId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [object[@"qty"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [object[@"lineAmount"] UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(updateStmt, 3, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 4, [object[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
    
    sumAmount = [self getSumAmount];
}

- (void)updateSalesTable {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;
        
        const char *sql = "update SalesTable Set AmountSum = ? where SalesId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [sumAmount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    isNewText = YES;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UITextField *myTextField = (UITextField *)[cell viewWithTag:indexPath.row+2];
    
    [myTextField setEnabled:YES];
    
    [myTextField becomeFirstResponder];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {            
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (isOpen) {
            [self removeItemFromTmpSale:self.itemsArray[indexPath.row]];
            [self.itemsArray removeObjectAtIndex:indexPath.row];
            
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            [self.delegate gridIsUpdated];
            
            sumAmount = [self getSumAmount];
            
            [self updateSalesTable];
        }
    }
}

- (void)removeItemFromTmpSale:(NSDictionary *)object {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        sqlite3_stmt *deleteStmt;
        
        const char *sql = "delete from SalesLine where SalesId = ? and ItemId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        
        sqlite3_bind_text(deleteStmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 2, [object[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 3, [object[@"StoreID"] UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)refreshData{
    [self createLineList];
}

@end
