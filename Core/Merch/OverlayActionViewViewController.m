//
//  OverlayActionViewViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 09.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "OverlayActionViewViewController.h"
#import "MerchActionViewController.h"

@implementation OverlayActionViewViewController

@synthesize rvController;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[rvController doneSearching_Clicked:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


@end
