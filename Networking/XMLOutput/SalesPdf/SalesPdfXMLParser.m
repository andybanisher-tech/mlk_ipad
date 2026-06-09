//
//  SalesPdfXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 09.26.2014.
//
//

#import "SalesPdfXMLParser.h"
#import "Base64Class.h"

@interface SalesPdfXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSData *pdfData;

@property (nonatomic, copy) NSString *response;
@property (nonatomic, copy) NSString *errorText;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@property (nonatomic, copy) void (^completion)(NSData *pdfData, NSString *_Nullable errorString);

@end

@implementation SalesPdfXMLParser

- (void)parse:(NSData *)webData completion:(void (^)(NSData *pdfData, NSString *_Nullable errorString))completion {
    self.completion = completion;
    
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
    if ([elementName isEqualToString:@"m:File"]) {
        self.pdfData = [Base64Class decode:self.currentElementValue];
    } else if ([elementName isEqualToString:@"m:Error"]) {
        self.errorText = self.currentElementValue.copy;
    }
    
    self.currentElementValue = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (![self.errorText isEqualToString:@"не ошибка"]) {
        self.completion(nil, self.errorText);
    } else {
        self.completion(self.pdfData, nil);
    }
}

@end

