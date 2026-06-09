//
//  GetRouteDistXMLParser.m
//  MLK
//
//  Created by Nikita on 19/02/15.
//
//

#import "GetRouteDistXMLParser.h"
#import "Route.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetRouteDistXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *routes;
@property (nonatomic, strong) Route *route;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetRouteDistXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
    
	if ([elementName isEqualToString:@"m:GetRouteDistResponse"]) {
		[self deleteRoute];
        self.routes = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.route = [Route new];
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
        [self.routes addObject:self.route];
        self.route = nil;
    } else if ([elementName isEqualToString:@"m:CustAccount"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        if ([self.currentElementValue isEqualToString:@"Start"])
            [self.route setValue:@"START" forKey:elementName];
        else if ([self.currentElementValue isEqualToString:@"Stop"])
            [self.route setValue:@"STOP" forKey:elementName];
        else
            [self.route setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:LineNum"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.route setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:DateOfRoute"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.route setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Status"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        if ([self.currentElementValue isEqualToString:@"VISIT"])
            [self.route setValue:@"visit" forKey:elementName];
        else if ([self.currentElementValue isEqualToString:@"VISITED"])
            [self.route setValue:@"visited" forKey:elementName];
        else
            [self.route setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:GPSPoint"]) {
        [self.route setValue:self.currentElementValue forKey:@"gpsPoint"];
    } else if ([elementName isEqualToString:@"m:TimeOfRoute"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [self.route setValue:self.currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:NearCust"]) {
        self.route.nearCust = self.currentElementValue;
    }

    self.currentElementValue = nil;
}

- (void)createRoute {
    //Finding NearCust duplicates
    NSMutableIndexSet *indicesToRemove = [NSMutableIndexSet new];
    NSMutableArray *nearCustArray = [NSMutableArray new];
    for (int i = 0; i < self.routes.count; i++) {
        Route *route_local = self.routes[i];
        
        if (!route_local.nearCust) { continue; }
        
        NSUInteger searchIndex = [nearCustArray indexOfObjectPassingTest:^BOOL(Route *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.custAccount isEqualToString:route_local.custAccount];
        }];
        
        if (searchIndex != NSNotFound) {
            Route *nearCust = nearCustArray[searchIndex];
            nearCust.nearCust = [NSString stringWithFormat:@"%@,%@", nearCust.nearCust, route_local.nearCust];
        } else {
            [nearCustArray addObject:route_local];
        }
        
        [indicesToRemove addIndex:i];
    }
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < self.routes.count; y++) {
            Route *route_local = self.routes[y];
            if ([route_local.custAccount isEqualToString:@"START"] || [route_local.custAccount isEqualToString:@"STOP"])
                continue;
            
            NSString *custName = @"null";
            NSString *custAddress = @"null";
            
            sqlite3_stmt *selectstmt;
            
            NSString *custTable = self.isSchedulerRequest ? @"tmpCustTable" : @"CustTable";
            NSString *sqlCustString = [NSString stringWithFormat:@"select Name, Address from %@ where CustAccount = ?", custTable];
            
            const char *sqlCust = sqlCustString.UTF8String;
            
            if (sqlite3_prepare_v2(database, sqlCust, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, [route_local.custAccount UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(selectstmt) == SQLITE_ROW)
                {
                    if (sqlite3_column_text(selectstmt, 0))
                        custName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    
                    if (sqlite3_column_text(selectstmt, 1))
                        custAddress = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                }
            }
            sqlite3_finalize(selectstmt);
            
            NSString *custForRoute = self.isSchedulerRequest ? @"tmpCustForRoute" : @"CustForRoute";
            NSString *sqlString = [NSString stringWithFormat:@"insert or ignore into %@ (CustAccount, DateOfRoute, RegularRoute, Status, CustName, CustAddress, lineNum, GPSPoint, TimeOfRoute, NearCust, GPSRequest, isSended) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", custForRoute];

            static sqlite3_stmt *addStmt;
            
            const char *sql = sqlString.UTF8String;
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [route_local.custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [route_local.dateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [@"No" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [route_local.status UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [custName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [custAddress UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [route_local.lineNum UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [route_local.gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [route_local.timeOfRoute UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 10, [route_local.nearCust UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 11, [@"" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(addStmt, 12, 1);
            
//            NSLog(@"Status is : %@",route_local.status);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
    
    if (!self.isSchedulerRequest) {
        [self insertRoute];
    }
}

- (void)insertRoute {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        for (int y = 0; y < self.routes.count; y++) {
            Route *route_local = self.routes[y];
            if ([route_local.custAccount isEqualToString:@"START"] || [route_local.custAccount isEqualToString:@"STOP"]) {
                const char *sql = "insert or ignore into StartStop (Date, Status, isSended) Values(?, ?, ?)";
                sqlite3_stmt *statement;
                
                if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                sqlite3_bind_text(statement, 1, [route_local.dateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(statement, 2, [route_local.custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(statement, 3, 1);
                
                if (sqlite3_step(statement) != SQLITE_DONE)
                {
                    NSLog(@"Commit Failed!");
                }
                sqlite3_finalize(statement);
            }
            
            sqlite3_stmt *addStmt;
            const char *sql = "insert or ignore into Route (DateOfRoute, TimeOfRoute, lineNum, GPSPoint, CustAccount, Status, SendStatus) Values(?, ?, ?, ?, ?, ?, ?)";
        
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
        
            sqlite3_bind_text(addStmt, 1, [route_local.dateOfRoute UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [route_local.timeOfRoute UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [route_local.lineNum UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [route_local.gpsPoint UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [route_local.custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [route_local.status UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [@"Sended" UTF8String], -1, SQLITE_TRANSIENT);
        
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            sqlite3_finalize(addStmt);
            
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        self.routes = nil;
    }
    sqlite3_close(database);
}

- (void)deleteRoute {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        NSString *custForRoute = self.isSchedulerRequest ? @"tmpCustForRoute" : @"CustForRoute";
        NSString *sqlString = [NSString stringWithFormat:@"delete from %@", custForRoute];
        
        sqlite3_exec(database, sqlString.UTF8String, NULL, NULL, NULL);
        
        if (!self.isSchedulerRequest) {
            sqlite3_exec(database, [[NSString stringWithFormat:
                                     @"delete from StartStop"] UTF8String], NULL, NULL, NULL);
        }
    }

    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.routes.count > 0) {
        [self createRoute];
    }
}

@end
