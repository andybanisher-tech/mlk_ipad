//
//  PutVisitDateRequest.h
//  MLK
//
//  Created by Rustem Galyamov on 06.12.13.
//
//

#import <Foundation/Foundation.h>

@interface PutVisitDateRequest: NSObject {
	
    BOOL notShowErrorMessage;
}

@property(nonatomic,retain)NSString     *curCustAcc;
@property(nonatomic,retain)NSString     *curStrDate;
@property(nonatomic,readwrite)BOOL notShowErrorMessage;

- (void)sendLVD:(NSString *)msg;

@end
