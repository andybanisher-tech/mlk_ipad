//
//  Notice.h
//  MLK
//
//  Created by Rustem Galyamov on 20.12.12.
//
//

#import <Foundation/Foundation.h>

@interface Notice: NSObject {
    
    NSString    *ID;
    NSString    *Name;
    NSString    *Description;
    NSString    *Alert;
    NSString    *NoticeDate;
}

@property(nonatomic,retain)NSString    *ID;
@property(nonatomic,retain)NSString    *Name;
@property(nonatomic,retain)NSString    *Description;
@property(nonatomic,retain)NSString    *Alert;
@property(nonatomic,retain)NSString    *NoticeDate;

@end
