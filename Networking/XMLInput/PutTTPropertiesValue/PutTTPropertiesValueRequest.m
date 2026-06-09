//
//  PutTTPropertiesValueRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "PutTTPropertiesValueRequest.h"
#import "PutTTPropertiesValueXMLParser.h"
#import "XMLWriter.h"
#import "Base64Class.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutTTPropertiesValueRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation PutTTPropertiesValueRequest

@synthesize custAccount;

- (void)sendTTPropertiesValue {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CreatedDateTime, PropertyId, Value, Image, ttId, ElementListId from TTPropertiesValue where Date = ? and CustAccount = ? and (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSData   *imgData       = nil;
                NSString *date          = @"null";
                NSString *propertyId    = @"null";
                NSString *value         = @"null";
                NSString *image         = @"null";
                NSString *ttid          = @"null";
                NSString *imageSize     = @"null";
                NSString *elementListId = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    date = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    propertyId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_blob(selectstmt, 3))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 3) length:sqlite3_column_bytes(selectstmt, 3)];
                    
                    imageSize = [NSString stringWithFormat:@"%lu", (unsigned long)[imgData length]];
                    
                    image = [Base64Class encode:imgData];
                }
                
                if (sqlite3_column_text(selectstmt, 4))
                    ttid  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    elementListId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:Period"];
                [xmlWriter writeCharacters:date];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:TTID"];
                [xmlWriter writeCharacters:ttid];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyID"];
                [xmlWriter writeCharacters:propertyId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValue"];
                [xmlWriter writeCharacters:value];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValueID"];
                [xmlWriter writeCharacters:elementListId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Image"];
                [xmlWriter writeCharacters:image];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Size"];
                [xmlWriter writeCharacters:imageSize];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    // get the resulting XML string
    
    [self sendMsg:[xmlWriter toString]];
    
}

- (void)sendMsg:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutTTPropertiesValue>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutTTPropertiesValue>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, msg];
    
    NSProgress *progress = [APIWorker.sharedInstance sendInputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    if (!self.withoutProgress) {
        self.progress = progress;
        [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
        
        [SVProgressHUD showProgress:0.0 status:@"Отправка данных\nСвойства точки"];
    }
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    [SVProgressHUD dismiss];
    
    /*NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     ////NSLog(theXML);*/
    
    PutTTPropertiesValueXMLParser *parser = [PutTTPropertiesValueXMLParser new];
    parser.custAccount = custAccount;
    [parser parse:data];
}

- (void)handleError:(NSError *)error {
    [SVProgressHUD dismiss];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Отправка данных\nСвойства точки"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
