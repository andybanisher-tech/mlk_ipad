//
//  DNViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 13.11.12.
//
//

#import "UIKit/UIKit.h"
#import "DNGrid.h"
#import "PutListStatusDNRequest.h"
#import "sqlite3.h"
#import "StatusListViewController.h"

@class DNGrid;
@class PutListStatusDNRequest;

@interface DNViewController : UIViewController <DNGridDelegate, StatusListDelegate, UITextFieldDelegate, PutDNDelegate> {
    BOOL isViewPushed;
    
    NSString *custAccount;
    NSString *custName;
    NSString *brandId;
    
    IBOutlet UILabel *custNameLbl;
    IBOutlet UITableView *dnLine;
    
    UIButton    *merchBtn;
    
    PutListStatusDNRequest   *putDN;
    
    StatusListViewController    *statusListViewController;

    UITextField *alertTextField;
}
@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic, retain)IBOutlet UILabel *custNameLbl;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSString *custName;
@property(nonatomic,retain)IBOutlet DNGrid *dnGrid;
@property(nonatomic,retain)IBOutlet UIButton *merchBtn;
@property(nonatomic,retain)NSString *brandId;
@property(nonatomic,retain)StatusListViewController *statusListViewController;

-(IBAction)sendData;
- (void)updateDNStatus:(NSString *)mngrStatus brandId:(NSString*)_brandId;
- (void)updateDNComment:(NSString *)comment brandId:(NSString*)_brandId;
- (void)showList;
- (void)elementIsSelected:(NSString *)listElement;
- (void)isSended;

@end
