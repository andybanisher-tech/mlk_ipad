//
//  PutTasksRequest.h
//  MLK
//
//  Created by garu on 11/27/14.
//
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@protocol SendTaskDelegate
- (void)refresh;

@end

@interface PutTasksRequest: NSObject {

    NSString        *custAccount;
    NSString        *taskId;
    
    BOOL notShowProgress;
    
    NSString *status;
    NSString *result;
    NSString *transDate;
    
    sqlite3_int64 lastTransRowId;
    
    BOOL notShowErrorMessage;
}

@property(nonatomic, retain)NSString *custAccount;
@property(nonatomic, retain)NSString *taskId;

@property(nonatomic, weak) id <SendTaskDelegate> delegate;
@property(nonatomic, readwrite) BOOL notShowProgress;
@property(nonatomic, retain) NSString *status;
@property(nonatomic, retain) NSString *result;
@property(nonatomic, retain) NSString *transDate;
@property(nonatomic, readwrite) sqlite3_int64 lastTransRowId;
@property(nonatomic, readwrite) BOOL notShowErrorMessage;
 
- (void)sendTask;
- (void)sendMsg:(NSString *)msg;

@end
