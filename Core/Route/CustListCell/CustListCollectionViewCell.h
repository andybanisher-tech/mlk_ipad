//
//  CustListCollectionViewCell.h
//  MLK
//
//  Modern list cell for the customers list. Reproduces the legacy cell
//  visuals: name (with ❗ for PDZ), address, send-status pill, last sale
//  date pill, tasks-count badge and visit-plan highlighting.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CustListCollectionViewCell;

@protocol CustListCollectionViewCellDelegate <NSObject>
- (void)custListCellDidTapResend:(CustListCollectionViewCell *)cell;
@end

@interface CustListCollectionViewCell : UICollectionViewListCell

@property (nonatomic, weak) id<CustListCollectionViewCellDelegate> cellDelegate;

- (void)configureWithName:(NSString *)name
                  address:(NSString *)address
                  hasPDZ:(BOOL)hasPDZ
               sendStatus:(nullable NSString *)sendStatus
                taskCount:(NSInteger)taskCount
            lastSalesDate:(nullable NSString *)lastSalesDate
            isLastSalesTP:(BOOL)isLastSalesTP
              visitPlan:(BOOL)visitPlan
              visitState:(NSInteger)visitState; // 0 none, 1 visited(green), 2 visit(blue)

@end

NS_ASSUME_NONNULL_END
