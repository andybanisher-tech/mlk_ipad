//
//  CheckVersionXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 07.06.13.
//
//

#import "CheckVersionXMLParser.h"

@interface CheckVersionXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@property (nonatomic, copy) NSString *verNumber;

@end

@implementation CheckVersionXMLParser

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
    if ([elementName isEqualToString:@"soap:Header/"]) {
        self.verNumber = @"Ошибка";
    } else if ([elementName isEqualToString:@"m:return"]) {
        self.verNumber = self.currentElementValue.copy;
    }

    self.currentElementValue = nil;
}

- (void)checkVersion {
    NSString *curVersion = [[NSBundle.mainBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
                            
    if (![self.verNumber isEqualToString:@"Ошибка"]) {
        if (![curVersion isEqualToString:self.verNumber] && [self isValidNumberVersion:self.verNumber]) {
            [AlertWorkerObjc alertWithTitle:@"Информация" message:@"Версия приложения отличается от версии на сервере. Необходимо обновить приложение!"];
        }
    }
}

- (BOOL)isValidNumberVersion:(NSString *)verNumber {
    if (!verNumber) {
        return NO;
    }

    NSString *validSimbol = @"0123456789";
    
    for (int i = 1; i <= 5; i++) {
        NSRange range = {i-1,1};
        NSString *symbol = [verNumber substringWithRange:range];
        NSRange YESSymbol = [validSimbol rangeOfString:symbol];
        
        if (i==1 | i==3 | i==5) {
            if (YESSymbol.location == NSNotFound) {
                return NO;
            }
        } else {
            if (![symbol isEqualToString:@"."]) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self checkVersion];
}

@end
