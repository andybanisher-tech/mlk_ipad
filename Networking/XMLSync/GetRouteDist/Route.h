//
//  Route.h
//  MLK
//
//  Created by Nikita on 19/02/15.
//
//

#import <Foundation/Foundation.h>

@interface Route: NSObject {
    
    NSString *custAccount;
    NSString *dateOfRoute;
    NSString *lineNum;
    NSString *status;
    NSString *timeOfRoute;
    NSString *nearCust;
    NSString *gpsPoint;
    NSString *custAddress;
}
  
@property (nonatomic, retain) NSString *custAccount;
@property (nonatomic, retain) NSString *dateOfRoute;
@property (nonatomic, retain) NSString *lineNum;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *timeOfRoute;
@property (nonatomic, retain) NSString *nearCust;
@property (nonatomic, retain) NSString *gpsPoint;
@property (nonatomic, retain) NSString *custAddress;
  
@end
