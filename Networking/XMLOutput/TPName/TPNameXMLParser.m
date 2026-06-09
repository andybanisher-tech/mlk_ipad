//
//  TPNameXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 02.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TPNameXMLParser.h"

@interface TPNameXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation TPNameXMLParser {
    
    NSMutableArray *_iPadsArray;
    NSMutableDictionary *_currentIPad;
}

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:IPads"]) {
        _iPadsArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        _currentIPad = [NSMutableDictionary new];
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
    if ([elementName isEqualToString:@"m:FIO"]) {
        [PersistenceWorker save:self.currentElementValue key:@"emple"];
    } else if ([elementName isEqualToString:@"m:Delta"]) {
        [PersistenceWorker save:self.currentElementValue key:@"GPSDiff"];
    } else if ([elementName isEqualToString:@"m:Zakaz"]) {
        [PersistenceWorker save:self.currentElementValue key:@"zakaz"];
    } else if ([elementName isEqualToString:@"m:Consult"]) {
        [PersistenceWorker save:self.currentElementValue key:@"consult"];
    } else if ([elementName isEqualToString:@"m:MoreCust"]) {
        [PersistenceWorker save:self.currentElementValue key:@"moreCust"];
    } else if ([elementName isEqualToString:@"m:Value"] && [_currentIPad[@"id"] length] > 0) {
        [_iPadsArray addObject:_currentIPad];
    } else if ([elementName isEqualToString:@"m:Name"]) {
        _currentIPad[@"name"] = self.currentElementValue;
    } else if ([elementName isEqualToString:@"m:Status4"]) {
        _currentIPad[@"status4"] = self.currentElementValue;
    } else if ([elementName isEqualToString:@"m:ID"]) {
        _currentIPad[@"id"] = self.currentElementValue;
    } else if ([elementName isEqualToString:@"m:Error"] && self.currentElementValue.length > 0) {
        [PersistenceWorker remove:@"login"];
        
        NSString *errorString = self.currentElementValue.copy;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertWorkerObjc alertWithTitle:@"Ошибка" message:errorString];
        });
    }

    self.currentElementValue = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [_iPadsArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1[@"name"] compare: obj2[@"name"]];
    }];
    [PersistenceWorker save:_iPadsArray key:@"iPadsArray"];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"UserAuthStateChanged" object:nil];
}

@end
