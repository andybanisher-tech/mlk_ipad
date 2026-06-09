//
//  PutClientsForPDZRequest.m
//  MLK
//
//  Created by Nikita on 08/04/15.
//
//

#import "PutClientsForPDZRequest.h"
#import "XMLWriter.h"

#import "sqlite3.h"

static sqlite3 *database = nil;

@interface PutClientsForPDZRequest ()

@property (nonatomic, strong) NSProgress *progress;

@end

@implementation PutClientsForPDZRequest

@synthesize notShowProgress;

- (void)sendPDZ:(NSString *)customerAccount {
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    NSMutableArray *customerAccsArray = [NSMutableArray new];
    
    if (customerAccount) {
        [customerAccsArray addObject:customerAccount];
    } else {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;
        
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        NSString *strDate = [dateFormatter stringFromDate:date];
        
        if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
            sqlite3_stmt *selectstmt;
            
            const char *sql = "select CustAccount from CustForRoute where DateOfRoute = ?";
            
            if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                
                while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                    NSString *custAcc = @"null";
                    
                    if (sqlite3_column_text(selectstmt, 0))
                        custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                    
                    [customerAccsArray addObject:custAcc];
                }
            }
            sqlite3_finalize(selectstmt);
            sqlite3_close(database);
        } else {
            sqlite3_close(database);
        }
    }
    
    for (NSString *custAcc in customerAccsArray) {
        [xmlWriter writeStartElement:@"sam:Value"];
        
        [xmlWriter writeStartElement:@"sam:CustAccount"];
        [xmlWriter writeCharacters:custAcc];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeEndElement];
    }

    [self sendMsg:[xmlWriter toString]];
}

- (void)sendMsg:(NSString *)msg {
    NSString *udid = LocalAuthWorker.login;
    
    NSString *soapMessage = [NSString stringWithFormat:@"<soap:Envelope xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:sam='http://www.sample-package.org' xmlns:sam1='http://www.sample-package1.org'>\n"
                             "<soap:Header/>\n"
                             "<soap:Body>\n"
                             "<sam:PutClientsForPDZ>\n"
                             "<sam:ID>%@</sam:ID>\n"
                             "<sam:Value>"
                             "%@\n"
                             "</sam:Value>\n"
                             "</sam:PutClientsForPDZ>\n"
                             "</soap:Body>\n"
                             "</soap:Envelope>\n", udid, msg];
    
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
}

- (void)handleError:(NSError *)error {
    if (!notShowProgress) {
        [SVProgressHUD dismiss];
    }
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
