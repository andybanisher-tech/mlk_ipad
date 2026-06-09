//
//  GetBrandXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 05.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "GetBrandXMLParser.h"
#import "Brand.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetBrandXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *brands;
@property (nonatomic, strong) Brand *brand;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetBrandXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
    
    if ([elementName isEqualToString:@"m:GetBrandResponse"]) {
        //Initialize the array.
        [self deleteBrand];
        self.brands = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        //Initialize the contact.
        self.brand = [[Brand alloc] init];
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
        [self.brands addObject:self.brand];

        self.brand = nil;
	} else if ([elementName isEqualToString:@"m:BrandID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.brand setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:BrandName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.brand setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createBrand {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.brands.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert into Brand (BrandId, BrandName) Values(? , ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            Brand *brand = self.brands[y];
            
            sqlite3_bind_text(addStmt, 1, [brand.BrandID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [brand.BrandName UTF8String], -1, SQLITE_TRANSIENT);
            
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

- (void)deleteBrand {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat: 
                                 @"delete from Brand"] UTF8String], NULL, NULL, NULL); 
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.brands.count > 0) {
        [self createBrand];
    }
}

@end
