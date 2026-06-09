//
//  LeftTableViewController.m
//  Created by Devin Ross on 7/7/10.
//
/*
 
 tapku.com || https://github.com/devinross/tapkulibrary
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "LeftTableViewController.h"

#import "RegularRouteView.h"
#import "CustForRoute.h"
#import "CustViewController.h"
#import "TasksViewController.h"

#import "SyncStateWorker.h"

#import "GeneratedAssetSymbols.h"

@interface LeftTableViewController() <UISplitViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *data;

@end

@implementation LeftTableViewController {
    NSIndexPath *_selectedIndexPath;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //Notifications
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(syncStateChanged) name:kSyncStateChanged object:nil];
    
    //NavBar Setup
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    [self.splitViewController.view setBackgroundColor:[ASPFunctions colorFromHex:@"cccccc"]];
    
    UIView *statusBarVertLine = [[UIView alloc]initWithFrame:CGRectMake(320, 0, 1.f/UIScreen.mainScreen.scale, 20)];
    [statusBarVertLine setBackgroundColor: [UIColor colorNamed:ACColorNameGrayNavBarBackground]];
    [self.splitViewController.view addSubview:statusBarVertLine];
    
    UIView *navBarVertDot = [[UIView alloc]initWithFrame:CGRectMake(320, 20, 1.f/UIScreen.mainScreen.scale, 1.f/UIScreen.mainScreen.scale)];
    [navBarVertDot setBackgroundColor: [UIColor blackColor]];
    [self.splitViewController.view addSubview:navBarVertDot];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];
    
    [self.navigationController.navigationBar addSubview:titleView];
    
    self.data = [NSMutableArray new];
    
    [self.data addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"Маршрут", @"Клиенты", /*@"Календарь посещений",*/ @"Задачи", @"Временные клиенты", nil], @"rows", @"", @"title", nil]];
    
    self.clearsSelectionOnViewWillAppear = NO;
    
    //self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.tableView.separatorColor = [UIColor blackColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView setBackgroundView:nil];
    
    UIView *backgroundView = [UIView new];
    
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
    
    _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self syncStateChanged];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [self.data count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.data objectAtIndex:section] objectForKey:@"rows"] count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.font= [UIFont boldSystemFontOfSize:21.f];
    }
    cell.textLabel.text = [[[self.data objectAtIndex:indexPath.section] objectForKey:@"rows"] objectAtIndex:indexPath.row];
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSString *moreCust = [PersistenceWorker load:@"moreCust"];
    
    NSString *arrowImageName = ACImageNameBigRightArrow;
    if (![moreCust isEqualToString:@"1"] && indexPath.row == 6) {
        cell.userInteractionEnabled = NO;
    } else {
        cell.userInteractionEnabled = YES;
        cell.textLabel.textColor = [UIColor blackColor];
        
        if ([indexPath compare:_selectedIndexPath] == NSOrderedSame) {
            cell.textLabel.textColor = UIColor.whiteColor;
            arrowImageName = ACImageNameBigRightWhiteArrow;
        }
    }
    
    UIImage *image = [UIImage imageNamed:arrowImageName];
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,image.size.width,image.size.height)];
    [accessoryButton setImage:image forState:UIControlStateNormal];
    cell.accessoryView = accessoryButton;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = UIColor.clearColor;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tv cellForRowAtIndexPath:_selectedIndexPath];
    if (cell) {
        UIImage *image = [UIImage imageNamed:ACImageNameBigRightArrow];
        UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,image.size.width,image.size.height)];
        [accessoryButton setImage:image forState:UIControlStateNormal];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.accessoryView = accessoryButton;
    }
    
    cell = [tv cellForRowAtIndexPath:indexPath];
    if (cell) {
        UIImage *image = [UIImage imageNamed:ACImageNameBigRightWhiteArrow];
        UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,image.size.width,image.size.height)];
        [accessoryButton setImage:image forState:UIControlStateNormal];
        cell.textLabel.textColor = UIColor.whiteColor;
        cell.accessoryView = accessoryButton;
    }
    
    if ([indexPath compare:_selectedIndexPath] != NSOrderedSame) {
        _selectedIndexPath = indexPath;
        [self syncStateChanged];
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return [[self.data objectAtIndex:section] objectForKey:@"footer"];
}

#pragma mark - Notifications
- (void)syncStateChanged {
    [self.splitViewController showDetailViewController:[self detailVCAtIndex:_selectedIndexPath.row] sender:self];
}

#pragma mark - Helpers
- (UIViewController *)detailVCAtIndex:(NSInteger)index{
    UIViewController *detailVC;
    if (index == 0) {
        detailVC = [RegularRouteView new];
    } else if (index == 2) {
        detailVC = [[UIStoryboard storyboardWithName:@"Tasks" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([TasksViewController class])];
    } else {
        CustViewController *custVC = [CustViewController new];
        custVC.visitPlan = NO;
        custVC.additionalCusts = index == 3;
        detailVC = custVC;
    }
    
    //NavBar Setup
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailVC];
    [ASPFunctions setupNavigationController:navController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, navController.navigationBar.frame.size.width, 1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];
    [navController.navigationBar addSubview:titleView];
    
    return navController;
}

@end

