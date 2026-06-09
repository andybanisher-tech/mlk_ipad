//
//  SalesDetailViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//
#import "SalesDetailViewController.h"

@interface SalesDetailViewController ()
@property (nonatomic, retain) UIViewController *mainController;
@end

@implementation SalesDetailViewController
@synthesize toolbar, mainController;


- (void)viewDidLoad {
    [super viewDidLoad];
    
	//self.view.backgroundColor = UIColor.whiteColor;
	
    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	toolbar.items = [NSArray array];
	[self.view addSubview:toolbar];
    
    //self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.toolbar.tintColor = [UIColor blackColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}

- (BOOL)shouldAutorotate {
    return YES;
}


@end
