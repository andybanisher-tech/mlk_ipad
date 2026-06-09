//
//  Dream.h
//  MLK
//
//  Created by Rustem Galyamov on 05.12.13.
//
//

#import <Foundation/Foundation.h>

@interface Dream: NSObject {
    NSString    *CustomerID;
    NSString    *Status;
}

@property(nonatomic,retain)NSString *CustomerID;
@property(nonatomic,retain)NSString *Status;

@end
