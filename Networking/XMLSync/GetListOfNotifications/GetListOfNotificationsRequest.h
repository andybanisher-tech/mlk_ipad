//
//  GetListOfNotificationsRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 20.12.12.
//
//

#import <Foundation/Foundation.h>

@interface GetListOfNotificationsRequest: NSObject
 
@property (nonatomic, assign) BOOL notShowProgress;

- (void)noticeReq;

@end
