//
//  GetStatusDNBrendXMLParser.m
//  mlk
//
//  Created by Nikolya Smolnyakov on 14.10.16.
//
//

#import "GetStatusDNBrendXMLParser.h"
#import "StatusDNBrand.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetStatusDNBrendXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *brands;
@property (nonatomic, strong) StatusDNBrand *statusDNBrand;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetStatusDNBrendXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetStatusDNBrendResponse"]) {
        [self deleteStatusDNBrand];
        self.brands = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.statusDNBrand = [StatusDNBrand new];
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
        [self.brands addObject:self.statusDNBrand];
        
        self.statusDNBrand = nil;
    } else if ([elementName isEqualToString:@"m:CustomerID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.statusDNBrand setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Status"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.statusDNBrand setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:BrandID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.statusDNBrand setValue:self.currentElementValue forKey:elementName];
    }
    
    self.currentElementValue = nil;
}

- (void)createStatusDNBrand {
    [self updateCustPP];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.brands.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into CustStatusDNBrand (CustAccount, Status, BrandID) Values(?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            StatusDNBrand *statusDNBrand_local = self.brands[y];
            
            sqlite3_bind_text(addStmt, 1, [statusDNBrand_local.CustomerID UTF8String], -1, SQLITE_TRANSIENT);
            
            if ([statusDNBrand_local.Status isEqualToString:@""])
                sqlite3_bind_text(addStmt, 2, [@"Без статуса" UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(addStmt, 2, [statusDNBrand_local.Status UTF8String], -1, SQLITE_TRANSIENT);
            
            sqlite3_bind_text(addStmt, 3, [statusDNBrand_local.BrandID UTF8String], -1, SQLITE_TRANSIENT);
            
            NSLog(@"%@", statusDNBrand_local.Status);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.brands = nil;
    }
    sqlite3_close(database);
}

- (void)updateCustPP {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.brands.count; y++) {
            const char *sql_2 = "update PersonalPriceList Set NeedPhoto = ? where BrandID = ? and CustAccount = ?";
            static sqlite3_stmt *updateStmt;
            
            if (sqlite3_prepare_v2(database, sql_2, -1, &updateStmt, NULL) == SQLITE_OK) {
                StatusDNBrand *statusDNBrand_local = self.brands[y];
                
                if ([statusDNBrand_local.Status isEqualToString:@"Работает"] ||
                   [statusDNBrand_local.Status isEqualToString:@"Закрытие"] ||
                   [statusDNBrand_local.Status isEqualToString:@"Новый"] ||
                   [statusDNBrand_local.Status isEqualToString:@"Новый(Запуск)"])
                {
                    sqlite3_bind_text(updateStmt, 1, [@"1" UTF8String], -1, SQLITE_TRANSIENT);
                } else {
                    sqlite3_bind_text(updateStmt, 1, [@"2" UTF8String], -1, SQLITE_TRANSIENT);
                }
                
                sqlite3_bind_text(updateStmt, 2, [statusDNBrand_local.BrandID UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 3, [statusDNBrand_local.CustomerID UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_step(updateStmt);
            }
            sqlite3_finalize(updateStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)deleteStatusDNBrand {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from CustStatusDNBrand"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.brands.count > 0) {
        [self createStatusDNBrand];
    }
}


@end
