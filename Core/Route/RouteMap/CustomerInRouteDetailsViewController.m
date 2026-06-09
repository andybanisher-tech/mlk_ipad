//
//  CustomerInRouteDetailsViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 19.06.2024.
//

#import "CustomerInRouteDetailsViewController.h"

//Views
#import "CustomerInRouteDetailsSectionHeaderView.h"

//Cells
#import "CustomerInRouteCollectionViewCell.h"

//Constants
static const CGFloat kCollectionViewTopInset = 20.0;
static const CGFloat kCustomerSectionHeight = 640.0;
static const CGFloat kNearCustomerSectionHeight = 555.0;

@interface CustomerInRouteDetailsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CustomerInRouteDetailsSectionHeaderViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *customerNameLabel;

@property (nonatomic, weak) IBOutlet UICollectionView *customersCollectionView;

@property (nonatomic, strong) NSDictionary *customer;

@property (nonatomic, assign) double searchRadius;

@end

@implementation CustomerInRouteDetailsViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI
- (void)setupUI {
    //Register ReusableViews
    [self.customersCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass(CustomerInRouteDetailsSectionHeaderView.class) bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass(CustomerInRouteDetailsSectionHeaderView.class)];
    //Register Cells
    [self.customersCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass(CustomerInRouteCollectionViewCell.class) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass(CustomerInRouteCollectionViewCell.class)];
    [self setupCollectionViewLayout];
    
    self.searchRadius = LocalAuthWorker.routeNearCustomersSearchRadius;
    
    [self bindData];
}

#pragma mark - Data Setters
- (void)setCustomer:(NSDictionary *)customer {
    if (_customer == customer) { return; }
    
    _customer = customer;
    
    [self bindData];
}

- (void)bindData {
    if (!self.isViewLoaded) { return; }
    
    self.customerNameLabel.text = self.customer[@"custName"];
    [self.customersCollectionView reloadData];
}

#pragma mark - Button Actions
- (IBAction)backButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidTapBackButton)]) {
        [self.delegate userDidTapBackButton];
    }
}

#pragma mark - CustomerInRouteDetailsSectionHeaderViewDelegate
- (void)headerCustomerCardButtonTapped {
    [NavigationWorker openCustomerDetails:self.customer[@"custAccount"]];
}

- (void)headerAddToRouteButtonTapped {
    if ([self.delegate respondsToSelector:@selector(userDidAddCustomerToRoute:)]) {
        [self.delegate userDidAddCustomerToRoute:self.customer];
    }
}

- (void)headerRadiusSliderChangedValue:(float)value {
    if (self.searchRadius != value) {
        self.searchRadius = value;
        
        if ([self.delegate respondsToSelector:@selector(userDidChangeRadius:)]) {
            [self.delegate userDidChangeRadius:value];
        }
    }
}

#pragma mark - UICollectionViewDataSource
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        CustomerInRouteDetailsSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass(CustomerInRouteDetailsSectionHeaderView.class) forIndexPath:indexPath];
        
        headerView.codeLabel.text = self.customer[@"custAccount"];
        headerView.typeLabel.text = self.customer[@"property6Name"];
        headerView.factAddressLabel.text = self.customer[@"factAddress"];
        headerView.addressLabel.text = self.customer[@"address"];
        headerView.lastOrderDateLabel.text = self.customer[@"salesDate"];
        headerView.tasksLabel.text = [self.customer[@"tasks"] componentsJoinedByString:@"\n"];
        
        if (self.customer[@"nearCust"]) {
            headerView.addToRouteButton.hidden = NO;
            headerView.radiusStackView.hidden = YES;
        } else {
            headerView.addToRouteButton.hidden = YES;
            [headerView setSearchRadius:self.searchRadius];
            headerView.radiusStackView.hidden = NO;
        }
        
        headerView.delegate = self;
        
        return headerView;
    }
    
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.customer[@"nearCustomers"] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CustomerInRouteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CustomerInRouteCollectionViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.customer[@"nearCustomers"][indexPath.item];
    cell.lblName.text = object[@"custName"];
    
    cell.btnRemove.hidden = YES;
    
    cell.backgroundColor = [ASPFunctions colorFromHex:@"BDBDBD"];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    NSDictionary *customer = self.customer[@"nearCustomers"][indexPath.item];
    if ([self.delegate respondsToSelector:@selector(userDidSelectNearCustomer:)]) {
        [self.delegate userDidSelectNearCustomer:customer];
    }
}

#pragma mark - Layout Helpers
- (void)setupCollectionViewLayout {
    self.customersCollectionView.contentInset = UIEdgeInsetsMake(kCollectionViewTopInset, 0.0, 0.0, 0.0);
    
    CGFloat sectionHeaderHeight = self.customer[@"nearCust"] ? kNearCustomerSectionHeight : kCustomerSectionHeight;
    
    //Constants
    CGFloat itemWidth = 330;
    CGFloat itemHeight = 60.0;
   
    CGFloat interGroupSpacing = 5.0;
    
    NSCollectionLayoutSize *size = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:itemWidth] heightDimension:[NSCollectionLayoutDimension absoluteDimension:itemHeight]];
    
    //Item
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:size];
    
    //Group
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup verticalGroupWithLayoutSize:size subitems:@[item]];
    group.edgeSpacing = [NSCollectionLayoutEdgeSpacing spacingForLeading:[NSCollectionLayoutSpacing flexibleSpacing:0.0] top:nil trailing:[NSCollectionLayoutSpacing flexibleSpacing:0.0] bottom:nil];
    
    //SupplementaryViews
    NSCollectionLayoutSize *headerSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension estimatedDimension:sectionHeaderHeight]];
    NSCollectionLayoutBoundarySupplementaryItem *sectionHeader = [NSCollectionLayoutBoundarySupplementaryItem boundarySupplementaryItemWithLayoutSize:headerSize elementKind:UICollectionElementKindSectionHeader alignment:NSRectAlignmentTop];
    
    //Section
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
    section.boundarySupplementaryItems = @[sectionHeader];
    section.contentInsets = NSDirectionalEdgeInsetsMake(0.0, 0.0, kCollectionViewTopInset, 0.0);
    section.interGroupSpacing = interGroupSpacing;
    
    self.customersCollectionView.collectionViewLayout = [[UICollectionViewCompositionalLayout alloc] initWithSection:section];
}

@end
