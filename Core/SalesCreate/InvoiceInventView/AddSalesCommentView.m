//
//  AddSalesCommentView.m
//  MLK
//
//  Created by Rustem Galyamov on 20.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AddSalesCommentView.h"

#import "GeneratedAssetSymbols.h"

@implementation AddSalesCommentView

@synthesize createButton, cancellButton, custAccount, salesComment, labelText;
@synthesize comment;
@synthesize delegate, allowEditNo, customerHasPDZ;

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
    self.navigationItem.title = @"Создание комментария";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    comment.text = salesComment;
    
    if (allowEditNo == YES) {
        comment.editable  = FALSE;
        createBtn.enabled = FALSE;
    }
    
    if (customerHasPDZ == YES) {
        labelText.hidden = FALSE;
    } else {
        labelText.hidden = YES;
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

-(IBAction)create {
    [self.delegate commentAdded:comment.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
