//
//  NewCustomer.h
//  MLK
//
//  Created by Rustem Galyamov on 08.05.2014.
//
//

#import <Foundation/Foundation.h>

@interface NewCustomer: NSObject {
    NSString    *Date;
    NSString    *Name;
    NSString    *FactAddress;
    NSString    *Phone;
    NSString    *Email;
    NSString    *Contact;
    NSString    *Location;
    NSString    *Uid;
}

@property(nonatomic,retain)NSString *Date;
@property(nonatomic,retain)NSString *Name;
@property(nonatomic,retain)NSString *FactAddress;
@property(nonatomic,retain)NSString *Phone;
@property(nonatomic,retain)NSString *Email;
@property(nonatomic,retain)NSString *Contact;
@property(nonatomic,retain)NSString *Location;
@property(nonatomic,retain)NSString *Uid;

@end
