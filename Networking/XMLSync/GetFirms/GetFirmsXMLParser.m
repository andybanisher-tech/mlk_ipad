//
//  GetFirmsXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 21.01.13.
//
//

#import "GetFirmsXMLParser.h"
#import "Firm.h"
#import "NoticeViewController.h"
#import "AppDelegate.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetFirmsXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *firms;
@property (nonatomic, strong) Firm *firm;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetFirmsXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetFirmsResponse"]) {
        [self deleteFirm];
        self.firms = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.firm = [[Firm alloc] init];
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
        [self.firms addObject:self.firm];

        self.firm = nil;
    } else if ([elementName isEqualToString:@"m:ID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.firm setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Name"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                
        [self.firm setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Default"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.firm setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Markup"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.firm setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createFirm {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.firms.count; y++) {
            
            Firm *firm_local = self.firms[y];
            
            static sqlite3_stmt *addStmt;
                
            const char *sql = "insert or ignore into FirmTable (FirmId, Name, Def, Markup) Values(?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
            sqlite3_bind_text(addStmt, 1, [firm_local.ID      UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [firm_local.Name    UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [firm_local.Default UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [firm_local.Markup  UTF8String], -1, SQLITE_TRANSIENT);
                
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
                
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.firms = nil;
    }
    sqlite3_close(database);
    
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    
    if ([appDelegate checkForNew]) {
        [appDelegate showNotice];
    }
}

- (void)deleteFirm {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from FirmTable"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.firms.count > 0) {
        [self createFirm];
    }
}

@end
