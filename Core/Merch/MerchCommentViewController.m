//
//  MerchCommentViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MerchCommentViewController.h"
#import "AddCustComment.h"
#import "CustCommentView.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

@implementation MerchCommentViewController

@synthesize isViewPushed, createCommentBtn, dateFilter;
@synthesize custCommentView;
@synthesize custAccount;
@synthesize mecrhCommentDateFilter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //NavBar Setup
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];

    [self.navigationController.navigationBar addSubview:titleView];

    if (custCommentView == nil) {
		custCommentView = [[CustCommentView alloc] init];
        custCommentView.custAccount = custAccount;
        custCommentView.commentType = @"merch";
    }
    
    [custComments setDataSource:custCommentView];
    [custComments setDelegate:custCommentView];
    
	custCommentView.view = custCommentView.tableView;
    self.custCommentView.delegate  = self;
    
    if (isViewPushed == NO) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        self.navigationItem.rightBarButtonItem = barButton;
	}
    

    CALayer *chLayer = custComments.layer;
    chLayer.borderColor = [[UIColor blackColor] CGColor];
    chLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    CALayer *txtLayer = textComments.layer;
    txtLayer.borderColor = [[UIColor blackColor] CGColor];
    txtLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    self.navigationItem.title = @"Комментарии";
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

-(IBAction)createComment {
	AddCustComment *fvController = [[AddCustComment alloc] initWithNibName: @"AddCustComment" bundle: nil];
    
    fvController.custAccount = custAccount;
    fvController.delegate    = self;
    fvController.commentType = @"merch";
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];

    fvController = nil;
    infoNavController = nil;
}

- (void)commentAdded {
    [custCommentView refreshData];
    [custComments reloadData];
}

- (void)setComment:(NSString *)comment {
    textComments.text = comment;
}

-(IBAction)showDate:(id)sender {
    if (!mecrhCommentDateFilter) {
        mecrhCommentDateFilter = [[MecrhCommentDateFilter alloc] init];
        mecrhCommentDateFilter.delegate = self;
        mecrhCommentDateFilter.custAccount = custAccount;
        
        mecrhCommentDateFilter.modalPresentationStyle = UIModalPresentationPopover;
        mecrhCommentDateFilter.popoverPresentationController.sourceView = sender;
        mecrhCommentDateFilter.popoverPresentationController.sourceRect = CGRectMake(85, 75, dateFilter.bounds.size.width, dateFilter.bounds.size.height);
        
        dateFilter = nil;
        
        [self presentViewController:mecrhCommentDateFilter animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        mecrhCommentDateFilter = nil;
    }
}

- (void)selectDate:(NSString *)dateStr {
    if (mecrhCommentDateFilter.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        mecrhCommentDateFilter = nil;
    }
    
    custCommentView = nil;
    custCommentView = [[CustCommentView alloc] init];
    custCommentView.custAccount  = custAccount;
    custCommentView.commentType  = @"merch";
    custCommentView.dateSelected = dateStr; 
    
    [custComments setDataSource:custCommentView];
    [custComments setDelegate:custCommentView];

    custCommentView.view = custCommentView.tableView;
    self.custCommentView.delegate  = self;

}


@end
