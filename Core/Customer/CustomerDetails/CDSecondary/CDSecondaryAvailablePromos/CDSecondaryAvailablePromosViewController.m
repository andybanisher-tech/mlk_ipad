//
//  CDSecondaryAvailablePromosViewController.m
//  MLK
//

#import "CDSecondaryAvailablePromosViewController.h"

#import "CDSecondaryAvailablePromosCollectionViewCell.h"

#import "GeneratedAssetSymbols.h"

@interface CDSecondaryAvailablePromosViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate, CDSecondaryAvailablePromosCollectionViewCellDelegate>

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIButton *markFilterButton;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UICollectionView *mainCollectionView;
@property (nonatomic, strong) UILabel *emptyLabel;

@property (nonatomic, strong) NSArray<NSDictionary *> *allPromotions;
@property (nonatomic, strong) NSArray<NSDictionary *> *filteredPromotions;

@property (nonatomic, copy) NSString *searchQuery;
@property (nonatomic, copy) NSString *selectedMark;

@end

@implementation CDSecondaryAvailablePromosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    self.navigationItem.title = @"Доступные акции";

    [self setupHeader];
    [self setupCollectionView];
    [self setupEmptyState];
    [self getAvailablePromos];
}

#pragma mark - Setup
- (void)setupHeader {
    self.headerView = [UIView new];
    self.headerView.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerView];

    self.searchBar = [UISearchBar new];
    self.searchBar.placeholder = @"Поиск";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;

    self.markFilterButton = [self toolbarButtonWithTitle:@"Марка" action:@selector(markFilterButtonTapped)];
    self.refreshButton = [self toolbarButtonWithTitle:@"Обновить" action:@selector(refreshButtonTapped)];

    [self.headerView addSubview:self.searchBar];
    [self.headerView addSubview:self.markFilterButton];
    [self.headerView addSubview:self.refreshButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.headerView.heightAnchor constraintEqualToConstant:56.0],

        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor constant:12.0],
        [self.searchBar.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.markFilterButton.leadingAnchor constant:-12.0],

        [self.markFilterButton.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [self.markFilterButton.trailingAnchor constraintEqualToAnchor:self.refreshButton.leadingAnchor constant:-16.0],

        [self.refreshButton.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [self.refreshButton.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor constant:-20.0],
    ]];
}

- (UIButton *)toolbarButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorNamed:ACColorNameMLKLightBlue] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

- (void)setupCollectionView {
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    configuration.showsSeparators = NO;

    UICollectionViewCompositionalLayout *layout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];

    self.mainCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.mainCollectionView.backgroundColor = [ASPFunctions colorFromHex:@"F2F2F2"];
    self.mainCollectionView.dataSource = self;
    self.mainCollectionView.delegate = self;
    self.mainCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainCollectionView registerClass:CDSecondaryAvailablePromosCollectionViewCell.class forCellWithReuseIdentifier:NSStringFromClass(CDSecondaryAvailablePromosCollectionViewCell.class)];

    [self.view addSubview:self.mainCollectionView];
    [NSLayoutConstraint activateConstraints:@[
        [self.mainCollectionView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
        [self.mainCollectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mainCollectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mainCollectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupEmptyState {
    self.emptyLabel = [UILabel new];
    self.emptyLabel.text = @"Нет доступных акций";
    self.emptyLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    self.emptyLabel.font = [UIFont systemFontOfSize:17.0];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.emptyLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.mainCollectionView.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.mainCollectionView.centerYAnchor],
    ]];
}

#pragma mark - Networking
- (void)getAvailablePromos {
    if (self.custAccount.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"Не указан клиент"];
        return;
    }

    [SVProgressHUD showWithStatus:@"Получаем акции..."];

    __weak typeof(self) weakSelf = self;
    [APIWorker.sharedInstance getAvailablePromos:self.custAccount completion:^(NSArray * _Nullable promotions, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }

        [SVProgressHUD dismiss];

        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
            strongSelf.allPromotions = @[];
            [strongSelf applyFilters];
            return;
        }

        strongSelf.allPromotions = promotions ?: @[];
        [strongSelf applyFilters];
    }];
}

#pragma mark - Filtering
- (void)applyFilters {
    NSPredicate *queryPredicate;
    if (self.searchQuery.length > 0) {
        NSString *query = self.searchQuery;
        queryPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary * _Nullable promo, NSDictionary<NSString *,id> * _Nullable bindings) {
            NSString *name = [promo[@"name"] isKindOfClass:NSString.class] ? promo[@"name"] : @"";
            NSString *mark = [promo[@"mark"] isKindOfClass:NSString.class] ? promo[@"mark"] : @"";
            return [name localizedCaseInsensitiveContainsString:query] ||
                   [mark localizedCaseInsensitiveContainsString:query];
        }];
    }

    NSPredicate *markPredicate;
    if (self.selectedMark.length > 0) {
        markPredicate = [NSPredicate predicateWithFormat:@"mark == %@", self.selectedMark];
    }

    NSArray *result = self.allPromotions;
    if (queryPredicate) { result = [result filteredArrayUsingPredicate:queryPredicate]; }
    if (markPredicate) { result = [result filteredArrayUsingPredicate:markPredicate]; }

    self.filteredPromotions = result;
    [self.mainCollectionView reloadData];

    self.emptyLabel.hidden = result.count > 0;

    NSString *markTitle = self.selectedMark.length > 0 ? [NSString stringWithFormat:@"Марка: %@", self.selectedMark] : @"Марка";
    [self.markFilterButton setTitle:markTitle forState:UIControlStateNormal];
}

#pragma mark - Actions
- (void)refreshButtonTapped {
    [self getAvailablePromos];
}

- (void)markFilterButtonTapped {
    NSMutableSet *marksSet = [NSMutableSet new];
    for (NSDictionary *promo in self.allPromotions) {
        NSString *mark = promo[@"mark"];
        if ([mark isKindOfClass:NSString.class] && mark.length > 0) {
            [marksSet addObject:mark];
        }
    }
    NSArray *marks = [marksSet.allObjects sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Фильтр по марке" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Все марки" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.selectedMark = nil;
        [self applyFilters];
    }]];

    for (NSString *mark in marks) {
        [sheet addAction:[UIAlertAction actionWithTitle:mark style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.selectedMark = mark;
            [self applyFilters];
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];

    sheet.popoverPresentationController.sourceView = self.markFilterButton;
    sheet.popoverPresentationController.sourceRect = self.markFilterButton.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchQuery = searchText;
    [self applyFilters];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredPromotions.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDSecondaryAvailablePromosCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CDSecondaryAvailablePromosCollectionViewCell.class) forIndexPath:indexPath];
    cell.delegate = self;
    [cell setPromo:self.filteredPromotions[indexPath.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - CDSecondaryAvailablePromosCollectionViewCellDelegate
- (void)availablePromosCellDidTapDetails:(CDSecondaryAvailablePromosCollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.mainCollectionView indexPathForCell:cell];
    if (!indexPath) { return; }

    NSDictionary *promo = self.filteredPromotions[indexPath.item];
    NSString *link = [promo[@"link"] isKindOfClass:NSString.class] ? promo[@"link"] : nil;
    NSURL *url = link.length > 0 ? [NSURL URLWithString:link] : nil;

    if (url && [UIApplication.sharedApplication canOpenURL:url]) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    } else {
        [SVProgressHUD showErrorWithStatus:@"Не удалось открыть ссылку"];
    }
}

@end
