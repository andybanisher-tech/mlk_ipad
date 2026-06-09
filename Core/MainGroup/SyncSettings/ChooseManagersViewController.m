//
//  ChooseManagersViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 02.09.2021.
//

#import "ChooseManagersViewController.h"

//Cells
#import "ChooseManagerTableViewCell.h"

//Constants
static const CGFloat kPopoverWidth = 300.0;
static const CGFloat kPopoverMinHeight = 142.0;
static const CGFloat kSettingsCellHeight = 44.0;

@interface ChooseManagersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@property (nonatomic, weak) IBOutlet UITableView *mainTableView;

@property (nonatomic, weak) IBOutlet UIButton *selectButton;

@end

@implementation ChooseManagersViewController

- (void)viewIsAppearing:(BOOL)animated {
    [super viewIsAppearing:animated];
    self.preferredContentSize = CGSizeMake(kPopoverWidth, kPopoverMinHeight + kSettingsCellHeight * (self.iPadsArray.count + 1));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareData];
}

#pragma mark - Initial Setup
- (void)prepareData {
    if (self.isSchedulerMode) {
        self.titleLabel.text = @"Выберите менеджера";
        [self.selectButton setTitle:@"Загрузить планировщик" forState:UIControlStateNormal];
    }
   
    if (!self.selectedIPadsSet) {
        self.selectedIPadsSet = [NSMutableSet new];
    }
    
    self.iPadsArray = [self.iPadsArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return ![self.selectedIPadsSet containsObject: obj1] && [self.selectedIPadsSet containsObject: obj2];
    }];
    [self.mainTableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isSchedulerMode) {
        return self.iPadsArray.count;
    } else {
        return self.iPadsArray.count + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChooseManagerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(ChooseManagerTableViewCell.class) forIndexPath:indexPath];
    
    if (!self.isSchedulerMode && indexPath.row == 0) {
        cell.lblName.text = self.iPadsArray.count == self.selectedIPadsSet.count ? @"Отменить выбор" : @"Выбрать всех";
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        NSInteger index = self.isSchedulerMode ? indexPath.row : indexPath.row - 1;
        NSDictionary *object = self.iPadsArray[index];
        cell.lblName.text = object[@"name"];
        
        if ([self.selectedIPadsSet containsObject:object]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kSettingsCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!self.isSchedulerMode && indexPath.row == 0) {
        if (self.iPadsArray.count == self.selectedIPadsSet.count) {
            [self.selectedIPadsSet removeAllObjects];
        } else {
            self.selectedIPadsSet = [NSMutableSet setWithArray:self.iPadsArray];
        }
    } else {
        NSInteger index = self.isSchedulerMode ? indexPath.row : indexPath.row - 1;
        NSDictionary *object = self.iPadsArray[index];
        
        if ([self.selectedIPadsSet containsObject:object]) {
            [self.selectedIPadsSet removeObject:object];
        } else {
            if (self.isSchedulerMode) {
                [self.selectedIPadsSet removeAllObjects];
            }
            [self.selectedIPadsSet addObject:object];
        }
    }
    
    [tableView reloadData];
}

#pragma mark - Button Actions
- (IBAction)selectButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidChooseManagers:)]) {
        [self.delegate userDidChooseManagers:self.selectedIPadsSet];
    }
}

- (IBAction)btnCloseTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
