//
//  PrepareSales.m
//  MLK
//
//  Created by Rustem Galyamov on 25.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PrepareSales.h"

static sqlite3 *database = nil;

@implementation PrepareSales

@synthesize actionType, actionId, brandForItems;

- (void)createTmpSalesLine:(NSString *)custAccount item:(NSDictionary *)item firmID:(NSString *)firmID firmName:(NSString *)firmName firmMarkup:(NSString *)firmMarkup isConsult:(BOOL)isConsult {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_1 = "select BrandName from Brand where BrandId = ?";
        sqlite3_stmt *selstmt_1;
        
        NSString *brandName = @"";
        
        if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt_1, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_1, 1, [item[@"brandID"] UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_1) == SQLITE_ROW) {
                if (sqlite3_column_text(selstmt_1, 0))
                    brandName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_1, 0)];
            }
            sqlite3_finalize(selstmt_1);
        }
        
        const char *sql_2 = "select ContractId from PersonalPriceList where BrandId = ? and CustAccount = ?";
        sqlite3_stmt *selstmt_2;
        
        NSString *contract = @"null";
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_2, 1, [item[@"brandID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
                if (sqlite3_column_text(selstmt_2, 0))
                    contract = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
            }
        }
        sqlite3_finalize(selstmt_2);
        
        NSString *saleLineTable = isConsult ? @"tmpConsultSalesLine" : @"tmpSalesLine";
        NSString *sqlString = [NSString stringWithFormat:@"replace into %@ (CustAccount, ItemId, ItemName, AvailQty, Qty, Price, Discount, LineAmount, ContractId, BrandId, BrandName, ActionType, ActionId, OrigPrice, StoreID, isBadProduct, FirmId, FirmName, FirmMarkup) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", saleLineTable];
        const char *sql_3 = sqlString.UTF8String;
        
        sqlite3_stmt *addStmt;
        
        if (sqlite3_prepare_v2(database, sql_3, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [item[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [item[@"itemName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [item[@"qty"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [item[@"text"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [item[@"price"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [item[@"discount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, [item[@"lineAmount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 9, [contract UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 10, [item[@"brandID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 11, [brandName UTF8String], -1, SQLITE_TRANSIENT);
        
        if (actionType != nil)
            sqlite3_bind_text(addStmt, 12, [actionType UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(addStmt, 12, [@"0" UTF8String], -1, SQLITE_TRANSIENT);
        
        if (actionId != nil)
            sqlite3_bind_text(addStmt, 13, [actionId UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_text(addStmt, 13, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(addStmt, 14, [item[@"origPrice"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 15, [item[@"StoreID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 16, [item[@"isBadProduct"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 17, [firmID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 18, [firmName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 19, [firmMarkup UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    sqlite3_close(database);
}

- (void)createTmpSalesLine:(NSString *)custAccount itemId:(NSString *)itemId qty:(NSString *)qty price:(NSString *)price lineAmount:(NSString *)lineAmount {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        
        BOOL update = NO;
        
        const char *sql_1;
        
        sql_1 = "select ItemId from tmpSalesLine where CustAccount = ? and ItemId = ?";
        
        sqlite3_stmt *selstmt_1;
        
        if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt_1, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_1, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_1, 2, [itemId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_1) == SQLITE_ROW) {
                update = YES;
            }
            else
                update = FALSE;
        }
        sqlite3_finalize(selstmt_1);
        
        if (update) {
            [self updateTmpSalesLine:itemId qty:qty lineAmount:lineAmount custAccount:custAccount storeID:nil];
        } else {
            NSString *brandId  = @"null";
            NSString *contract = @"null";
            
            const char *sql_2;
            
            sql_2 = "select BrandId from ItemTable where ItemId = ?";
            
            sqlite3_stmt *selstmt_2;
            
            if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selstmt_2, 1, [itemId UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(selstmt_2) == SQLITE_ROW)
                {
                    if (sqlite3_column_text(selstmt_2, 0))
                        brandId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                }
                else
                    if (brandForItems)
                    {
                        brandId = brandForItems;
                    }
            }
            sqlite3_finalize(selstmt_2);
            
            const char *sql_3;
            
            sql_3 = "select ContractId from PersonalPriceList where BrandId = ? and CustAccount = ?";
            
            sqlite3_stmt *selstmt_3;
            
            if (sqlite3_prepare_v2(database, sql_3, -1, &selstmt_3, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selstmt_3, 1, [brandId UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(selstmt_3, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(selstmt_3) == SQLITE_ROW)
                {
                    if (sqlite3_column_text(selstmt_3, 0))
                        contract  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 0)];
                }
            }
            sqlite3_finalize(selstmt_3);
            
            
            sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into tmpSalesLine (CustAccount, ItemId, Qty, Price, LineAmount, ContractId, BrandId, ActionType, ActionId, OrigPrice) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [itemId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [qty UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [price UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [lineAmount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [contract UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [brandId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (actionType != nil)
                sqlite3_bind_text(addStmt, 8, [actionType UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(addStmt, 8, [@"0" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (actionId != nil)
                sqlite3_bind_text(addStmt, 9, [actionId UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(addStmt, 9, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
            
            //sqlite3_bind_text(addStmt, 10, [origPrice UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_step(addStmt);
            sqlite3_finalize(addStmt);
        }
    }
    sqlite3_close(database);
}

- (void)deleteTmpSalesLine:(NSString *)custAccount itemID:(NSString *)itemID isConsult:(BOOL)isConsult {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *deleteStmt;
        
        NSString *saleLineTable = isConsult ? @"tmpConsultSalesLine" : @"tmpSalesLine";
        NSString *sqlString;
        
        if (itemID) {
            sqlString = [NSString stringWithFormat:@"delete from %@ where CustAccount = ? and ItemId = ?", saleLineTable];
        } else {
            sqlString = [NSString stringWithFormat:@"delete from %@ where CustAccount = ?", saleLineTable];
        }
        const char *sql = sqlString.UTF8String;
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_text(deleteStmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        if (itemID) {
            sqlite3_bind_text(deleteStmt, 2, [itemID UTF8String], -1, SQLITE_TRANSIENT);
        }
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
    }
    sqlite3_close(database);
}

- (void)updateTmpSalesLine:(NSString *)itemId qty:(NSString *)newQty lineAmount:(NSString *)lineAmount custAccount:(NSString *)custAccount storeID:(NSString *)storeID {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *updateStmt;
        
        const char *sql = "update tmpSalesLine Set Qty = ?, lineAmount = ? where CustAccount = ? and ItemId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [newQty UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [lineAmount UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(updateStmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 4, [itemId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 5, [storeID UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
    }
    sqlite3_close(database);
}

- (void)createSalesLine:(NSString *)custAccount salesID:(NSString *)salesID item:(NSDictionary *)item{
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_1 = "select BrandName from Brand where BrandId = ?";
        sqlite3_stmt *selstmt_1;
        
        NSString *brandName = @"";
        
        if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt_1, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_1, 1, [item[@"brandID"] UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_1) == SQLITE_ROW) {
                if (sqlite3_column_text(selstmt_1, 0))
                    brandName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_1, 0)];
            }
            sqlite3_finalize(selstmt_1);
        }
        
        const char *sql_3 = "replace into SalesLine (SalesId, ItemId, ItemName, BrandName, Qty, AvailQty, Price, Discount, LineAmount, StoreID, isBadProduct) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *addStmt;
        
        if (sqlite3_prepare_v2(database, sql_3, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [salesID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [item[@"itemID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [item[@"itemName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [brandName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [item[@"text"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [item[@"qty"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [item[@"price"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, [item[@"discount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 9, [item[@"lineAmount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 10, [item[@"StoreID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 11, [item[@"isBadProduct"] UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    sqlite3_close(database);
}

- (void)deleteSalesLine:(NSString *)custAccount itemID:(NSString *)itemID salesID:(NSString *)salesID {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *deleteStmt;
        
        const char *sql = "delete from SalesLine where SalesId = ? and ItemId = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        //When binding parameters, index starts from 1 and not zero.
        sqlite3_bind_text(deleteStmt, 1, [salesID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 2, [itemID UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
    }
    sqlite3_close(database);
}

@end
