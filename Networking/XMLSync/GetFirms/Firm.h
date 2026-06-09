//
//  Firm.h
//  MLK
//
//  Created by Rustem Galyamov on 21.01.13.
//
//

#import <Foundation/Foundation.h>

@interface Firm: NSObject {
    
    NSString    *ID;
    NSString    *Name;
    NSString    *Default;
    NSString    *Markup;
}

@property(nonatomic,retain)NSString    *ID;
@property(nonatomic,retain)NSString    *Name;
@property(nonatomic,retain)NSString    *Default;
@property(nonatomic,retain)NSString    *Markup;

@end
