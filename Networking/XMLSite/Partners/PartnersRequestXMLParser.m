//
//  PartnersRequestXMLParser.m
//  MLK
//
//  Created by Alexandr Polienko on 12.12.2025.
//

#import "PartnersRequestXMLParser.h"

@interface PartnersRequestXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@property (nonatomic, strong) NSMutableArray *partners;
@property (nonatomic, strong) NSMutableDictionary *currentPartner;

@property (nonatomic, strong) NSDateFormatter *mainDateFormatter;

@end

@implementation PartnersRequestXMLParser

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:UrGetPartnerResponse"]) {
        self.partners = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"Value"]) {
        self.currentPartner = [NSMutableDictionary new];
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
    if ([elementName isEqualToString:@"Value"]) {
        [self.partners addObject:self.currentPartner];
    } else if (!self.currentPartner[@"name"] && [elementName isEqualToString:@"Name"]) {
        self.currentPartner[@"name"] = self.currentElementValue;
    } else if ([elementName isEqualToString:@"m:Error"] && self.currentElementValue.length > 0 && self.partners.count < 1) {
        NSString *errorString = self.currentElementValue.copy;
        [AlertWorkerObjc alertWithTitle:@"Ошибка" message:errorString];
    }

    self.currentElementValue = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [NSNotificationCenter.defaultCenter postNotificationName:@"partnersReceived" object:self.partners];
}

@end
