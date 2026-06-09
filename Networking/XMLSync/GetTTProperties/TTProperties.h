//
//  TTProperties.h
//  MLK
//
//  Created by Rustem Galyamov on 14.06.12.
//
//

#import <Foundation/Foundation.h>

@interface TTProperties: NSObject {
    
    NSString    *Period;
    NSString    *TTID;
    NSString    *PropertyID;
    NSString    *PropertyName;
    NSString    *PropertyType;
    NSString    *Multiple;
    NSString    *Required;
}
   
@property (nonatomic, retain) NSString *Period;
@property (nonatomic, retain) NSString *TTID;
@property (nonatomic, retain) NSString *PropertyID;
@property (nonatomic, retain) NSString *PropertyName;
@property (nonatomic, retain) NSString *PropertyType;
@property (nonatomic, retain) NSString *Multiple;
@property (nonatomic, retain) NSString *Required;
 
@end
