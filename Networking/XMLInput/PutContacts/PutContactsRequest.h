//
//  PutContactsRequest.h
//  MLK
//
//  Created by Nikita on 22/01/15.
//
//

#import <Foundation/Foundation.h>

@interface PutContactsRequest: NSObject

@property (nonatomic, copy) NSString *custAccount;
@property (nonatomic, copy) NSString *contactId;
 
@property (nonatomic, assign) BOOL notShowProgress;
@property (nonatomic, assign) BOOL notShowErrorMessage;
 
- (void)sendMsg:(NSString *)msg;
- (void)sendContact;

@end
