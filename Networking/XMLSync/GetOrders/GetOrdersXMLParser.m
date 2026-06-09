//
//  GetOrdersXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 24.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "GetOrdersXMLParser.h"
#import "SalesLine.h"
#import "SalesTable.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetOrdersXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *salesLineArray;
@property (nonatomic, strong) SalesLine *salesLine;

@property (nonatomic, strong) NSMutableArray *salesTableArray;
@property (nonatomic, strong) SalesTable *salesTable;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetOrdersXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetOrdersResponse"]) {
        //Initialize the array.
        //[self deleteleSas];
        //[self deleteSalesLine];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.salesLineArray = [NSMutableArray new];
        self.salesTableArray = [NSMutableArray new];
        
        self.salesTable = [[SalesTable alloc] init];
    } else if ([elementName isEqualToString:@"m:SalesLines"]) {
        self.salesLine = [[SalesLine alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:
                               NSCharacterSet.whitespaceAndNewlineCharacterSet];
    
    if (!self.currentElementValue) {
        self.currentElementValue = [[NSMutableString alloc] initWithString:trimmedString];
    } else {
        [self.currentElementValue appendString:trimmedString];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"m:Value"]) {
        [self.salesTableArray addObject:self.salesTable];
        
        self.salesTable = nil;
        
        [self createSales];
    } else if ([elementName isEqualToString:@"m:SalesNum"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:SalesDate"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:DeliveryDate"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:CustAccount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ContractID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:AmountSum"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ChannelTypeID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:SalesStatus"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Comment"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:SalesNum1c"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:SalesUUID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesTable setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:SalesLines"]) {
        [self.salesLineArray addObject:self.salesLine];
        
        self.salesLine = nil;
    } else if ([elementName isEqualToString:@"m:ItemID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ItemName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:BrandName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Qty"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:AvailQty"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Price"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Discount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:LineAmount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:StoreID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:isBadProduct"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ActionID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    }
    if ([elementName isEqualToString:@"m:ActionType"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.salesLine setValue:self.currentElementValue forKey:elementName];
    }
    
    self.currentElementValue = nil;
}

- (void)createSales {
    NSString *prevSalesId = nil;
    NSString *num = nil;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.salesTableArray.count; y++) {
            if (self.syncSalesLine) {
                SalesTable *tables = self.salesTableArray[y];
                
                [self findSales:tables.SalesUUID custAccount:tables.CustAccount];
                
                const char *sqlLine = "select SalesId from SalesTable where Num1C = ?";
                sqlite3_stmt *statement;
                
                if (sqlite3_prepare_v2(database, sqlLine, -1, &statement, NULL) == SQLITE_OK) {
                    sqlite3_bind_text(statement, 1, [self.syncNum1C UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(statement) == SQLITE_ROW) {
                        NSString *salesId = @"null";
                        
                        if (sqlite3_column_text(statement, 0)) {
                            salesId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                            
                            num = salesId;
                        }
                        
                    }
                }
                sqlite3_finalize(statement);
            } else {
                // Andrey -
                
                static sqlite3_stmt *addStmt;
                
                const char *sql = "insert or ignore into SalesTable (CustAccount, SalesId, SalesDate, AmountSum, SalesNum, ChannelTypeId, ContractId, SalesStatus, Comment, ActionId, CreatedTime, Num1C, SalesUUID, SalesDateSort, ActionType, DeliveryDate) Values( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                SalesTable *tables = self.salesTableArray[y];
                
                if ([tables.CustAccount isEqualToString:@"С44754"])
                    NSLog(@"%@ %@ %@", tables.SalesNum1c, tables.SalesUUID, tables.SalesNum);
                
                [self findSales:tables.SalesUUID custAccount:tables.CustAccount];
                
                sqlite3_bind_text(addStmt, 1, [tables.CustAccount UTF8String], -1, SQLITE_TRANSIENT);
                
                prevSalesId = [PersistenceWorker load:@"salesID"];
                num = [NSString stringWithFormat:@"%i", ([prevSalesId intValue] + 1)];
                
                [PersistenceWorker save:num key:@"salesID"];
                
                sqlite3_bind_text(addStmt, 2, [num UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [tables.SalesDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [tables.AmountSum UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [tables.SalesNum1c UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 6, [tables.ChannelTypeID UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 7, [tables.ContractID UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 8, [tables.SalesStatus UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 9, [tables.Comment UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 10, [tables.ActionID UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 11, [@"00.00.00" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 12, [tables.SalesNum1c UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 13, [tables.SalesUUID UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 15, [tables.ActionType UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 16, [tables.DeliveryDate UTF8String], -1, SQLITE_TRANSIENT);
                
                NSDate *endDate;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                endDate = [dateFormatter dateFromString:tables.SalesDate];
                [dateFormatter setDateFormat:dateFormat_YYYY_MM_dd];
                
                sqlite3_bind_text(addStmt, 14, [[dateFormatter stringFromDate:endDate] UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(addStmt) != SQLITE_DONE) {
                    NSLog(@"Commit Failed!");
                }
                sqlite3_finalize(addStmt);
            }
            
            [self createSalesLine:num];
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.salesTableArray = nil;
    }
    sqlite3_close(database);
}

- (void)updateLastSalesTPDate {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql;
        
        sql = "select CustAccount from CustTable order by Name asc";
        
        sqlite3_stmt *selectstmt;
        
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                const char *sql_2;
                
                sql_2 = "select SalesDate, SalesDateSort, ChannelTypeId from SalesTable where CustAccount = ? order by SalesDateSort desc limit 1";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt_2, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW)
                    {
                        NSString *salesDate = @"null";
                        NSString *salesDateSort = @"null";
                        NSString *channel = @"null";
                        
                        if (sqlite3_column_text(selstmt_2, 0))
                            salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                        
                        if (sqlite3_column_text(selstmt_2, 1))
                            salesDateSort = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 1)];
                        
                        if (sqlite3_column_text(selstmt_2, 2))
                            channel = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 2)];
                        
                        const char *sql_3 = "update CustTable Set SalesDate = ?, SalesDateSort = ?, ChannelTypeId = ? where CustAccount = ?";
                        
                        sqlite3_stmt *updateStmt;
                        
                        if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK)
                        {
                            sqlite3_bind_text(updateStmt, 1, [salesDate UTF8String], -1, SQLITE_TRANSIENT);
                            sqlite3_bind_text(updateStmt, 2, [salesDateSort UTF8String], -1, SQLITE_TRANSIENT);
                            sqlite3_bind_text(updateStmt, 3, [channel UTF8String], -1, SQLITE_TRANSIENT);
                            sqlite3_bind_text(updateStmt, 4, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
                            
                            sqlite3_step(updateStmt);
                            sqlite3_finalize(updateStmt);
                            
                            NSLog(@"%@", salesDate);
                            
                        }
                    }
                }
                sqlite3_finalize(selstmt_2);
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)createSalesLine:(NSString *)salesId {
    for (SalesLine *lines in self.salesLineArray) {
        static sqlite3_stmt *addStmt;
        
        const char *sql = "replace into SalesLine (SalesId, ItemId, ItemName, BrandName, Qty, AvailQty, Price, Discount, LineAmount, StoreID, isBadProduct) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        NSString *itemID = lines.ItemID;
        if ([lines.isBadProduct isEqual:@"1"]) {
            itemID = [NSString stringWithFormat:@"%@/%@", itemID,  lines.StoreID];
        }
        
        NSString *price = [NSString stringWithFormat:@"%0.2lf", ([lines.Price doubleValue]/(1-[lines.Discount doubleValue]/100))];
        
        sqlite3_bind_text(addStmt, 2, [itemID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [lines.ItemName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [lines.BrandName UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [lines.Qty UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [lines.AvailQty UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [price UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, [lines.Discount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 9, [lines.LineAmount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 10, [lines.StoreID UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 11, [lines.isBadProduct UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(addStmt);
        sqlite3_finalize(addStmt);
    }
    self.salesLineArray = nil;
}

- (void)findSales:(NSString *)uuid custAccount:(NSString *)custAccount {
    const char *sql = "select SalesId, SalesDate from SalesTable where SalesUUID = ? and CustAccount = ?";
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [uuid UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(statement, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(statement) == SQLITE_ROW) {
            NSString *salesId = @"null";
            NSString *salesDate = @"null";
            
            if (sqlite3_column_text(statement, 0))
                salesId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            
            if (sqlite3_column_text(statement, 1))
                salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
            
            [self removeSales:salesId salesDate:salesDate custAccount:custAccount];
        }
    }
    sqlite3_finalize(statement);
}

- (void)removeSales:(NSString *)salesId salesDate:(NSString *)salesDate custAccount:(NSString *)custAccount {
    if (!self.syncSalesLine || self.removeOld) {
        sqlite3_stmt *deleteStmt;
        
        const char *sql = "delete from SalesTable where SalesId = ? and SalesDate = ? and CustAccount = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &deleteStmt, NULL);
        
        sqlite3_bind_text(deleteStmt, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 2, [salesDate UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(deleteStmt, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(deleteStmt);
        sqlite3_finalize(deleteStmt);
    }
    
    sqlite3_stmt *deleteStmt_2;
    
    const char *sql_2 = "delete from SalesLine where SalesId = ?";
    
    sqlite3_prepare_v2(database, sql_2, -1, &deleteStmt_2, NULL);
    
    sqlite3_bind_text(deleteStmt_2, 1, [salesId UTF8String], -1, SQLITE_TRANSIENT);
    
    sqlite3_step(deleteStmt_2);
    sqlite3_finalize(deleteStmt_2);
}

- (void)checkSales {
    NSDate *endDate = NSDate.date;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select SalesId, SalesDate from SalesTable";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSString *salesId = @"null";
                NSString *salesDate = @"null";
                
                if (sqlite3_column_text(statement, 0))
                    salesId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                
                if (sqlite3_column_text(statement, 1))
                    salesDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                
                [formatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                NSDate *startDate = [formatter dateFromString:salesDate];
                
                NSCalendar       *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                    fromDate:startDate
                                                                      toDate:endDate
                                                                     options:0];
                
                if ([components day] > 30) {
                    [self removeSales:salesId salesDate:salesDate custAccount:nil];
                }
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self updateLastSalesTPDate];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"SalesUpdated" object:self.syncNum1C];
}

@end

