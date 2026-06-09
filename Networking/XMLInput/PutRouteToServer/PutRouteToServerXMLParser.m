//
//  PutRouteToServerXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 21.01.13.
//
//

#import "PutRouteToServerXMLParser.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutRouteToServerXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@property (nonatomic, copy) NSString *response;
@property (nonatomic, copy) NSString *responseStatus;

@end

@implementation PutRouteToServerXMLParser {
    BOOL _getResponseStatus;
}

- (void)parseData:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (NSString *)getResponseStatus:(NSData *)webData {
    _getResponseStatus = YES;
    [self parseData:webData];
    
    return self.responseStatus;
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
        self.response = self.currentElementValue.copy;
    }

    self.currentElementValue = nil;
}

- (void)updateRoute {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        static sqlite3_stmt *updateStmt;
        
        const char *sql = "update Route Set SendStatus = ? where SendStatus = ?";
        
        sqlite3_prepare_v2(database, sql, -1, &updateStmt, NULL);
        
        sqlite3_bind_text(updateStmt, 1, [self.response UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(updateStmt, 2, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
        
        sqlite3_step(updateStmt);
        sqlite3_finalize(updateStmt);
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    self.responseStatus = self.response.copy;
    
    if ([self.response localizedStandardContainsString:@"получено"]) {
        self.response = @"Sended";
    } else {
        self.response = @"new";
    }
    
    if (!_getResponseStatus) {
        [self updateRoute];
    }
}

- (NSString *)returnResult:(NSString *)result {
    return result;
}

@end

