//
//  OverlaySelectCustAcc.m
//  MLK
//
//  Created by Rustem Galyamov on 27.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "OverlaySelectCustAcc.h"
#import "SelectCustAcc.h"

@implementation OverlaySelectCustAcc

@synthesize rvController;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[rvController doneSearching_Clicked:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


@end
