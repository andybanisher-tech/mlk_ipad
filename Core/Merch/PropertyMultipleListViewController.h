//
//  PropertyMultipleListViewController.h
//  MLK
//
//  Created by Alex B on 13.07.15.
//

#import "UIKit/UIKit.h"
#import "sqlite3.h"
#import "PropertyListAbstractController.h"

@interface PropertyMultipleListViewController : PropertyListAbstractController <UITableViewDelegate,UITableViewDataSource> {
    id setBtn;
    NSMutableDictionary *selectedCollection;
}

@property(nonatomic,retain)id setBtn;
@property(nonatomic,retain)NSMutableDictionary *selectedCollection;

- (void)createList;
- (void)refreshData;

@end
