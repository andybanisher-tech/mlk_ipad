//
//  CDSecondaryAvailablePromosCollectionViewCell.m
//  MLK
//

#import "CDSecondaryAvailablePromosCollectionViewCell.h"

#import "GeneratedAssetSymbols.h"

@interface CDSecondaryAvailablePromosCollectionViewCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *markLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *detailsButton;
@property (nonatomic, strong) UIImageView *promoImageView;

@property (nonatomic, copy) NSString *currentImageURLString;

@end

@implementation CDSecondaryAvailablePromosCollectionViewCell

+ (NSCache<NSString *, UIImage *> *)imageCache {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSCache new];
        cache.countLimit = 100;
    });
    return cache;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.contentView.backgroundColor = UIColor.whiteColor;

    self.nameLabel = [UILabel new];
    self.nameLabel.font = [UIFont boldSystemFontOfSize:17.0];
    self.nameLabel.textColor = [UIColor colorWithWhite:0.31 alpha:1.0];
    self.nameLabel.numberOfLines = 0;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.markLabel = [UILabel new];
    self.markLabel.font = [UIFont systemFontOfSize:15.0];
    self.markLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
    self.markLabel.numberOfLines = 1;
    self.markLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.dateLabel = [UILabel new];
    self.dateLabel.font = [UIFont systemFontOfSize:14.0];
    self.dateLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.detailsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.detailsButton setTitle:@"Подробнее" forState:UIControlStateNormal];
    [self.detailsButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.detailsButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    self.detailsButton.backgroundColor = [UIColor colorNamed:ACColorNameMLKLightBlue];
    self.detailsButton.layer.cornerRadius = 6.0;
    self.detailsButton.contentEdgeInsets = UIEdgeInsetsMake(6.0, 14.0, 6.0, 14.0);
    self.detailsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.detailsButton addTarget:self action:@selector(detailsButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    self.promoImageView = [UIImageView new];
    self.promoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.promoImageView.clipsToBounds = YES;
    self.promoImageView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.markLabel];
    [self.contentView addSubview:self.dateLabel];
    [self.contentView addSubview:self.detailsButton];
    [self.contentView addSubview:self.promoImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.promoImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
        [self.promoImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12.0],
        [self.promoImageView.widthAnchor constraintEqualToConstant:220.0],
        [self.promoImageView.heightAnchor constraintEqualToConstant:140.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.promoImageView.leadingAnchor constant:-12.0],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:14.0],

        [self.markLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.markLabel.trailingAnchor constraintEqualToAnchor:self.nameLabel.trailingAnchor],
        [self.markLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:12.0],

        [self.dateLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.dateLabel.trailingAnchor constraintEqualToAnchor:self.nameLabel.trailingAnchor],
        [self.dateLabel.topAnchor constraintEqualToAnchor:self.markLabel.bottomAnchor constant:8.0],

        [self.detailsButton.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.detailsButton.topAnchor constraintEqualToAnchor:self.dateLabel.bottomAnchor constant:12.0],

        // Растим contentView под максимум высоты картинки и блока с текстом+кнопкой
        [self.contentView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.promoImageView.bottomAnchor constant:12.0],
        [self.contentView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.detailsButton.bottomAnchor constant:14.0],
    ]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.promoImageView.image = nil;
    self.currentImageURLString = nil;
}

- (void)setPromo:(NSDictionary *)promo {
    self.nameLabel.text = [self stringValue:promo[@"name"]];
    self.markLabel.text = [NSString stringWithFormat:@"Марка: %@", [self stringValue:promo[@"mark"]]];

    NSString *dateTo = [self stringValue:promo[@"date_to"]];
    NSString *trimmedDate = [[dateTo componentsSeparatedByString:@" "] firstObject] ?: dateTo;
    self.dateLabel.text = trimmedDate.length > 0 ? [NSString stringWithFormat:@"до %@", trimmedDate] : @"";

    [self loadImageFromURL:[self stringValue:promo[@"image"]]];
}

- (NSString *)stringValue:(id)value {
    return [value isKindOfClass:NSString.class] ? value : @"";
}

- (void)loadImageFromURL:(NSString *)urlString {
    if (urlString.length == 0) {
        return;
    }
    self.currentImageURLString = urlString;

    UIImage *cached = [[self.class imageCache] objectForKey:urlString];
    if (cached) {
        self.promoImageView.image = cached;
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) { return; }

    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!data) { return; }
        UIImage *image = [UIImage imageWithData:data];
        if (!image) { return; }

        [[self.class imageCache] setObject:image forKey:urlString];

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.currentImageURLString isEqualToString:urlString]) {
                self.promoImageView.image = image;
            }
        });
    }];
    [task resume];
}

- (void)detailsButtonTapped {
    [self.delegate availablePromosCellDidTapDetails:self];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
}

@end
