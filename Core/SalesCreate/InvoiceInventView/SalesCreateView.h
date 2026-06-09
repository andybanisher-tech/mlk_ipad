//
//  SalesCreateView.h
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "PreSalesGrid.h"
#import "SelectCustAcc.h"
#import "AddSalesCommentView.h"
#import "MerchActionViewController.h"
#import "FirmViewController.h"

#import "RWBorderedButton.h"

#import "ASPDatePickerViewController.h"

#import "sqlite3.h"

@class PreSalesGrid;
@class SelectCustAcc;
@class AddSalesCommentView;
@class MerchActionViewController;

@interface SalesCreateView : UIViewController <PreSalesGridDelegate, SelectCustDelegate, AddSalesCommentDelegate, FirmDelegate, UITextFieldDelegate, ASPDatePickerViewControllerDelegate> {
    UINavigationController *navigationController;
    
	//ReaderDemoController *readerDemoController;
    
    BOOL isViewPushed;
    
    IBOutlet UILabel *labelCust;
    IBOutlet UILabel *labelQtyTotal;
    IBOutlet UILabel *labelSumTotal;
    IBOutlet UILabel *labelMarkup;
    
    IBOutlet UITableView *itemMarkTable;
    IBOutlet UITableView *preSalesTable;
    
    NSString    *custAccount;
	NSString    *custName;
    
    double      qtyTotal;
    double      sumTotal;
    
    RWBorderedButton    *putItemsToSalesBtn;
    UIButton    *selectCustAccount;
    RWBorderedButton    *createSales;
    UIButton    *viewPreInvoice;
    UIButton    *actionBtn;
    
    UINavigationController *inventNavController;
    
    SelectCustAcc    *selectCustAcc;
    
    NSString    *salesId;
    
    UIButton    *createCommentBtn;
    
    NSString    *salesComment;
    
    UINavigationController *infoNavController;
    
    IBOutlet UITextField  *salesDeliveryDate;
    
    NSString    *dontInclCheckQty;
    NSString    *dontInclCheckAmount;
    
    NSString    *brand;
    
    IBOutlet UITextField *jurPerson;
    UIButton             *jurPersonBtn;
    NSString             *jurPersonIdValue;
    NSString             *jurPersonNameValue;
    
    IBOutlet UITextField *txtStoreField;
    
    FirmViewController  *firmViewController;
    
    NSString            *jurPersonMarkupValue;
    
    UIButton    *mergeBtn;
    BOOL        merge;
    UIBarButtonItem *editButton;
    UIBarButtonItem *closeBarButton;
}

@property(nonatomic,retain)UILabel *labelCust;
@property(nonatomic,retain)UILabel *labelQtyTotal;
@property(nonatomic,retain)UILabel *labelSumTotal;
@property(nonatomic,retain)UILabel *labelMarkup;
@property(nonatomic,retain)IBOutlet PreSalesGrid *preSalesGrid;
@property(nonatomic,readwrite)BOOL isViewPushed;
@property(nonatomic,retain)NSString *custAccount;
@property(nonatomic,retain)NSString *custName;
@property(nonatomic,retain)IBOutlet RWBorderedButton *putItemsToSalesBtn;
@property(nonatomic,retain)IBOutlet UIButton *selectCustAccount;
@property(nonatomic,retain)IBOutlet RWBorderedButton *createSale;
@property(nonatomic,retain)IBOutlet UIButton *viewPreInvoice;
@property(nonatomic,retain)IBOutlet UIButton *actionBtn;
@property(nonatomic,retain)IBOutlet UIButton *jurPersonBtn;
@property(nonatomic,retain)SelectCustAcc *selectCustAcc;
@property(nonatomic,readwrite)double qtyTotal;
@property(nonatomic,readwrite)double sumTotal;
@property(nonatomic,retain)NSString *salesId;
@property(nonatomic,retain)IBOutlet UIButton *createCommentBtn;
@property(nonatomic,retain)IBOutlet AddSalesCommentView *addSalesCommentView;
@property(nonatomic,retain)NSString *salesComment;
@property(nonatomic,retain)UITextField *salesDeliveryDate;
@property(nonatomic,retain)UITextField *jurPerson;

@property(nonatomic,retain)NSString *dontInclCheckQty;
@property(nonatomic,retain)NSString *dontInclCheckAmount;
@property(nonatomic,retain)NSString *brand;
@property(nonatomic,retain)NSString *jurPersonNameValue;
@property(nonatomic,retain)NSString *jurPersonIdValue;
@property(nonatomic,retain)NSString *jurPersonMarkupValue;
@property(nonatomic,retain)FirmViewController *firmViewController;
@property (nonatomic, strong) ASPDatePickerViewController *datePickerVC;
@property(nonatomic,readwrite)BOOL merge;

@property (nonatomic, weak) IBOutlet UISwitch *mergeSwitch;

@property (nonatomic, strong) NSDictionary *selectedStore;

@property (nonatomic, assign) BOOL isConsult;

//-(IBAction)actionOpenPlainDocument:(id)sender;
- (void)reloadData;
-(IBAction)putCustToSale;
-(IBAction)createSales;
-(IBAction)preInvoice;
- (void)createBtnPressed:(BOOL)sendSales;
- (void)custIsSelected:(NSString *)custAcc custName:(NSString *)custN;
- (void)gridIsUpdated;
-(IBAction)createComment;
- (void)commentAdded:(NSString *)comment;
-(UITableView*)getTV;
-(NSString*)getActionType:(NSString *)custAcc;
-(NSString*)getActionQty:(NSString *)custAcc type:(NSString*)type;
-(NSString*)getActionBrandId:(NSString *)custAcc type:(NSString*)type;
- (void)setDontChekParms:(NSString *)custAcc type:(NSString*)type;
-(NSString*)getActionSum:(NSString *)custAcc type:(NSString*)type;
-(IBAction)selectJurPerson;
- (void)getJurPersonDefault;
-(IBAction)mergeSale;
@end
