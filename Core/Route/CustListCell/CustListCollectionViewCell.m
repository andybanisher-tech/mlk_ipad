//
//  CustListCollectionViewCell.m
//  MLK
//

#import "CustListCollectionViewCell.h"

@interface CustListCollectionViewCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *addressLabel;

@property (nonatomic, strong) UILabel *taskBadge;
@property (nonatomic, strong) UIButton *sendStatusButton;
@property (nonatomic, strong) UILabel *salesDateLabel;

@end

@implementation CustListCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    UIColor *textColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];

    self.nameLabel = [UILabel new];
    self.nameLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = textColor;
    self.nameLabel.numberOfLines = 1;
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    self.addressLabel = [UILabel new];
    self.addressLabel.font = [UIFont systemFontOfSize:14.0];
    self.addressLabel.textColor = UIColor.systemGrayColor;
    self.addressLabel.numberOfLines = 1;
    self.addressLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.nameLabel, self.addressLabel]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 2.0;
    textStack.alignment = UIStackViewAlignmentLeading;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;
    [textStack setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [textStack setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    // Task count badge (fixed, square-ish)
    self.taskBadge = [UILabel new];
    self.taskBadge.font = [UIFont boldSystemFontOfSize:15.0];
    self.taskBadge.textColor = UIColor.whiteColor;
    self.taskBadge.textAlignment = NSTextAlignmentCenter;
    self.taskBadge.backgroundColor = UIColor.darkGrayColor;
    self.taskBadge.layer.cornerRadius = 6.0;
    self.taskBadge.clipsToBounds = YES;
    self.taskBadge.translatesAutoresizingMaskIntoConstraints = NO;

    // Last sales date pill (fixed)
    self.salesDateLabel = [UILabel new];
    self.salesDateLabel.font = [UIFont systemFontOfSize:14.0];
    self.salesDateLabel.textAlignment = NSTextAlignmentCenter;
    self.salesDateLabel.layer.cornerRadius = 6.0;
    self.salesDateLabel.clipsToBounds = YES;
    self.salesDateLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // Send status pill (fixed)
    self.sendStatusButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendStatusButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    self.sendStatusButton.layer.cornerRadius = 6.0;
    self.sendStatusButton.clipsToBounds = YES;
    self.sendStatusButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendStatusButton addTarget:self action:@selector(resendTapped) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *trailingStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.salesDateLabel, self.sendStatusButton, self.taskBadge]];
    trailingStack.axis = UILayoutConstraintAxisHorizontal;
    trailingStack.spacing = 8.0;
    trailingStack.alignment = UIStackViewAlignmentCenter;
    trailingStack.translatesAutoresizingMaskIntoConstraints = NO;
    [trailingStack setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [trailingStack setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.contentView addSubview:textStack];
    [self.contentView addSubview:trailingStack];

    [NSLayoutConstraint activateConstraints:@[
        // Fixed accessory sizes — never stretch across the row
        [self.taskBadge.widthAnchor constraintEqualToConstant:42.0],
        [self.taskBadge.heightAnchor constraintEqualToConstant:34.0],
        [self.salesDateLabel.widthAnchor constraintEqualToConstant:130.0],
        [self.salesDateLabel.heightAnchor constraintEqualToConstant:34.0],
        [self.sendStatusButton.widthAnchor constraintEqualToConstant:150.0],
        [self.sendStatusButton.heightAnchor constraintEqualToConstant:34.0],

        // Text on the left
        [textStack.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor],
        [textStack.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor constant:8.0],
        [textStack.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

        // Accessories pinned right
        [trailingStack.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
        [trailingStack.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [trailingStack.leadingAnchor constraintGreaterThanOrEqualToAnchor:textStack.trailingAnchor constant:12.0],

        // Row height
        [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:56.0],
    ]];
}

- (void)resendTapped {
    [self.cellDelegate custListCellDidTapResend:self];
}

- (void)configureWithName:(NSString *)name
                  address:(NSString *)address
                  hasPDZ:(BOOL)hasPDZ
               sendStatus:(NSString *)sendStatus
                taskCount:(NSInteger)taskCount
            lastSalesDate:(NSString *)lastSalesDate
            isLastSalesTP:(BOOL)isLastSalesTP
              visitPlan:(BOOL)visitPlan
              visitState:(NSInteger)visitState {
    self.nameLabel.text = hasPDZ ? [NSString stringWithFormat:@"❗ %@", name] : name;

    BOOL emptyAddress = address.length == 0 || [address isEqualToString:@"null"];
    self.addressLabel.text = emptyAddress ? nil : address;
    self.addressLabel.hidden = emptyAddress;

    // Task badge
    if (taskCount > 0) {
        self.taskBadge.text = [NSString stringWithFormat:@"%ld", (long)taskCount];
        self.taskBadge.hidden = NO;
    } else {
        self.taskBadge.hidden = YES;
    }

    // Send status pill vs sales date pill (mutually exclusive, like legacy)
    BOOL hasSendStatus = sendStatus != nil && ![sendStatus isEqualToString:@"null"];
    if (hasSendStatus) {
        BOOL sent = [sendStatus isEqualToString:@"Sended"];
        [self.sendStatusButton setTitle:sent ? @"Отправлен" : @"Не отправлен" forState:UIControlStateNormal];
        [self.sendStatusButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.sendStatusButton.backgroundColor = sent ? [UIColor colorWithRed:0.49 green:0.91 blue:0.48 alpha:1.0] : UIColor.systemRedColor;
        self.sendStatusButton.userInteractionEnabled = !sent;
        self.sendStatusButton.hidden = NO;
        self.salesDateLabel.hidden = YES;
    } else {
        self.sendStatusButton.hidden = YES;
        if (lastSalesDate == nil || [lastSalesDate isEqualToString:@"null"]) {
            self.salesDateLabel.hidden = YES;
        } else {
            self.salesDateLabel.hidden = NO;
            self.salesDateLabel.text = lastSalesDate;
            if (isLastSalesTP) {
                self.salesDateLabel.backgroundColor = [UIColor colorWithRed:0.835 green:0.325 blue:0.325 alpha:1.0];
                self.salesDateLabel.textColor = UIColor.whiteColor;
            } else {
                self.salesDateLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
                self.salesDateLabel.textColor = UIColor.darkGrayColor;
            }
        }
    }

    // Route highlight: green = visited, blue = in today's route
    UIColor *bg = nil;
    if (visitState == 1) {
        bg = [UIColor colorWithRed:0.427 green:0.925 blue:0.561 alpha:1.0]; // green visited
    } else if (visitState == 2) {
        bg = [UIColor colorWithRed:0.392 green:0.584 blue:0.929 alpha:1.0]; // blue in route
    }

    UIBackgroundConfiguration *bgConfig = [UIBackgroundConfiguration listGroupedCellConfiguration];
    bgConfig.backgroundColor = bg ?: UIColor.whiteColor;
    self.backgroundConfiguration = bgConfig;
}

@end
