//
//  CDSecondaryMainViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 25.09.2024.
//

#import "CDSecondaryMainViewController.h"

//Cells
#import "CDSecondaryMainTableViewCell.h"

//UI Constants
static const CGFloat kEstimatedCustomerDetailCellHeight = 50.0;

@interface CDSecondaryMainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mainTableView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation CDSecondaryMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareDataSource];
}

#pragma mark - Prepare Data
- (void)prepareDataSource {
    self.dataSource = [NSMutableArray new];
    
    //Sort first
    NSArray *sortedKeys = [self.customerDetails keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"sort"] compare:obj2[@"sort"]];
    }];

    //Filter and format dataSource
    NSDictionary *custDetailsNames = [self custDetailNames];
    
    for (NSString *key in sortedKeys) {
        NSString *custDetailsName = custDetailsNames[key];
        if (custDetailsName) {
            NSMutableDictionary *detail = [NSMutableDictionary new];
            detail[@"name"] = custDetailsName;
            detail[@"value"] = self.customerDetails[key][@"value"];
            
            [self.dataSource addObject:detail];
        }
    }

    [self.mainTableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryMainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(CDSecondaryMainTableViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.dataSource[indexPath.row];
    [cell setData:object];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kEstimatedCustomerDetailCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

#pragma mark - ConstData
- (NSDictionary *)custDetailNames {
    return @{
        @"CustAccount" : @"Код клиента",
        @"Property6Name" : @"Тип клиента",
        @"Name" : @"Название клиента",
        @"FactAddress" : @"Адрес фактический",
        @"Address" : @"Адрес юридический",
        @"LegalName" : @"Юр. наименование",
        @"INN" : @"ИНН",
        @"KPP" : @"КПП",
        @"BankName" : @"Банк",
        @"BankAccount" : @"Банковский счёт"
    };
}

@end
