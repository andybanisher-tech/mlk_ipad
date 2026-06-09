//
//  PutDreamStatusXMLParser.m
//  MLK
//
//  Created by Nikita on 29/07/15.
//
//

#import "PutDreamStatusXMLParser.h"

@interface PutDreamStatusXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@property (nonatomic, copy) NSString *response;

@end

@implementation PutDreamStatusXMLParser

- (BOOL)getResponseResult:(NSData *)webData {
    BOOL result = NO;
    
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    result = [xmlParser parse];
    
    return result;
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

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    BOOL result = NO;
    
    if ([self.response localizedStandardContainsString:@"получено"]) {
        self.response = @"Sended";
        result = YES;
    } else {
        self.response = @"new";
    }
    
    [self returnResult:result];
}

- (BOOL)returnResult:(BOOL)result {
    return result;
}

@end
