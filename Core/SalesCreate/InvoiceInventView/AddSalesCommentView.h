//
//  AddSalesCommentView.h
//  MLK
//
//  Created by Rustem Galyamov on 20.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol AddSalesCommentDelegate
- (void)commentAdded:(NSString *)comment;
@end

@interface AddSalesCommentView : UIViewController {
    UIButton    *createBtn;
    UIButton    *cancelBtn;
    
    NSString    *custAccount;
    NSString    *salesComment;
    
    IBOutlet UITextView *comment;
    
    BOOL allowEditNo;
    BOOL customerHasPDZ;
    
    IBOutlet UILabel *labelText;
}

@property(nonatomic,assign) id<AddSalesCommentDelegate> delegate;

@property(nonatomic,retain)IBOutlet UIButton *createButton;
@property(nonatomic,retain)IBOutlet UIButton *cancellButton;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)UITextView *comment;
@property(nonatomic,retain)NSString *salesComment;
@property(nonatomic,readwrite)BOOL allowEditNo;
@property(nonatomic,readwrite)BOOL customerHasPDZ;
@property(nonatomic,retain)IBOutlet UILabel *labelText;

-(IBAction)create;
-(IBAction)cancel;

@end

