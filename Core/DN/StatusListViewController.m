//
//  StatusListViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 27.11.12.
//
//

#import "StatusListViewController.h"

@interface StatusListViewController ()

@end

@implementation StatusListViewController

@synthesize delegate;
@synthesize elementNameList;

#define LABEL_TAG 1

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.tableView.frame = CGRectMake(0, 0, 250, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [self refreshData];
    [super viewDidLoad];
}

- (void)createList {
    elementNameList           = [NSMutableArray new];
	
    [elementNameList  addObject:@"Новый"];
    [elementNameList  addObject:@"Работает"];
    [elementNameList  addObject:@"Закрытие"];
    [elementNameList  addObject:@"Не работает"];
    //[elementNameList  addObject:@"Реанимация"];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [elementNameList count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Get the label for the current cell
	cell.textLabel.text       = [elementNameList objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate) {
        [self.delegate elementIsSelected:[elementNameList objectAtIndex:indexPath.row]];
    }
}

- (void)refreshData{

    [self createList];
    [self.tableView reloadData];
}

@end
