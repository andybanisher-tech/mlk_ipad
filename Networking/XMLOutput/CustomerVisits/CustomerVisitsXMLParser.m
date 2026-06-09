//
//  CustomerVisitsXMLParser.m
//  MLK
//
//  Created by Alexandr Polienko on 04.09.2023.
//

#import "CustomerVisitsXMLParser.h"

@interface CustomerVisitsXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *currentElementValue;

@property (nonatomic, strong) NSMutableArray *visits;
@property (nonatomic, strong) NSMutableDictionary *currentVisit;

@property (nonatomic, strong) NSDateFormatter *mainDateFormatter;

@end

@implementation CustomerVisitsXMLParser

- (instancetype)init {
    self = [super init];
    if (self) {
        //DateFormatter
        self.mainDateFormatter = NSDateFormatter.new;
        self.mainDateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    }
    
    return self;
}

- (void)parse:(NSData *)webData {
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:webData];
    xmlParser.delegate = self;
    [xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"m:GetVisitsResponse"]) {
        self.visits = [NSMutableArray new];
    } else if ([elementName isEqualToString:@"m:Value"]) {
        self.currentVisit = [NSMutableDictionary new];
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
        [self.visits addObject:self.currentVisit];
    } else if ([elementName isEqualToString:@"m:DateOfVisit"]) {
        NSString *dateOfVisitString = self.currentElementValue;
        self.currentVisit[@"dateOfVisitString"] = dateOfVisitString;
        self.currentVisit[@"dateOfVisit"] = [self.mainDateFormatter dateFromString:dateOfVisitString];
    } else if ([elementName isEqualToString:@"m:FIO"]) {
        self.currentVisit[@"fio"] = self.currentElementValue;
    } else if ([elementName isEqualToString:@"m:Error"] && self.currentElementValue.length > 0) {
        NSString *errorString = self.currentElementValue.copy;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertWorkerObjc alertWithTitle:@"Ошибка" message:errorString];
        });
    }

    self.currentElementValue = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [NSNotificationCenter.defaultCenter postNotificationName:@"DidReceiveCustomerVisits" object:self.visits];
}

@end
