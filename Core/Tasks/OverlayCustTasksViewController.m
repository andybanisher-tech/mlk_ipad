//
//  OverlayCustTasksViewController.m
//  MLK
//
//  Created by garu on 11/24/14.
//
//

#import "OverlayCustTasksViewController.h"
#import "CustTasksViewController.h"

@implementation OverlayCustTasksViewController

@synthesize rvController;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[rvController doneSearching_Clicked:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


@end
