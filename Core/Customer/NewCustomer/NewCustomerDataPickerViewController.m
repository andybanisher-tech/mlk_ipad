//
//  NewCustomerDataPickerViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 29.11.2021.
//

#import "NewCustomerDataPickerViewController.h"

//Cells
#import "NewCustomerDataTableViewCell.h"

//UIConstants
static const CGFloat kNewCustomerDataCellHeight = 50.0;

@interface NewCustomerDataPickerViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation NewCustomerDataPickerViewController

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewCustomerDataTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(NewCustomerDataTableViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.row];
    cell.lblName.text = object[@"name"];
    
    if (self.selectedObject == object) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kNewCustomerDataCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedObject = self.dataSource[indexPath.row];
    NSArray *visibleIndexPaths = [tableView indexPathsForVisibleRows];
    [tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    
    if ([self.delegate respondsToSelector:@selector(userDidPickCustomerData:)]) {
        [self.delegate userDidPickCustomerData:self.selectedObject];
    }
}

@end
