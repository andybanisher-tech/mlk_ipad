//
//  GetNewCustomerXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 08.05.2014.
//
//

#import "GetNewCustomerXMLParser.h"
#import "NewCustomer.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetNewCustomerXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *customersArray;
@property (nonatomic, strong) NewCustomer *customer;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetNewCustomerXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
	
	if ([elementName isEqualToString:@"m:GetNewCustomerResponse"]) {
		self.customersArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.customer = [[NewCustomer alloc] init];
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
        [self.customersArray addObject:self.customer];

        self.customer = nil;
    } else if ([elementName isEqualToString:@"m:Date"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Name"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:FactAddress"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Phone"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Email"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Contact"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                        
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Location"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Uid"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.customer setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createCustomer {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.customersArray.count; y++) {
            static sqlite3_stmt *compiledStatement;
        
            const char *sql = "insert or ignore into CustTable (CustAccount, Name, FactAddress, Phone, Email, GPSPoint, Note, NewCustomer, SendStatus, CreatedDate) Values( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
            if (sqlite3_prepare_v2(database, sql, -1, &compiledStatement, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
            NewCustomer *newCustoemr_local = self.customersArray[y];
            
            sqlite3_bind_text(compiledStatement, 1, [newCustoemr_local.Uid UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 2, [newCustoemr_local.Name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 3, [newCustoemr_local.FactAddress UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 4, [newCustoemr_local.Phone UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 5, [newCustoemr_local.Email UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 6, [newCustoemr_local.Location UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 7, [newCustoemr_local.Contact UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 8, [@"yes" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 9, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 10,[newCustoemr_local.Date UTF8String], -1, SQLITE_TRANSIENT);
        
            if (sqlite3_step(compiledStatement) != SQLITE_DONE)
                NSLog(@"Commit Failed!");
        
            sqlite3_finalize(compiledStatement);
        }
        
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        
        [self createDream];
    }
    sqlite3_close(database);
}

- (void)createDream {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.customersArray.count; y++) {
            static sqlite3_stmt *addStmt;
        
            const char *sql = "insert or ignore into CustStatusDN (CustAccount, StatusDN) Values(?, ?)";
        
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
            NewCustomer *newCustoemr_local = self.customersArray[y];
            
            sqlite3_bind_text(addStmt, 1, [newCustoemr_local.Uid UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [@"3" UTF8String], -1, SQLITE_TRANSIENT);
        
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
        
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.customersArray = nil;
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.customersArray.count > 0) {
        [self createCustomer];
    }
}

@end
