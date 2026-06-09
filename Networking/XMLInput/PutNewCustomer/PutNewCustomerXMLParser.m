//
//  PutNewCustomerXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 08.04.2014.
//
//

#import "PutNewCustomerXMLParser.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutNewCustomerXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation PutNewCustomerXMLParser {
    NSMutableDictionary *_newCustomerData;
    NSMutableDictionary *_currentData;
    NSMutableArray *_currentDataArray;
}

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:Customer"]) {
        _newCustomerData = [NSMutableDictionary new];
    } else if ([elementName isEqualToString:@"m:Contact"] || [elementName isEqualToString:@"m:Value"]) {
        _currentData = [NSMutableDictionary new];
    } else if ([elementName isEqualToString:@"m:PPL"] || [elementName isEqualToString:@"m:TTProperties"]) {
        _currentDataArray = [NSMutableArray new];
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
    elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
    
    if ([elementName isEqualToString:@"Customer"]) {
        [parser abortParsing];
        [self parserDidEndDocument:parser];
    }
    
    if ([elementName isEqualToString:@"Contact"]) {
        _newCustomerData[elementName] = _currentData;
        _currentData = nil;
    } else if ([elementName isEqualToString:@"PPL"] || [elementName isEqualToString:@"TTProperties"]) {
        _newCustomerData[elementName] = _currentDataArray;
    } else if ([elementName isEqualToString:@"Value"]) {
        [_currentDataArray addObject:_currentData];
        _currentData = nil;
    } else if (!_currentData) {
        _newCustomerData[elementName] = self.currentElementValue;
    } else {
        _currentData[elementName] = self.currentElementValue;
    }
    
    self.currentElementValue = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (!_newCustomerData[@"CustAccount"]) {
        [NSNotificationCenter.defaultCenter postNotificationName:@"SendNewCustomerNotification" object:@"NotSended"];
    } else {
        [self updateNewCustomer];
    }
}

- (void)updateNewCustomer {
    [self updateCustTable];
    [self updateCustStatusDN];
    [self updateCustContact];
    [self updatePersonalPriceList];
    [self updateTTPropertiesValue];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"SendNewCustomerNotification" object:@"Sended"];
}

- (void)updateCustTable {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *compiledStatement;
        
        const char *sql = "insert or ignore into CustTable (CustAccount, Name, Address, LegalName, Phone, Email, LocationDescription, Note, GPSPoint, FactAddress, INN, KPP, CustType, City, State, CustKey, TTId, TTName, LastVisitDate, LVDateComp, TenProp, PDZAmount, BankName, BankAccount, Property6, Property6Name, SendStatus) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &compiledStatement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(compiledStatement, 1, [_newCustomerData[@"CustAccount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 2, [_newCustomerData[@"Name"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 3, [_newCustomerData[@"Address"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 4, [_newCustomerData[@"LegalName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 5, [_newCustomerData[@"Phone"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 6, [_newCustomerData[@"Email"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 7, [_newCustomerData[@"LocationDescription"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 8, [_newCustomerData[@"Note"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 9, [_newCustomerData[@"GPSPoint"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 10, [_newCustomerData[@"FactAddress"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 11, [_newCustomerData[@"INN"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 12, [_newCustomerData[@"KPP"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 13, [_newCustomerData[@"CustType"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 14, [_newCustomerData[@"City"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 15, [_newCustomerData[@"State"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 16, [_newCustomerData[@"CustKey"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 17, [_newCustomerData[@"TTID"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 18, [_newCustomerData[@"TTName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 19, [_newCustomerData[@"LastVisitDate"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 21, [_newCustomerData[@"TenProp"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 22, [_newCustomerData[@"PDZAmount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 23, [_newCustomerData[@"BankName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 24, [_newCustomerData[@"BankAccount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 25, [_newCustomerData[@"Property6"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 26, [_newCustomerData[@"Property6Name"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(compiledStatement, 27, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(compiledStatement) != SQLITE_DONE) {
            NSLog(@"Commit Failed!");
        }
        
        sqlite3_finalize(compiledStatement);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)updateCustStatusDN {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *addStmt;
        
        const char *sql = "insert or ignore into CustStatusDN (CustAccount, StatusDN) Values(?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        sqlite3_bind_text(addStmt, 1, [_newCustomerData[@"CustAccount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [_newCustomerData[@"StatusDN"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(addStmt) != SQLITE_DONE) {
            NSLog(@"Commit Failed!");
        }
        
        sqlite3_finalize(addStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)updateCustContact {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *addStmt;
        
        const char *sql = "insert or ignore into CustContact (CustAccount, ContactId, Name, Phone, Email, Birthday, Position, SName, MName, ForDelete, Source) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
        NSDictionary *contact = _newCustomerData[@"Contact"];
        
        sqlite3_bind_text(addStmt, 1, [_newCustomerData[@"CustAccount"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 2, [contact[@"ContactId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 3, [contact[@"Name"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 4, [contact[@"Phone"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 5, [contact[@"Email"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 6, [contact[@"Birthday"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 7, [contact[@"Position"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 8, [contact[@"Sname"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 9, [contact[@"Mname"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 10, [contact[@"ForDelete"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(addStmt, 11, [contact[@"Source"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(addStmt) != SQLITE_DONE) {
            NSLog(@"Commit Failed!");
        }
        
        sqlite3_finalize(addStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)updatePersonalPriceList {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (NSDictionary *object in _newCustomerData[@"PPL"]) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into PersonalPriceList (CustAccount, BrandId, PriceTypeId, ContractId, Discount, Date, Round, ComDiscount, Active, Delay, MatrixId) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [_newCustomerData[@"CustAccount"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [object[@"BrandID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [object[@"PriceTypeID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [object[@"ContractID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [object[@"Discount"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [object[@"Date"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [object[@"Round"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [object[@"ComDiscount"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [object[@"Active"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 10, [object[@"Delay"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 11, [object[@"MatrixID"] UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)updateTTPropertiesValue {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (NSDictionary *object in _newCustomerData[@"PPL"]) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into TTPropertiesValue (PropertyId, Value, Date, CustAccount, SendStatus, ttId, ElementListId) Values(?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [object[@"PropertyID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [object[@"PropertyValue"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [object[@"Period"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [_newCustomerData[@"CustAccount"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [object[@"TTID"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [object[@"PropertyValueID"] UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

@end

