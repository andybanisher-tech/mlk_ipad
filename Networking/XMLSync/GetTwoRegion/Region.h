//
//  Region.h
//  MLK
//
//  Created by garu on 11/7/14.
//
//

#import <Foundation/Foundation.h>

@interface Region: NSObject {
    
    NSString    *PropertyID;
    NSString    *PropertyValueID;
    NSString    *PropertyValueName;
}

@property(nonatomic,retain)NSString *PropertyID;
@property(nonatomic,retain)NSString *PropertyValueID;
@property(nonatomic,retain)NSString *PropertyValueName;
@end
