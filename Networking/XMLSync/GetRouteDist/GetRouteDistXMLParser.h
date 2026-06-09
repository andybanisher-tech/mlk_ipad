//
//  GetRouteDistXMLParser.h
//  MLK
//
//  Created by Nikita on 19/02/15.
//
//

#import <Foundation/Foundation.h>

@interface GetRouteDistXMLParser: NSObject

@property (nonatomic, assign) BOOL isSchedulerRequest;

- (void)parse:(NSData *)webData;

@end
