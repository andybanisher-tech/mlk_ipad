//
//  NoticeDescrViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 18.12.12.
//
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"

@protocol NoticeDelegate
- (void)gridIsUpdated;
@end

@interface NoticeDescrViewController : UIViewController {
    NSString *noticeId;
    NSString *noticeName;
    NSString *noticeDescription;
    
    IBOutlet UITextView  *description;
    
    BOOL isViewPushed;
    
    UIButton    *delBtn;
}
@property(nonatomic,assign) id<NoticeDelegate> delegate;
@property(nonatomic, retain)NSString *noticeId;
@property(nonatomic, retain)NSString *noticeName;
@property(nonatomic, retain)NSString *noticeDescription;
@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,retain)IBOutlet UIButton *delBtn;


@property(nonatomic) BOOL isNewNotice;

- (void)cancel_Clicked:(id)sender;
- (void)updateNotice:(NSString *)notId;
-(IBAction)deleteNotice:(id)sender;
-(BOOL)checkForNew;

@end
