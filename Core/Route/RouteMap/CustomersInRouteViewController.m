//
//  CustomersInRouteViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 18.06.2024.
//

#import "CustomersInRouteViewController.h"

//VCs
#import "CustViewController.h"
#import "CustomerInRouteDetailsViewController.h"

//Cells
#import "CustomerInRouteCollectionViewCell.h"

//CustomObject
#import "GetRouteDistRequest.h"

#import "GeneratedAssetSymbols.h"

@interface CustomersInRouteViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CustomerInRouteDetailsViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *routeDateLabel;

@property (nonatomic, weak) IBOutlet UICollectionView *customersCollectionView;

@property (nonatomic, strong) NSArray *customers;
@property (nonatomic, strong) NSDictionary *selectedCustomer;
@property (nonatomic, strong) NSDictionary *selectedNearCustomer;

@end

@implementation CustomersInRouteViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self refreshRoute:LocalAuthWorker.routeNearCustomersSearchRadius];
}

#pragma mark - UI
- (void)setupUI {
    [self.navigationController setNavigationBarHidden:YES];
    
    //Register Cells
    [self.customersCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass(CustomerInRouteCollectionViewCell.class) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass(CustomerInRouteCollectionViewCell.class)];
    
    //Binding Data
    NSDateFormatter *formatter = NSDateFormatter.new;
    formatter.dateFormat = @"E, dd MMMM yyyy";
    NSString *selectedDateString = [formatter stringFromDate:self.currentDate].uppercaseString;

    NSString *routeDate = [NSString stringWithFormat:@"Маршрут на: %@", selectedDateString];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: routeDate];
    [attributedString setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:self.routeDateLabel.font.pointSize], NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameGrayNavBarBackground]} range:[routeDate rangeOfString:selectedDateString]];
    
    self.routeDateLabel.attributedText = attributedString;
}

#pragma mark - Setters
- (void)setCustomers:(NSArray *)customers {
    _customers = customers;
    [self.customersCollectionView reloadData];
}

- (void)setSelectedCustomer:(NSDictionary *)customer {
    if (_selectedCustomer == customer) { return; }
    
    _selectedCustomer = customer;
    
    [self showCustomerInRouteDetails:customer];
}

- (void)setSelectedNearCustomer:(NSDictionary *)customer {
    if (_selectedNearCustomer == customer) { return; }
    
    _selectedNearCustomer = customer;
    
    [self showNearCustomerInRouteDetails:customer];
}

#pragma mark - Networking
- (void)refreshRoute:(double)radius {
    GetRouteDistRequest *routeRequest = [GetRouteDistRequest new];
    routeRequest.isSingleRequest = YES;
    [routeRequest routeReq:radius];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.customers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CustomerInRouteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CustomerInRouteCollectionViewCell.class) forIndexPath:indexPath];
    
    NSDictionary *object = self.customers[indexPath.item];
    cell.lblName.text = object[@"custName"];
    
    cell.btnRemove.hidden = YES;
    
    if ([object[@"status"] isEqual:@"visited"]) {
        cell.backgroundColor = [ASPFunctions colorFromHex:@"7DE779"];
    } else if ([object[@"status"] isEqual:@"visit"]) {
        cell.backgroundColor = [ASPFunctions colorFromHex:@"6395EC"];
    } else {
        cell.backgroundColor = [ASPFunctions colorFromHex:@"BDBDBD"];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    NSDictionary *customer = self.customers[indexPath.item];
    if (self.selectedCustomer == customer) { return; }
    
    if ([self.delegate respondsToSelector:@selector(userDidSelectCustomer:)]) {
        [self.delegate userDidSelectCustomer:customer];
    }
}

#pragma mark - CustomerInRouteDetailsViewControllerDelegate
- (void)userDidTapBackButton {
    if ([self.delegate respondsToSelector:@selector(userDidSelectCustomer:)]) {
        [self.delegate userDidSelectCustomer:nil];
    }
}

- (void)userDidSelectNearCustomer:(NSDictionary *)customer {
    if ([self.delegate respondsToSelector:@selector(userDidSelectCustomer:)]) {
        [self.delegate userDidSelectCustomer:customer];
    }
}

- (void)userDidAddCustomerToRoute:(NSDictionary *)customer {
    [SVProgressHUD show];
    
    NSString *custAccount = customer[@"custAccount"];
    NSString *custName = customer[@"custName"];
    
    NSDateFormatter *dateFormatter = NSDateFormatter.new;
    dateFormatter.dateFormat = dateFormat_dd_MM_YYYY;
    
    NSString *strDate = [dateFormatter stringFromDate:NSDate.date];
    
    CustViewController *custVC = [CustViewController new];
    [custVC addCustomersToRoute:custAccount custName:custName custAddr:customer[@"address"] strDate:strDate];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshRoute:LocalAuthWorker.routeNearCustomersSearchRadius];
    });
}

- (void)userDidChangeRadius:(double)radius {
    [self refreshRoute:radius];
}

#pragma mark - Helpers
- (void)showCustomerInRouteDetails:(NSDictionary *)customer {
    if (!customer) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popToViewController:self.navigationController.viewControllers[1] animated:YES];
        
        CustomerInRouteDetailsViewController *customerDetailsVC = self.navigationController.viewControllers.lastObject;
        [customerDetailsVC setCustomer:customer];
    } else {
        CustomerInRouteDetailsViewController *customerDetailsVC = [[UIStoryboard storyboardWithName:@"RouteMap" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CustomerInRouteDetailsViewController.class)];
        customerDetailsVC.delegate = self;
        [customerDetailsVC setCustomer:customer];
        
        [self.navigationController pushViewController:customerDetailsVC animated:YES];
    }
}

- (void)showNearCustomerInRouteDetails:(NSDictionary *)customer {
    if (!customer) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if (self.navigationController.viewControllers.count > 2) {
        CustomerInRouteDetailsViewController *customerDetailsVC = self.navigationController.viewControllers.lastObject;
        [customerDetailsVC setCustomer:customer];
    } else {
        CustomerInRouteDetailsViewController *customerDetailsVC = [[UIStoryboard storyboardWithName:@"RouteMap" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(CustomerInRouteDetailsViewController.class)];
        customerDetailsVC.delegate = self;
        [customerDetailsVC setCustomer:customer];
        
        [self.navigationController pushViewController:customerDetailsVC animated:YES];
    }
}

@end
