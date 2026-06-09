//
//  PutListStatusDNRequest.m
//  MLK
//
//  Created by Rustem Galyamov on 23.11.12.
//
//

#import "PutListStatusDNRequest.h"
#import "XMLWriter.h"
#import "Base64Class.h"
#import "PutListStatusDNXMLParser.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutListStatusDNRequest ()
@property (nonatomic, strong) NSProgress *progress;

@end

@implementation PutListStatusDNRequest

@synthesize custAccount;
@synthesize delegate;
@synthesize origBrandId;
@synthesize notShowProgress;

- (void)sendDN {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, Name, BrandId, BrandName, Date, MngrStatus, Comment, SendStatus from DNTable where CustAccount = ? and (SendStatus = 'Error' or SendStatus = 'Modified')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            //NSLog(custAccount);
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc       = @"null";
                NSString *name          = @"null";
                NSString *brandId       = @"null";
                NSString *brandName     = @"null";
                NSString *month         = @"null";
                NSString *managerStatus = @"null";
                NSString *comment       = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    name      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    brandId          = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    brandName      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    month  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    managerStatus        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    comment     = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustAccount"];
                [xmlWriter writeCharacters:custAcc];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Name"];
                [xmlWriter writeCharacters:name];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:BrandID"];
                [xmlWriter writeCharacters:brandId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:BrandName"];
                [xmlWriter writeCharacters:brandName];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Date"];
                [xmlWriter writeCharacters:month];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Status"];
                [xmlWriter writeCharacters:managerStatus];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Comment"];
                [xmlWriter writeCharacters:comment];
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
                             "<sam:PutListStatusDN>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:ListOfDN>"
                             "%@\n"
                             "</sam:ListOfDN>\n"
                             "</sam:PutListStatusDN>\n"
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
        
        [SVProgressHUD showProgress:0.0 status:@"Отправка данных\nDN"];
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
    
    PutListStatusDNXMLParser *parser = [PutListStatusDNXMLParser new];
    parser.custAccount = custAccount;
    [parser parse:data];

    [self.delegate isSended];
}

- (void)handleError:(NSError *)error {
    [SVProgressHUD dismiss];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && [object isKindOfClass:NSProgress.class]) {
        NSProgress *progress = (NSProgress *)object;
        [SVProgressHUD showProgress:progress.fractionCompleted status:@"Отправка данных\nDN"];
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

@end
