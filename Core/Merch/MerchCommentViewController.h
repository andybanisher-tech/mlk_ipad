//
//  MerchCommentViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "CustCommentView.h"
#import "AddCustComment.h"
#import "MecrhCommentDateFilter.h"

@class CustCommentView;
@class AddCustComment;

@interface MerchCommentViewController : UIViewController <CustCommentDelegate, AddCustCommentDelegate, MecrhCommentDateFilterDelegate> {
    BOOL isViewPushed;
    
    UIButton    *dateFilter;
    UIButton    *createCommentBtn;
    
    IBOutlet UITextView  *textComments;
    IBOutlet UITableView *custComments;
    
    UINavigationController *infoNavController;
    
    NSString    *custAccount;
    
    MecrhCommentDateFilter   *mecrhCommentDateFilter;
}

@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,retain)IBOutlet UIButton *dateFilter;
@property(nonatomic,retain)IBOutlet UIButton *createCommentBtn;
@property(nonatomic,retain)IBOutlet CustCommentView *custCommentView;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)MecrhCommentDateFilter *mecrhCommentDateFilter;

-(IBAction)createComment;
- (void)commentAdded;
- (void)setComment:(NSString *)comment;
-(IBAction)showDate:(id)sender;
- (void)selectDate:(NSString *)dateStr;

@end
