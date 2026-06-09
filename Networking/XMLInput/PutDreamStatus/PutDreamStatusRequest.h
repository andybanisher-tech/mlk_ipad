//
//  PutDreamStatusRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 06.12.13.
//
//

#import <Foundation/Foundation.h>

@interface PutDreamStatusRequest: NSObject {
	
    NSString        *custAccount;
    
    BOOL notShowErrorMessage;
}

@property(nonatomic,retain,readwrite)NSString     *custAccount;
@property(nonatomic,readwrite)BOOL notShowErrorMessage;

- (void)sendDream:(NSString *)msg;

@end
