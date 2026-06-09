//
//  PutClientsForPDZRequest.h
//  MLK
//
//  Created by Nikita on 08/04/15.
//
//

#import <Foundation/Foundation.h>

@interface PutClientsForPDZRequest: NSObject {
    BOOL notShowProgress;
}

@property(nonatomic,readwrite)BOOL notShowProgress;

- (void)sendPDZ:(NSString *)customerAccount;

@end
