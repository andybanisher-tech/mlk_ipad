//
//  Matrix.h
//  mlk
//
//  Created by METASHARKS on 14/01/2017.
//
//

#import <Foundation/Foundation.h>

@interface Matrix: NSObject {
    NSString *MatrixID;
    NSString *MatrixName;
    NSString *ItemID;
}

@property(nonatomic,retain)NSString *MatrixID;
@property(nonatomic,retain)NSString *MatrixName;
@property(nonatomic,retain)NSString *ItemID;

@end

