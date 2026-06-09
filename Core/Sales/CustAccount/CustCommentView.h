//
//  CustCommentView.h
//  MLK
//
//  Created by Rustem Galyamov on 04.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol CustCommentDelegate
- (void)setComment:(NSString *)comment;
@end

@interface CustCommentView : UITableViewController <UITableViewDelegate,UITableViewDataSource> {
    NSString             *custAccount;
    
    NSMutableArray		 *dateList;
    NSMutableArray		 *dateToLiveInArray;
    
    NSMutableArray		 *userList;
	NSMutableArray       *userToLiveInArray;
    
    NSMutableArray		 *commentList;
	NSMutableArray       *commentToLiveInArray;
    
    NSMutableArray		 *statusList;
	NSMutableArray       *statusToLiveInArray;
    
    NSMutableArray		 *commentIdList;
	NSMutableArray       *commentIdToLiveInArray;
    
    NSMutableArray		 *timeToLiveInArray;
    
    NSString             *commentType;
    NSString             *dateSelected;

    NSIndexPath          *selectedIndex;
}

@property(nonatomic,assign) id<CustCommentDelegate> delegate;
@property (nonatomic, retain) NSString *custAccount;
@property(nonatomic,retain)NSMutableArray *dateList;
@property(nonatomic,retain)NSMutableArray *userList;
@property(nonatomic,retain)NSMutableArray *commentList;
@property(nonatomic,retain)NSMutableArray *statusList;
@property(nonatomic,retain)NSString *commentType;
@property(nonatomic,retain)NSString *dateSelected;
@property(nonatomic,retain)NSMutableArray *commentIdList;
@property(nonatomic,retain)NSMutableArray *timeList;

- (void)createCommentList;
- (void)refreshData;

@end
