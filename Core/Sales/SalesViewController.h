//
//  SalesViewController.h
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"

@class SalesDetailViewController;
@class NewSalesGrid;

@interface SalesViewController : UITableViewController <UISplitViewControllerDelegate> {
	SalesDetailViewController *detailViewController;
    
    NewSalesGrid *lastViewController;
}

@property(nonatomic,retain) SalesDetailViewController *detailViewController;

@end
