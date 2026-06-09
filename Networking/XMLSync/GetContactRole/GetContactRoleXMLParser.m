//
//  GetContactRoleXMLParser.m
//  MLK
//
//  Created by Alexandr Polienko on 29.11.2021.
//

#import "GetContactRoleXMLParser.h"

@interface GetContactRoleXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *contactRolesArray;
@property (nonatomic, strong) NSMutableDictionary *currentContactRole;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation GetContactRoleXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetContactRoleResponse"]) {
        self.contactRolesArray = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.currentContactRole = [NSMutableDictionary new];
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
        [self.contactRolesArray addObject:self.currentContactRole];
    } else if ([elementName isEqualToString:@"m:RoleCode"]) {
        self.currentContactRole[@"code"] = self.currentElementValue;
    } else if ([elementName isEqualToString:@"m:RoleName"]) {
        self.currentContactRole[@"name"] = self.currentElementValue;
    }

    self.currentElementValue = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self.contactRolesArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1[@"name"] compare: obj2[@"name"]];
    }];
    [PersistenceWorker save:_contactRolesArray key:@"contactRolesArray"];
}

@end
