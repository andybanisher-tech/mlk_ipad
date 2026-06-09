//
//  PutListStatusDNRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 23.11.12.
//
//

#import <Foundation/Foundation.h>

@protocol PutDNDelegate
- (void)isSended;

@end

@interface PutListStatusDNRequest: NSObject {
    NSString        *custAccount;
    NSString        *origBrandId;
    
    BOOL notShowProgress;
}

@property(nonatomic,retain)NSString     *custAccount;
@property(nonatomic,retain)NSString     *origBrandId;

@property(nonatomic,assign)id<PutDNDelegate> delegate;
@property(nonatomic,readwrite)BOOL notShowProgress;

- (void)sendDN;
- (void)sendMsg:(NSString *)msg;

@end
