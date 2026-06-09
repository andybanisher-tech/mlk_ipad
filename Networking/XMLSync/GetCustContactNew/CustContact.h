//
//  CustContact.h
//  MLK
//
//  Created by Nikita on 21/01/15.
//
//

#import <Foundation/Foundation.h>

@interface CustContact: NSObject {
    
    NSString	*sname;
    NSString	*name;
    NSString	*mname;
    NSString	*birthday;
    NSString	*position;
    NSString	*phone;
    NSString	*email;
    NSString	*forDelete;
    NSString	*source;
    NSString	*custAccount;
    NSString	*contactId;
}

@property(nonatomic,retain)NSString	*sname;
@property(nonatomic,retain)NSString	*name;
@property(nonatomic,retain)NSString	*mname;
@property(nonatomic,retain)NSString	*birthday;
@property(nonatomic,retain)NSString	*position;
@property(nonatomic,retain)NSString	*phone;
@property(nonatomic,retain)NSString	*email;
@property(nonatomic,retain)NSString	*forDelete;
@property(nonatomic,retain)NSString	*source;
@property(nonatomic,retain)NSString	*custAccount;
@property(nonatomic,retain)NSString	*contactId;


@end
