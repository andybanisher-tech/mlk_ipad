//
//  PDZFileXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 09.26.2014.
//
//

#import "PDZFileXMLParser.h"
#import "Base64Class.h"

@interface PDZFileXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSData *pdfData;

@property (nonatomic, copy) NSString *response;
@property (nonatomic, copy) NSString *errorText;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation PDZFileXMLParser

- (void)parse:(NSData *)webData {
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
    if ([elementName isEqualToString:@"m:ActionID"]) {
        self.response = self.currentElementValue;
    } else if ([elementName isEqualToString:@"m:File"]) {
        self.pdfData = [Base64Class decode:self.currentElementValue];
    } else if ([elementName isEqualToString:@"m:Error"]) {
        self.errorText = self.currentElementValue.copy;
    }
    
    self.currentElementValue = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![self.errorText isEqualToString:@"не ошибка"]) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"pdzFileRequestFailed" object:self.errorText];
        } else {
            [NSNotificationCenter.defaultCenter postNotificationName:@"pdzFileReceived" object:self.pdfData];
        }
    });
}

@end

