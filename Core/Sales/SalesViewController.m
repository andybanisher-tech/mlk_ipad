//
//  SalesViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 23.08.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//
#import "SalesViewController.h"
#import "AppDelegate.h"
#import "NewSalesGrid.h"

#import "GeneratedAssetSymbols.h"

@interface SalesViewController()
    @property (nonatomic, strong) NSArray *data;

@end

@implementation SalesViewController {
    NSInteger _selectedIndex;
}

@synthesize detailViewController;

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *barColor = [UIColor colorNamed:ACColorNameGrayNavBarBackground];
    self.navigationController.navigationBar.barTintColor = barColor;
    self.navigationController.navigationBar.translucent = NO;

    [self.splitViewController.view setBackgroundColor:[ASPFunctions colorFromHex:@"cccccc"]];

    UIView *statusBarVertLine = [[UIView alloc]initWithFrame:CGRectMake(320, 0, 1.f/UIScreen.mainScreen.scale, 20)];
    [statusBarVertLine setBackgroundColor: barColor];
    [self.splitViewController.view addSubview:statusBarVertLine];

    UIView *navBarVertDot = [[UIView alloc]initWithFrame:CGRectMake(320, 20, 1.f/UIScreen.mainScreen.scale, 1.f/UIScreen.mainScreen.scale)];
    [navBarVertDot setBackgroundColor: [UIColor blackColor]];
    [self.splitViewController.view addSubview:navBarVertDot];

    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];

    [self.navigationController.navigationBar addSubview:titleView];
	self.clearsSelectionOnViewWillAppear = NO;

    UIView *backgroundView = [UIView new];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView setBackgroundView:backgroundView];
    [self.tableView setBackgroundColor:UIColor.clearColor];

    self.view.backgroundColor = UIColor.clearColor;

    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];
    [backgroundView addSubview:bgImage];
    
    bgImage.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[bgImage.leadingAnchor constraintEqualToAnchor:backgroundView.leadingAnchor],
       [bgImage.trailingAnchor constraintEqualToAnchor:backgroundView.trailingAnchor],
       [bgImage.topAnchor constraintEqualToAnchor:backgroundView.topAnchor],
       [bgImage.bottomAnchor constraintEqualToAnchor:backgroundView.bottomAnchor]]];
    
    self.tableView.scrollEnabled = NO;
    
    self.data = @[@"Заказы текущего дня", @"История заказов", @"Отложенные заказы", @"Консультации текущего дня", @"История консультаций"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    if (!lastViewController) {
        NewSalesGrid *detailView = [NewSalesGrid new];
        detailView.isToday = YES;
        lastViewController = detailView;
        
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        UIImage *image = [UIImage imageNamed:ACImageNameBigRightArrow];
        UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,image.size.width,image.size.height)];
        [accessoryButton setImage:image forState:UIControlStateNormal];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.font= [UIFont boldSystemFontOfSize:21.f];
        cell.accessoryView = accessoryButton;
    }
    
  	cell.textLabel.text = self.data[indexPath.row];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    UIImage *image;
    if (_selectedIndex == indexPath.row) {
        image = [UIImage imageNamed:ACImageNameBigRightWhiteArrow];
        cell.textLabel.textColor = UIColor.whiteColor;

    } else {
        image = [UIImage imageNamed:ACImageNameBigRightArrow];
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, image.size.width, image.size.height)];
    [accessoryButton setImage:image forState:UIControlStateNormal];
    cell.accessoryView = accessoryButton;

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = UIColor.clearColor;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tv deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *cell = [tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
    if (cell) {
        UIImage *image = [UIImage imageNamed:ACImageNameBigRightArrow];
        UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,image.size.width,image.size.height)];
        [accessoryButton setImage:image forState:UIControlStateNormal];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.accessoryView = accessoryButton;
    }
    
    _selectedIndex = indexPath.row;

    cell = [tv cellForRowAtIndexPath:indexPath];
    if (cell) {
        UIImage *image = [UIImage imageNamed:ACImageNameBigRightWhiteArrow];
        UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,image.size.width,image.size.height)];
        [accessoryButton setImage:image forState:UIControlStateNormal];
        cell.textLabel.textColor = UIColor.whiteColor;
        cell.accessoryView = accessoryButton;
    }

    UIViewController *localDetailViewController;
    
    if (indexPath.row == 0) {
        NewSalesGrid *detailView = [NewSalesGrid new];
        detailView.isToday = YES;
        localDetailViewController = detailView;
    } else if (indexPath.row == 1) {
        NewSalesGrid *detailView = [NewSalesGrid new];
        localDetailViewController = detailView;
    } else if (indexPath.row == 2) {
        NewSalesGrid *detailView = [NewSalesGrid new];
        detailView.isPending = YES;
        localDetailViewController = detailView;
    } else if (indexPath.row == 3) {
        NewSalesGrid *detailView = [NewSalesGrid new];
        detailView.isToday = YES;
        detailView.isConsult = YES;
        localDetailViewController = detailView;
    } else if (indexPath.row == 4) {
        NewSalesGrid *detailView = [NewSalesGrid new];
        detailView.isConsult = YES;
        localDetailViewController = detailView;
    }
    
    //NavBar Setup
    UINavigationController *navController = [UINavigationController new];
    [ASPFunctions setupNavigationController:navController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    lastViewController = (NewSalesGrid *)localDetailViewController;
    lastViewController.navigationItem.title = self.data[indexPath.row];
    [navController pushViewController:localDetailViewController animated:YES];
    AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;

    delegate.splitSalesViewController.viewControllers = @[delegate.splitSalesViewController.viewControllers.firstObject, navController];
}

@end
