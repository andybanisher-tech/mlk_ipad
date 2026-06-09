//
//  PutPhotosRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "PutPhotosRequest.h"
#import "PutPhotosXMLParser.h"
#import "XMLWriter.h"
#import "Base64Class.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutPhotosRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation PutPhotosRequest

@synthesize custAccount;
@synthesize notShowProgress;

- (void)sendGroupPhotos {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select Date, GroupId, Image from GroupImage where Date = ? and CustAccount = ? and (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSData   *imgData       = nil;
                NSString *date          = @"null";
                NSString *groupId       = @"null";
                NSString *image         = @"null";
                NSString *imageSize     = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    groupId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_blob(selectstmt, 2))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 2) length:sqlite3_column_bytes(selectstmt, 2)];
                    
                    imageSize = [NSString stringWithFormat:@"%lu", (unsigned long)[imgData length]];
                     
                    image = [Base64Class encode:imgData];
                }
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GroupID"];
                [xmlWriter writeCharacters:groupId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Period"];
                [xmlWriter writeCharacters:date];
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
    }
    sqlite3_close(database);
    
    // get the resulting XML string
    [self sendMsg:[xmlWriter toString]];
}

- (void)sendMsg:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutPhotos>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutPhotos>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, msg];
    
    //NSLog(soapMessage);
    
    NSProgress *progress = [APIWorker.sharedInstance sendInputRequest:soapMessage completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            [self handleSuccess:data];
        } else {
            [self handleError:error];
        }
    }].progress;
    
    if (!notShowProgress) {
        self.progress = progress;
        [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
        
        [SVProgressHUD showProgress:0.0 status:@"Отправка данных\nФото по группе"];
    }
}

#pragma mark - Request Helpers
- (void)handleSuccess:(NSData *)data {
    if (!notShowProgress) {
        [SVProgressHUD dismiss];
    }

    /*NSString *theXML = [[NSString alloc]
     initWithBytes: [webData mutableBytes]
     length:[webData length]
     encoding:NSUTF8StringEncoding];
     //---shows the XML---
     ////NSLog(theXML);*/
    
    PutPhotosXMLParser *parser = [PutPhotosXMLParser new];
    parser.custAccount = custAccount;
    [parser parse:data];

    if (!notShowProgress) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertWorkerObjc alertWithTitle:@"Данные отправлены"];
        });
    }
}

- (void)handleError:(NSError *)error {
    [SVProgressHUD dismiss];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Отправка данных\nФото по группе"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
