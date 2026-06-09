//
//  ActionTypeViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 11.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol TypeFilterDelegate
- (void)typeIsSelected:(NSString *)type;
@end

@interface ActionTypeViewController : UITableViewController <UITableViewDelegate,UITableViewDataSource> {    
	NSMutableArray       *typeList;
	NSMutableArray       *typeToLiveInArray;
    
    NSString    *custAccount;
}

@property(nonatomic,retain)NSMutableArray  *typeList;
@property(nonatomic,retain)NSString *custAccount;

@property(nonatomic,assign) id<TypeFilterDelegate> delegate;

+(void)finalizeStatements;

@end
