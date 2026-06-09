//
//  GetCustContactXMLParser.m
//  MLK
//
//  Created by Nikita on 21/01/15.
//
//

#import "GetCustContactXMLParser.h"
#import "CustContact.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetCustContactXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) CustContact *contact;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetCustContactXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetCustContactNewResponse"] ||
       [elementName isEqualToString:@"m:GetCustContactDopResponse"]) {
        [self deleteContact];
        self.contacts = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.contact = [[CustContact alloc] init];
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
        [self.contacts addObject:self.contact];

        self.contact = nil;
    } else if ([elementName isEqualToString:@"m:Sname"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
            
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Name"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Mname"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                    
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Birthday"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Position"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                            
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Phone"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Email"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                    
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ForDelete"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                        
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Source"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                            
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:CustAccount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                
        [self.contact setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ContactId"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
                                                    
        [self.contact setValue:self.currentElementValue forKey:elementName];
    }

    self.currentElementValue = nil;
}

- (void)createContact {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.contacts.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into CustContact (CustAccount, ContactId, Name, Phone, Email, Birthday, Position, SName, MName, ForDelete, Source) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            CustContact *contact_local = self.contacts[y];
            
            sqlite3_bind_text(addStmt, 1, [contact_local.custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [contact_local.contactId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [contact_local.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [contact_local.phone UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [contact_local.email UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [contact_local.birthday UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [contact_local.position UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [contact_local.sname UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [contact_local.mname UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 10,[contact_local.forDelete UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 11,[contact_local.source UTF8String], -1, SQLITE_TRANSIENT);

            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
}

- (void)deleteContact {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from CustContact"] UTF8String], NULL, NULL, NULL);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.contacts.count > 0) {
        [self createContact];
    }
}

@end

