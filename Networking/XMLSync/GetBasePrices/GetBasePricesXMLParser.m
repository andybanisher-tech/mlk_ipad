//
//  GetBasePricesXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 13.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GetBasePricesXMLParser.h"
#import "BasePrice.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetBasePricesXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *basePriceArray;
@property (nonatomic, strong) BasePrice *basePrice;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetBasePricesXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetBasePricesResponse"]) {
        //Initialize the array.
        [self deleteBPrice];
        self.basePriceArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        //Initialize the contact.
        self.basePrice = [[BasePrice alloc] init];
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
        [self.basePriceArray addObject:self.basePrice];

        self.basePrice = nil;
	} else if ([elementName isEqualToString:@"m:ItemID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.basePrice setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Price"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.basePrice setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PriceDate"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.basePrice setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:PriceTypeID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.basePrice setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createBPrice {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.basePriceArray.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into BasePriceTable (ItemId, Price, PriceDate, PriceTypeId) Values(?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            BasePrice *basePrice = self.basePriceArray[y];
            
            sqlite3_bind_text(addStmt, 1, [basePrice.ItemID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [basePrice.Price UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [basePrice.PriceDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [basePrice.PriceTypeID UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.basePriceArray = nil;
    }
    sqlite3_close(database);
}

- (void)deleteBPrice {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat: 
                                 @"delete from BasePriceTable"] UTF8String], NULL, NULL, NULL); 
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.basePriceArray.count > 0) {
        [self createBPrice];
    }
}

@end

