//
//  GetPersonalPricesXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 20.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GetPersonalPricesXMLParser.h"
#import "PersonalPrices.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetPersonalPricesXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *personalPricesArray;
@property (nonatomic, strong) PersonalPrices *personalPrices;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetPersonalPricesXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetPersonalPricesResponse"]) {
        //Initialize the array.
        [self deletePPrice];
        self.personalPricesArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        //Initialize the contact.
        self.personalPrices = [[PersonalPrices alloc] init];
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
        [self.personalPricesArray addObject:self.personalPrices];
        
        self.personalPrices = nil;
    } else if ([elementName isEqualToString:@"m:CustAccount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:BrandID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PriceTypeID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ContractID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Discount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Date"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Round"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ComDiscount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Active"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.personalPrices setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Delay"]) {
            elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
            [self.personalPrices setValue:self.currentElementValue forKey:elementName];
        } else if ([elementName isEqualToString:@"m:MatrixID"]) {
            elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
            [self.personalPrices setValue:self.currentElementValue forKey:elementName];
        }
    
    self.currentElementValue = nil;
}

- (void)createPPrice {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.personalPricesArray.count; y++) {
            static sqlite3_stmt *addStmt;
            
            // Andrey add Delay
            const char *sql = "insert or ignore into PersonalPriceList (CustAccount, BrandId, PriceTypeId, ContractId, Discount, Date, Round, ComDiscount, Active, Delay, MatrixId) Values( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            PersonalPrices *pPrices = self.personalPricesArray[y];
            
            sqlite3_bind_text(addStmt, 1, [pPrices.CustAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [pPrices.BrandID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [pPrices.PriceTypeID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [pPrices.ContractID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [pPrices.Discount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [pPrices.Date UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [pPrices.Round UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [pPrices.ComDiscount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [pPrices.Active UTF8String], -1, SQLITE_TRANSIENT);
            // Andrey
            sqlite3_bind_text(addStmt, 10, [pPrices.Delay UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 11, [pPrices.MatrixID UTF8String], -1, SQLITE_TRANSIENT);
            
            //NSLog(@"Delay: %@", pPrices.Delay);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
            pPrices = nil;
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.personalPricesArray = nil;
    }
    sqlite3_close(database);
}

- (void)deletePPrice {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;

        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from PersonalPriceList"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.personalPricesArray.count > 0) {
        [self createPPrice];
    }
}

@end

