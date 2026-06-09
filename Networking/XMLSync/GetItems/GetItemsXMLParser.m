//
//  GetItemsXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 07.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "GetItemsXMLParser.h"
#import "Items.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface GetItemsXMLParser () <NSXMLParserDelegate>

@end

@implementation GetItemsXMLParser {
    NSMutableString *_currentElementValue;
    Items           *_aItems;
    NSMutableArray  *_array;
    
    NSMutableArray *_allStoresArray;
    NSMutableArray *_currentItemStoresArray;
    NSMutableDictionary *_currentStore;
    
    NSMutableArray *_currentItemBadProductArray;
    NSMutableDictionary *_currentBadProduct;
}

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetItemsResponse"]) {
        //Initialize the array.
        [self deleteItems];
        _array = [NSMutableArray new];
        _allStoresArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        //Initialize the contact.
        _aItems = [Items new];
        _currentItemStoresArray = [NSMutableArray new];
        _currentItemBadProductArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Stores"]) {
        _currentStore = [NSMutableDictionary new];
    } else if ([elementName isEqualToString:@"m:BadProduct"]) {
        _currentBadProduct = [NSMutableDictionary new];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:
                               NSCharacterSet.whitespaceAndNewlineCharacterSet];
    
    if (!_currentElementValue) {
        _currentElementValue = [[NSMutableString alloc] initWithString:trimmedString];
    } else {
        [_currentElementValue appendString:trimmedString];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"m:Value"]) {
        [_allStoresArray addObjectsFromArray:_currentItemStoresArray];
        
        NSData *storesData = [NSJSONSerialization dataWithJSONObject:_currentItemStoresArray options:0 error:nil];
        NSString *storesJSONString = [[NSString alloc] initWithData:storesData encoding:NSUTF8StringEncoding];
        
        NSData *badProductData = [NSJSONSerialization dataWithJSONObject:_currentItemBadProductArray options:0 error:nil];
        NSString *badProductJSONString = [[NSString alloc] initWithData:badProductData encoding:NSUTF8StringEncoding];
        
        _aItems.storesJSON = storesJSONString;
        _aItems.qty = _currentItemStoresArray.firstObject[@"QtyS"];
        _aItems.badProductJSON = badProductJSONString;
        _aItems.isBadProduct = @"0";
        
        [_array addObject:_aItems];
        _aItems = nil;
    } else if ([elementName isEqualToString:@"m:BrandID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ItemID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:ItemName"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Unit"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:GroupID"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Closed"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Action"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Promo"]) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Discount"] && !_currentBadProduct) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        [_aItems setValue:_currentElementValue forKey:elementName];
    } else if ([elementName isEqualToString:@"m:Stores"]) {
        [_currentItemStoresArray addObject:_currentStore];
        _currentStore = nil;
    } else if ([elementName isEqualToString:@"m:StoreName"] && _currentStore) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        _currentStore[elementName] = _currentElementValue;
    } else if ([elementName isEqualToString:@"m:StoreID"] && _currentStore) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        _currentStore[elementName] = _currentElementValue;
    } else if ([elementName isEqualToString:@"m:QtyS"] && _currentStore) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        _currentStore[elementName] = _currentElementValue;
    } else if ([elementName isEqualToString:@"m:Exp"] && _currentStore) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        _currentStore[elementName] = _currentElementValue;
    } else if ([elementName isEqualToString:@"m:BadProduct"]) {
        [_currentItemBadProductArray addObject:_currentBadProduct];
        _currentBadProduct = nil;
    } else if ([elementName isEqualToString:@"m:StoreName"] && _currentBadProduct) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        _currentBadProduct[elementName] = _currentElementValue;
    } else if ([elementName isEqualToString:@"m:StoreID"] && _currentBadProduct) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        _currentBadProduct[elementName] = _currentElementValue;
    } else if ([elementName isEqualToString:@"m:QtyS"] && _currentBadProduct) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        _currentBadProduct[elementName] = _currentElementValue;
    } else if ([elementName isEqualToString:@"m:Discount"] && _currentBadProduct) {
        elementName = [elementName stringByReplacingOccurrencesOfString:@"m:" withString:@""];
        _currentBadProduct[elementName] = _currentElementValue;
    }
    
    _currentElementValue = nil;
}

- (void)createItems {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        for (int y = 0; y < _array.count; y++) {
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert into ItemTable (ItemId, ItemName, BrandId, Unit, Qty, GroupId, Closed, Action, Promo, Discount, StoresJSON, BadProductJSON, isBadProduct) Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            Items *items = [_array objectAtIndex:y];
            
            sqlite3_bind_text(addStmt, 1, [items.itemID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [items.itemName UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [items.brandID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [items.unit UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [items.qty UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [items.groupID UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [items.closed UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [items.action UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 9, [items.promo UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 10, [items.discount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 11, [items.storesJSON UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 12, [items.badProductJSON UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 13, [items.isBadProduct UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
                NSLog(@"Error while updating. '%s'", sqlite3_errmsg(database));
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        _array = nil;
    }
    
    sqlite3_close(database);
    
    NSMutableArray *uniqueStoresArray = [NSMutableArray new];
    NSMutableSet *uniqueStoreIDs = [NSMutableSet set];
    for (NSDictionary *store in _allStoresArray) {
        if (![uniqueStoreIDs containsObject:store[@"StoreID"]]) {
            [uniqueStoreIDs addObject:store[@"StoreID"]];
            [uniqueStoresArray addObject:store];
        }
    }
    
    [PersistenceWorker save:uniqueStoresArray key:@"storesArray"];
}

- (void)deleteItems {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        static sqlite3_stmt *compiledStatement;
        
        // now execute sql statement
        sqlite3_exec(database, [[NSString stringWithFormat:
                                 @"delete from ItemTable"] UTF8String], NULL, NULL, NULL);
        
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (_array.count > 0) {
        [self createItems];
    }
}

@end



