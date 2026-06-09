//
//  PutOrdersNewXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 22.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PutOrdersNewXMLParser.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutOrdersNewXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@property (nonatomic, copy) NSString *salesStatus;

@end

@implementation PutOrdersNewXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict {
    
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
    if ([elementName isEqualToString:@"m:Error"]) {
        self.salesStatus = self.currentElementValue.copy;
    }

    self.currentElementValue = nil;
}

- (void)updateSales {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;
        
        NSString *salesTable = self.isConsult ? @"ConsultSalesTable" : @"SalesTable";
        NSString *sqlString = [NSString stringWithFormat:@"update %@ Set SalesStatus = ? where SalesId = ?", salesTable];
        const char *sql = sqlString.UTF8String;
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [self.salesStatus UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [self.salesId UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.salesStatus.length > 0) {
        self.salesStatus = [NSString stringWithFormat:@"%@%@", [self.salesStatus substringToIndex:1].uppercaseString, [self.salesStatus substringFromIndex:1]];
    }
        
    [self updateSales];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"SalesSended" object:@{@"salesID" : self.salesId, @"salesStatus" : self.salesStatus}];
}

@end
