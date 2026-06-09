//
//  PutClientForRouteRequest.h
//  MLK
//
//  Created by Nikita on 08/04/15.
//
//

#import <Foundation/Foundation.h>

@protocol PutClientForRouteRequestDelegate <NSObject>
- (void)isSendedForDelete:(NSString *)custAccount;
@optional
- (void)isSended:(NSString *)custAccount custName:(NSString *)custName custAddr:(NSString *)custAddress strDate:(NSString *)strDate;

@end

@interface PutClientForRouteRequest: NSObject {
    NSString        *custAccount;
    BOOL            forDelete;
    NSString        *date;
    NSString        *custAddress;
    NSString        *custName;
    
    BOOL notShowProgress;
    BOOL notShowErrorMessage;
}
 
@property (nonatomic, retain) NSString *managerID;
@property (nonatomic, retain) NSString *custAccount;
@property (nonatomic, retain) NSString *date;
@property (nonatomic, retain) NSString *custAddress;
@property (nonatomic, retain) NSString *custName;
@property (nonatomic, assign) BOOL forDelete;

@property (nonatomic, weak) id<PutClientForRouteRequestDelegate> delegate;
  
@property (nonatomic, assign) BOOL notShowProgress;
@property (nonatomic, assign) BOOL notShowErrorMessage;

- (void)sendCust;
- (void)sendMsg:(NSString *)msg;

@end
