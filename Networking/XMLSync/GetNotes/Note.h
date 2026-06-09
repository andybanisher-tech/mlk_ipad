//
//  Note.h
//  MLK
//
//  Created by Nikita on 22/01/15.
//
//

#import <Foundation/Foundation.h>

@interface Note: NSObject {
    
    NSString	*custAccount;
    NSString	*commentId;
    NSString	*description;
    NSString	*userId;
    NSString	*date;
    NSString	*commentType;
    NSString    *forDelete;
    NSString    *time;
}

@property(nonatomic,retain)NSString	*custAccount;
@property(nonatomic,retain)NSString	*commentId;
@property(nonatomic,retain)NSString	*description;
@property(nonatomic,retain)NSString	*userId;
@property(nonatomic,retain)NSString	*date;
@property(nonatomic,retain)NSString	*commentType;
@property(nonatomic,retain)NSString	*forDelete;
@property(nonatomic,retain)NSString	*time;

@end
