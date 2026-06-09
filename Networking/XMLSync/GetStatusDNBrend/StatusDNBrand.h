//
//  StatusDNBrand.h
//  mlk
//
//  Created by Nikolya Smolnyakov on 14.10.16.
//
//

#import <Foundation/Foundation.h>

@interface StatusDNBrand: NSObject {
    
    NSString    *CustomerID;
    NSString    *Status;
    NSString    *BrandID;
}

@property(nonatomic,retain)NSString *CustomerID;
@property(nonatomic,retain)NSString *Status;
@property(nonatomic,retain)NSString *BrandID;
@end
