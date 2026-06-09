//
//  ActionMarkViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 11.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol ActionMarkDelegate
- (void)markIsSelected:(NSString *)brand;
@end

@interface ActionMarkViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
    NSMutableArray		 *brandList;
    NSMutableArray		 *copyBrandList;
    NSMutableArray		 *brandsToLiveInArray;
    
    NSMutableArray		 *brandIdList;
    NSMutableArray		 *copyBrandIdList;
    NSMutableArray		 *brandsIdToLiveInArray;
    
    NSString    *custAccount;
}

@property(nonatomic,assign)id<ActionMarkDelegate> delegate;
@property(nonatomic,retain)NSMutableArray *brandList;
@property(nonatomic,retain)NSMutableArray *brandIdList;
@property(nonatomic,retain)NSString *custAccount;

- (void)markIsSelected:(NSString *)brand;

@end
