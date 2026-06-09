//
//  PutCommentsXMLParser.h
//  MLK
//
//  Created by Rustem Galyamov on 31.10.12.
//
//

#import <Foundation/Foundation.h>

@interface PutCommentsXMLParser: NSObject

@property (nonatomic, copy) NSString *custAccount;
@property (nonatomic, copy) NSString *commentId;

- (void)parse:(NSData *)webData;

@end
