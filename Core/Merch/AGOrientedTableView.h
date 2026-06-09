enum{
    kAGTableViewOrientationVertical = 0,
    kAGTableViewOrientationHorizontal
};
typedef NSUInteger AGTableViewOrientation;

@interface AGOrientedTableView : UITableView <UITableViewDataSource, UITableViewDelegate> {
@private
    id<UITableViewDataSource> _orientedTableViewDataSource;
    AGTableViewOrientation _tableViewOrientation;
}

@property (nonatomic, assign) AGTableViewOrientation tableViewOrientation;
@property (nonatomic, strong) id<UITableViewDataSource> orientedTableViewDataSource;

@end
