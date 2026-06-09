//
//  MoreCustXMLParser.m
//  MLK
//
//  Created by garu on 11/10/14.
//
//

#import "MoreCustXMLParser.h"
#import "CustTable.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface MoreCustXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *customers;
@property (nonatomic, strong) CustTable *customer;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation MoreCustXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
	
    if ([elementName isEqualToString:@"m:GetCustTableDopResponse"]) {
        //Initialize the array.
        self.customers = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.customer = [[CustTable alloc] init];
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
        [ self.customers addObject:self.customer];

        self.customer = nil;
	} else if ([elementName isEqualToString:@"m:CustAccount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Name"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Address"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:LegalName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                        
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Phone"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Email"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:LocationDescription"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                    
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Note"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                        
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:GPSPoint"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                            
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:FactAddress"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:INN"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                    
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:KPP"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                        
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:CustType"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                            
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:City"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:State"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                                    
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:CustKey"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                                        
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:TTID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                                            
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:TTName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                                                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:LastVisitDate"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                                                    
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:TenProp"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Property6"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Property6Name"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.customer setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if ( self.customers.count > 0) {
        [self createCustTable];
    }
}

- (void)createCustTable {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y <  self.customers.count; y++) {
            static sqlite3_stmt *compiledStatement;
            
            const char *sql = "insert or ignore into CustTable (CustAccount, Name, Address, LegalName, Phone, Email, LocationDescription, Note, GPSPoint, FactAddress, INN, KPP, CustType, City, State, CustKey, TTId, TTName, LastVisitDate, LVDateComp, AdditionalCust, TenProp, Property6, Property6Name) Values( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &compiledStatement, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            CustTable *cust =  self.customers[y];
            
            sqlite3_bind_text(compiledStatement, 1, [cust.CustAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 2, [cust.Name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 3, [cust.Address UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 4, [cust.LegalName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 5, [cust.Phone UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 6, [cust.Email UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 7, [cust.LocationDescription UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 8, [cust.Note UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 9,  [cust.GPSPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 10, [cust.FactAddress UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 11, [cust.INN UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 12, [cust.KPP UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 13, [cust.CustType UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 14, [cust.City UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 15, [cust.State UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 16, [cust.CustKey UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 17, [cust.TTID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 18, [cust.TTName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 19, [cust.LastVisitDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 21, [@"1" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 22, [cust.tenProp UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 23, [cust.Property6 UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 24, [cust.Property6Name UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(compiledStatement) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(compiledStatement);
            
            static sqlite3_stmt *addStmt;
                        
            const char *sqlDN = "insert or ignore into CustStatusDN (CustAccount, StatusDN) Values(?, ?)";
                        
            if (sqlite3_prepare_v2(database, sqlDN, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                        
            sqlite3_bind_text(addStmt, 1, [cust.CustAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [@"4" UTF8String], -1, SQLITE_TRANSIENT);
                        
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.customers = nil;
    }
    sqlite3_close(database);
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"updateParent" object:nil];
}

@end
