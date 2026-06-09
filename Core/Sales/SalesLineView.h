//
//  SalesLineView.h
//  MLK
//
//  Created by Rustem Galyamov on 03.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "SalesLineGrid.h"
#import "sqlite3.h"
#import "FirmViewController.h"
#import "AddSalesCommentView.h"

#import "ASPDatePickerViewController.h"

@class SalesLineView;

@protocol SalesLineViewDelegate <NSObject>

@optional
- (void)userDidSendSales:(NSString *)salesID;

@end

@class SalesLineGrid;
@class AddSalesCommentView;
@class RWBorderedButton;

@interface SalesLineView : UIViewController <SalesLineDelegate, FirmDelegate, AddSalesCommentDelegate, UITextFieldDelegate, ASPDatePickerViewControllerDelegate> {
    BOOL isViewPushed;
    BOOL isOpen;
    
    IBOutlet UILabel *custName;
    IBOutlet UILabel *qty;
    IBOutlet UILabel *amount;
    
    NSString *customer;
    NSString *salesId;
    NSString *sumQty;
    NSString *sumAmount;
    NSString *num1C;
    
    IBOutlet UITableView *salesLine;
    
    UINavigationController *inventNavController;
    
    RWBorderedButton    *putItemsToSalesBtn;
    
    IBOutlet UITextField *jurPerson;
    UIButton             *jurPersonBtn;
    NSString             *jurPersonIdValue;
    NSString             *jurPersonNameValue;
    NSString             *jurPersonMarkupValue;
    
    __weak IBOutlet UITextField *txtStoreField;
    
    FirmViewController  *firmViewController;

    RWBorderedButton    *createCommentBtn;
    
    NSString    *salesComment;
    
    UINavigationController *infoNavController;
    
    IBOutlet UITextField  *salesDeliveryDate;
    
    UIButton    *mergeBtn;
    BOOL        merge;
    UIBarButtonItem *editButton;
    UIBarButtonItem *closeBarButton;
}

@property (nonatomic, weak) id <SalesLineViewDelegate> delegate;

@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,readwrite)BOOL isOpen;
@property(nonatomic,retain)IBOutlet UILabel *custName;
@property(nonatomic,retain)IBOutlet UILabel *qty;
@property(nonatomic,retain)IBOutlet UILabel *amount;
@property(nonatomic,retain)NSString *customer;
@property(nonatomic,retain)NSString *salesId;
@property(nonatomic,retain)NSString *sumQty;
@property(nonatomic,retain)NSString *sumAmount;
@property(nonatomic,retain)NSString *num1C;
@property(nonatomic,retain)IBOutlet UIButton *putItemsToSalesBtn;
@property(nonatomic,retain)IBOutlet UIButton *jurPersonBtn;
@property(nonatomic,retain)NSString *jurPersonNameValue;
@property(nonatomic,retain)NSString *jurPersonMarkupValue;
@property(nonatomic,retain)NSString *jurPersonIdValue;
@property(nonatomic,retain)FirmViewController *firmViewController;
@property (nonatomic, strong) ASPDatePickerViewController *datePickerVC;
@property(nonatomic,retain)IBOutlet SalesLineGrid *salesLineGrid;
@property(nonatomic,retain)UITextField *jurPerson;
@property(nonatomic,retain)IBOutlet UIButton *createCommentBtn;
@property(nonatomic,retain)IBOutlet AddSalesCommentView *addSalesCommentView;
@property(nonatomic,retain)NSString *salesComment;
@property(nonatomic,retain)UITextField *salesDeliveryDate;

@property(nonatomic,readwrite)BOOL merge;

@property (nonatomic, weak) IBOutlet UISwitch *mergeSwitch;

- (void)gridIsUpdated;
-(IBAction)putItemsToSales;
-(NSString *)getCustAccount;
-(IBAction)selectJurPerson;
- (void)selectFirm:(NSString *)firmId firmName:(NSString *)firmName firmMarkup:(NSString *)firmMarkup;
- (void)getJurPersonDefault;
-(IBAction)createComment;
- (void)commentAdded:(NSString *)comment;
- (void)getSalesComment;
-(NSString *)getSalesDlvDate;
- (void)setDlvDate;
- (void)updateSalesLine;
- (void)updateSalesLineByFirm:(NSString *)itemId qty:(NSString *)newQty lineAmount:(NSString *)lineAmount price:(NSString *)price;

@end
