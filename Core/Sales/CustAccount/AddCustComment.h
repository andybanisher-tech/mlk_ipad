//
//  AddCustComment.h
//  MLK
//
//  Created by Rustem Galyamov on 04.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol AddCustCommentDelegate
- (void)commentAdded;
@end

@interface AddCustComment : UIViewController {
    UIButton    *createBtn;
    UIButton    *cancelBtn;
    
    NSString    *custAccount;
    
    IBOutlet UITextView *comment;
    
    NSString    *commentType;
}
@property(nonatomic,assign)id<AddCustCommentDelegate> delegate;
@property(nonatomic,retain)IBOutlet UIButton *createButton;
@property(nonatomic,retain)IBOutlet UIButton *cancellButton;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)UITextView *comment;
@property(nonatomic,retain)NSString *commentType;

-(IBAction)create;
-(IBAction)cancel;
- (void)getCustComment;

@end
