//
//  ActionFileXMLParser.m
//  MLK
//
//  Created by Rustem Galyamov on 08.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "ActionFileXMLParser.h"
#import "Base64Class.h"

@interface ActionFileXMLParser () <NSXMLParserDelegate>

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *errorText;

@property (nonatomic, strong) NSMutableString *currentElementValue;

@end

@implementation ActionFileXMLParser

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
        self.fileName = self.currentElementValue;
    } else if ([elementName isEqualToString:@"m:File"]) {
        [self addFile:self.currentElementValue];
    } else if ([elementName isEqualToString:@"m:Error"]) {
        self.errorText = self.currentElementValue.copy;
    }

    self.currentElementValue = nil;
}

- (void)addFile:(NSString*)fileString {
    NSData * data = [Base64Class decode:fileString];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *pdfPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf", self.fileName]];
	
    [data writeToFile:pdfPath atomically:NO];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
}

@end
