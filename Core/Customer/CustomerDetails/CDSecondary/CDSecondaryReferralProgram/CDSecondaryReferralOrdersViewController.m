//
//  CDSecondaryReferralOrdersViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 24.06.2025.
//

#import "CDSecondaryReferralOrdersViewController.h"

//Cells
#import "CDSecondaryReferralOrderCollectionViewCell.h"
#import "CDSecondaryReferralOrdersLoadMoreCollectionViewCell.h"

@interface CDSecondaryReferralOrdersViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *mainCollectionView;

@property (nonatomic, strong) NSDictionary *pagination;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation CDSecondaryReferralOrdersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self prepareLayout];
    [self getReferralOrders];
}

#pragma mark - UI
- (void)prepareLayout {
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    configuration.headerMode = UICollectionLayoutListHeaderModeSupplementary;
    configuration.itemSeparatorHandler = ^UIListSeparatorConfiguration * _Nonnull(NSIndexPath * _Nonnull indexPath, UIListSeparatorConfiguration * _Nonnull sectionSeparatorConfiguration) {
        sectionSeparatorConfiguration.bottomSeparatorInsets = NSDirectionalEdgeInsetsZero;
        return sectionSeparatorConfiguration;
    };
    
    UICollectionViewCompositionalLayout *layout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];
    self.mainCollectionView.collectionViewLayout = layout;
}

#pragma mark - Networking
- (void)getReferralOrders {
    [SVProgressHUD showWithStatus:@"Получаем заказы клиентов..."];
    
    if (!self.pagination || !self.dataSource) {
        self.pagination = [NSDictionary new];
        self.dataSource = [NSMutableArray new];
    }
    
    NSInteger page = [self.pagination[@"CurrentPage"] integerValue] + 1;
    
    [APIWorker.sharedInstance getReferralOrders:self.custAccount page:page completion:^(NSDictionary * _Nullable data, NSError * _Nullable error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        } else {
            [SVProgressHUD dismiss];
            
            self.pagination = data[@"Pagination"];
            [self.dataSource addObjectsFromArray:data[@"Orders"]];
        }
        
        [self.mainCollectionView reloadData];
    }];
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CDSecondaryReferralOrdersSectionHeaderView" forIndexPath:indexPath];
        return headerView;
    }
    
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger currentPage = [self.pagination[@"CurrentPage"] integerValue];
    NSInteger totalPages = [self.pagination[@"TotalPages"] integerValue];
    
    if (currentPage < totalPages) {
        return self.dataSource.count + 1;
    } else {
        return self.dataSource.count;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.dataSource.count) {
        CDSecondaryReferralOrderCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryReferralOrderCollectionViewCell.class) forIndexPath:indexPath];
        
        NSDictionary *object = self.dataSource[indexPath.item];
        [cell setOrder:object];
        
        return cell;
    } else {
        CDSecondaryReferralOrdersLoadMoreCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryReferralOrdersLoadMoreCollectionViewCell.class) forIndexPath:indexPath];
        
        __weak typeof(self) weakSelf = self;
        cell.onCellLoadMoreButtonTapped = ^{
            [weakSelf getReferralOrders];
        };
        
        return cell;
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

}

@end
