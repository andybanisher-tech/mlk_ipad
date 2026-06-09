//
//  OverlayCustView.m
//  MLK
//
//  Created by Rustem Galyamov on 03.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "OverlayCustView.h"
#import "CustViewController.h"

@implementation OverlayCustView

@synthesize rvController;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[rvController doneSearching_Clicked:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


@end
