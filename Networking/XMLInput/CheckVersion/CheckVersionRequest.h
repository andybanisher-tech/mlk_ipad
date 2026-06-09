//
//  CheckVersionRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 07.06.13.
//
//

#import <Foundation/Foundation.h>

@interface CheckVersionRequest: NSObject

@property (nonatomic, assign) BOOL notShowProgress;

- (void)verReq;

@end
