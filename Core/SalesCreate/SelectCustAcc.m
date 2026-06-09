//
//  SelectCustAcc.m
//  MLK
//
//  Created by Rustem Galyamov on 27.10.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SelectCustAcc.h"
#import "OverlaySelectCustAcc.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@implementation SelectCustAcc

@synthesize searchBar;
@synthesize custDetList, custList, custAccList;
@synthesize delegate;
@synthesize isViewPushed;
@synthesize fcity, cityArray, fkey, keyArray, fmark, markArray, fday;
@synthesize cityBtn, markBtn, keyBtn, dayBtn;

@synthesize i;

#pragma mark - View lifecycle
#define TableViewTag 8888

- (void)loadView{
    [super loadView];
    
    [self selectAllCustomers];
    
    if (isViewPushed == NO) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        
        self.navigationItem.rightBarButtonItem = barButton;
    }
    
    //NavBar Setup
    self.navigationItem.title = @"Список клиентов";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    // create a standard "refresh" button
    RWBorderedButton *showCityButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Регион"];
    [showCityButton addTarget:self
                       action:@selector(showCity:)
             forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *city = [[UIBarButtonItem alloc] initWithCustomView:showCityButton];
    self.cityBtn = city;
    
    RWBorderedButton *showDreamButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Статус"];
    [showDreamButton addTarget:self
                        action:@selector(showDream:)
              forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *custkey = [[UIBarButtonItem alloc] initWithCustomView:showDreamButton];
    self.keyBtn = custkey;
    
    RWBorderedButton *showBrandButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Марка"];
    [showBrandButton addTarget:self
                        action:@selector(showBrand:)
              forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *mark = [[UIBarButtonItem alloc] initWithCustomView:showBrandButton];
    self.markBtn = mark;
    
    self.navigationItem.leftBarButtonItems = @[city, custkey, mark];
    
    self.view.backgroundColor = UIColor.clearColor;
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width,1.f/UIScreen.mainScreen.scale)];
    [titleView setBackgroundColor:[UIColor blackColor]];

    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];
    [self.view addSubview:bgImage];
    
    bgImage.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[bgImage.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [bgImage.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [bgImage.topAnchor constraintEqualToAnchor:self.view.topAnchor],
       [bgImage.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    
    //SearchBar
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 1024.0, 40.0)];
    searchBar.delegate = self;
    searchBar.barTintColor = [UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1];
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.tintColor = [UIColor blackColor];
    searchBar.placeholder = @"Поиск";
    searchBar.searchTextField.backgroundColor = UIColor.whiteColor;
    
    searching        = NO;
    letUserSelectRow = YES;
    searchBar.layer.borderWidth = 1;
    
    searchBar.layer.borderColor = [[UIColor colorWithRed:62.0/255.0 green:63.0/255.0 blue:64.0/255.0 alpha:1] CGColor];
    
    [self.view addSubview:searchBar];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:
     @[[searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [searchBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor]]];
    
    myTableView = [[UITableView alloc]initWithFrame:CGRectMake(0.0, 84.0, 1024.0, 650.0)];
    
    myTableView.delegate = self;
    myTableView.dataSource = self;
    
    myTableView.separatorColor = UIColor.clearColor;
    myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [myTableView setBackgroundColor:UIColor.clearColor];
    
    [self.view addSubview:myTableView];
    myTableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:
     @[[myTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
       [myTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
       [myTableView.topAnchor constraintEqualToAnchor:searchBar.bottomAnchor],
       [myTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
}

- (void)selectAllCustomers {
    custList            = [NSMutableArray new];
    custsToLiveInArray  = [NSMutableArray array];
    
    custDetList          = [NSMutableArray new];
    custDetToLiveInArray = [NSMutableArray array];
    
    custAccList          = [NSMutableArray new];
    custAccToLiveInArray = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select CustAccount, Name, FactAddress, Phone from CustTable order by Name asc";
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc   = @"null";
                NSString *custName  = @"null";
                NSString *custAddr  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                [custsToLiveInArray   addObject:custName];
                [custDetToLiveInArray addObject:custAddr];
                [custAccToLiveInArray addObject:custAcc];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    NSDictionary *custsToLiveInDict    = [NSDictionary dictionaryWithObject:custsToLiveInArray forKey:@"CustName"];
    NSDictionary *custsDetToLiveInDict = [NSDictionary dictionaryWithObject:custDetToLiveInArray forKey:@"CustAddr"];
    NSDictionary *custsAccToLiveInDict = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    
    [custList    addObject:custsToLiveInDict];
    [custDetList addObject:custsDetToLiveInDict];
    [custAccList addObject:custsAccToLiveInDict];
    
    copyCustList    = [NSMutableArray new];
    copyCustDetList = [NSMutableArray new];
    copyCustAccList = [NSMutableArray new];
    
}

- (void)selectWithFilters {
    custList            = [NSMutableArray new];
    custsToLiveInArray  = [NSMutableArray array];
    
    custDetList          = [NSMutableArray new];
    custDetToLiveInArray = [NSMutableArray array];
    
    custAccList          = [NSMutableArray new];
    custAccToLiveInArray = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = nil;
        
        NSString *squl = @"select CustAccount, Name, FactAddress, Phone from CustTable where 1=1";
        
        if (fkey) {
            squl = [NSString stringWithFormat:@"%@ and exists(select * from CustStatusDN where CustTable.CustAccount == CustStatusDN.CustAccount and %@)", squl, fkey];
        }
        if (fcity) {
            squl = [NSString stringWithFormat:@"%@ and %@", squl, fcity];
        }
        if (fmark) {
            squl = [NSString stringWithFormat:@"%@ and exists(select * from PersonalPriceList where CustTable.CustAccount == PersonalPriceList.CustAccount and PersonalPriceList.Active = '1' and %@)", squl, fmark];
        }
        if (fday) {
            squl = [NSString stringWithFormat:@"%@ and LVDateComp > '%@'", squl, fday];
        }
        
        squl = [NSString stringWithFormat:@"%@ order by Name", squl];
        sql = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            if (fcity)
                sqlite3_bind_text(selectstmt, 1, [fcity UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSString *custAcc   = @"null";
                NSString *custName  = @"null";
                NSString *custAddr  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    custAcc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    custAddr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                [custsToLiveInArray   addObject:custName];
                [custDetToLiveInArray addObject:custAddr];
                [custAccToLiveInArray addObject:custAcc];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    NSLog(@"rrrr");
    
    NSDictionary *custsToLiveInDict    = [NSDictionary dictionaryWithObject:custsToLiveInArray forKey:@"CustName"];
    NSDictionary *custsDetToLiveInDict = [NSDictionary dictionaryWithObject:custDetToLiveInArray forKey:@"CustAddr"];
    NSDictionary *custsAccToLiveInDict = [NSDictionary dictionaryWithObject:custAccToLiveInArray forKey:@"CustAcc"];
    
    [custList    addObject:custsToLiveInDict];
    [custDetList addObject:custsDetToLiveInDict];
    [custAccList addObject:custsAccToLiveInDict];
    
    copyCustList    = [NSMutableArray new];
    copyCustDetList = [NSMutableArray new];
    copyCustAccList = [NSMutableArray new];
}


- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //UIColor *mycolor= [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:128.0/255.0 alpha:1.0];
    cell.backgroundColor = [ASPFunctions colorFromHex:@"f1f1f1"];
    
}

- (void)showCity:(id)sender {
    if (self.presentedViewController) { return; }
    
    CustCity *custCity = [CustCity new];
    custCity.delegate = self;
    custCity.selected = cityArray;
    
    custCity.modalPresentationStyle = UIModalPresentationPopover;
    custCity.popoverPresentationController.barButtonItem = cityBtn;
    
    [self presentViewController:custCity animated:YES completion:nil];
}

- (void)showBrand:(id)sender {
    if (self.presentedViewController) { return; }
    
    CustBrand *custBrand = [CustBrand new];
    custBrand.delegate = self;
    custBrand.selected = markArray;
    
    custBrand.modalPresentationStyle = UIModalPresentationPopover;
    custBrand.popoverPresentationController.barButtonItem = markBtn;
    
    [self presentViewController:custBrand animated:YES completion:nil];
}


- (void)showDream:(id)sender {
    if (self.presentedViewController) { return; }
    
    CustDream *custDream = [CustDream new];
    custDream.delegate = self;
    custDream.selected = keyArray;
    
    custDream.modalPresentationStyle = UIModalPresentationPopover;
    custDream.popoverPresentationController.barButtonItem = keyBtn;
    
    [self presentViewController:custDream animated:YES completion:nil];
}

- (void)userDidSelectCities:(NSMutableArray *)cities {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    cityArray = [cities copy];
    
    NSString *squl;
    for (NSString *city in cityArray) {
        if ([city isEqualToString:cityArray.firstObject]) {
            squl = [NSString stringWithFormat:@"City = '%@'", city];
        } else {
            squl = [NSString stringWithFormat:@"%@ or City = '%@'", squl, city];
        }
    }
    
    fcity = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    [self selectWithFilters];
    [myTableView reloadData];
    
    [self setBarButton:cityBtn highlighted:fcity != nil];
}

- (void)userDidSelectBrand:(NSMutableArray *)brandArray{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    markArray = [brandArray copy];
    
    NSArray *array = [brandArray copy];
    NSString *squl;
    int counter;
    
    for(counter = 0; counter < [array count]; counter++) {
        if (counter == 0) {
            squl = [NSString stringWithFormat:@"BrandId = '%@'", [array objectAtIndex:counter]];
        } else {
            squl = [NSString stringWithFormat:@"%@ or BrandId = '%@'", squl, [array objectAtIndex:counter]];
        }
    }
    
    fmark = [NSString stringWithFormat:@"(%@)",squl];
    
    [self selectWithFilters];
    [myTableView reloadData];
    
    [self setBarButton:markBtn highlighted:fmark != nil];
}

- (void)userDidSelectDream:(NSMutableArray *)dreamArray{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    keyArray = [dreamArray copy];
    
    NSString *squl;
    for (NSString *dream in dreamArray) {
        if ([dream isEqualToString:cityArray.firstObject]) {
            squl = [NSString stringWithFormat:@"StatusDN = '%@'", dream];
        } else {
            squl = [NSString stringWithFormat:@"%@ or StatusDN = '%@'", squl, dream];
        }
    }
    
    fkey = squl.length > 0 ? [NSString stringWithFormat:@"(%@)", squl] : nil;
    
    [self selectWithFilters];
    [myTableView reloadData];
    
    [self setBarButton:keyBtn highlighted:fkey != nil];
}

- (void)selectBrand:(NSString *)brand {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (!brand)
        markArray = nil;
    
    fmark = brand;
    
    [self selectWithFilters];
    [myTableView reloadData];
    
    [self setBarButton:markBtn highlighted:fmark != nil];
}

- (void)selectDay:(id)sender {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self visitDay:sender];
    
    dayBtn = sender;
    
    UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
    [dayBtn setTintColor:color];
    
}

-(IBAction)visitDay:(id)sender {
    [AlertWorkerObjc actionSheetWithTitle:nil message:nil sourceView:sender buttons:@[@"Неделя", @"Месяц",  @"Квартал", @"Полугодие", @"Задать", @"Убрать фильтр"] tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if ([action.title isEqual:@"Убрать фильтр"]) {
            self->fday = nil;
            [self selectWithFilters];
            [self->myTableView reloadData];
            
            [self->dayBtn setTintColor:UIColor.clearColor];
        } else {
            if ([action.title isEqual:@"Неделя"]) {
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*7];
                
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                self->fday = [dateFormatter stringFromDate:dateY];
                
                [self selectWithFilters];
                [self->myTableView reloadData];
            }
            
            if ([action.title isEqual:@"Месяц"]) {
                
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*30];
                
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                self->fday = [dateFormatter stringFromDate:dateY];
                
                [self selectWithFilters];
                [self->myTableView reloadData];
            }
            
            if ([action.title isEqual:@"Квартал"]) {
                
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*90];
                
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                self->fday = [dateFormatter stringFromDate:dateY];
                
                [self selectWithFilters];
                [self->myTableView reloadData];
            }
            
            if ([action.title isEqual:@"Полугодие"]) {
                
                NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*180];
                NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                
                self->fday = [dateFormatter stringFromDate:dateY];
                
                [self selectWithFilters];
                [self->myTableView reloadData];
            }
            
            if ([action.title isEqual:@"Задать"]) {
                UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"Введите кол-во дней"  message:@"дни визита" preferredStyle:UIAlertControllerStyleAlert];
                
                
                [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.keyboardType = UIKeyboardTypePhonePad;
                    [textField becomeFirstResponder];
                }];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    NSDate *dateY = [NSDate dateWithTimeIntervalSinceNow:-86400*[alertVC.textFields.firstObject.text doubleValue]];
                    
                    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
                    
                    self->fday = [dateFormatter stringFromDate:dateY];
                    
                    [self selectWithFilters];
                    [self->myTableView reloadData];
                }];
                
                [alertVC addAction:okAction];
                
                [self presentViewController:alertVC animated:YES completion:nil];
            }
        }
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (void)clearFilter {
    NSString *searchText = searchBar.text;
    
    fcity = nil;
    fkey  = nil;
    fmark = nil;
    fday  = nil;
    
    [cityBtn setTintColor:UIColor.clearColor];
    [markBtn setTintColor:UIColor.clearColor];
    [keyBtn  setTintColor:UIColor.clearColor];
    [dayBtn  setTintColor:UIColor.clearColor];
    
    [self selectAllCustomers];
    [myTableView reloadData];
    
    searchBar.text = searchText;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    if (searching) {
        return 1;
    } else {
        return [custList count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (searching) {
        return [copyCustList count];
    } else {
        //Number of rows it should expect should be based on the section
        NSDictionary *dictionary = [custList objectAtIndex:section];
        NSArray		 *array = [dictionary objectForKey:@"CustName"];
        
        return [array count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (searching) {
        return @"Результаты поиска";
    } else {
        return @"Клиенты";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(
                                                                      0,
                                                                      55.f - 1.f/UIScreen.mainScreen.scale,
                                                                      CGRectGetWidth(tableView.frame),
                                                                      1.f/UIScreen.mainScreen.scale)
                              ];
        [bottomLine setBackgroundColor:[UIColor blackColor]];
        [cell addSubview:bottomLine];
        
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,10,CGRectGetWidth(tableView.frame)-20,20)];
        textLabel.tag = 111;
        textLabel.font = [UIFont systemFontOfSize:17.f];
        textLabel.textColor = [UIColor blackColor];
        [cell addSubview:textLabel];
        
        UILabel *detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,30,CGRectGetWidth(tableView.frame)-20,20)];
        detailTextLabel.tag = 222;
        detailTextLabel.font = [UIFont systemFontOfSize:17.f];
        detailTextLabel.textColor = [ASPFunctions colorFromHex:@"b4b8bb"];
        [cell addSubview:detailTextLabel];
        
        /*cell.textLabel.font = [UIFont systemFontOfSize:17.f];
         cell.detailTextLabel.font = [UIFont systemFontOfSize:17.f];
         
         cell.textLabel.textColor = [UIColor blackColor];
         cell.detailTextLabel.textColor = [ASPFunctions colorFromHex:@"b4b8bb"];*/
    }
    
    UILabel *uiLabel = [cell viewWithTag:111];
    UILabel *detailTextLabel = [cell viewWithTag:222];
    if (searching) {
        if ([copyCustList count] > 0) {
            NSString *cellValue	   = [copyCustList objectAtIndex:indexPath.row];
            
            NSString *cellValueDet = [copyCustDetList objectAtIndex:indexPath.row];
            
            uiLabel.text = cellValue;
            detailTextLabel.text = cellValueDet;
        }
    } else {
        NSDictionary	*dictionary = [custList objectAtIndex:indexPath.section];
        NSArray			*array		= [dictionary objectForKey:@"CustName"];
        NSString		*cellValue	= [array objectAtIndex:indexPath.row];
        
        NSDictionary	*dictionaryDet  = [custDetList objectAtIndex:indexPath.section];
        NSArray			*arrayDet		= [dictionaryDet objectForKey:@"CustAddr"];
        NSString		*cellValueDet	= [arrayDet objectAtIndex:indexPath.row];
        
        uiLabel.text       = [NSString stringWithFormat:@" %@", cellValue];
        detailTextLabel.text = [NSString stringWithFormat:@" %@", cellValueDet];
    }
    
    return cell;
}


#pragma mark -
#pragma mark Search Bar 

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
    //This method is called again when the user clicks back from teh detail view.
    //So the overlay is displayed on the results, which is something we do not want to happen.
    if (searching)
        return;
    
    //Add the overlay view.
    if (ovController == nil)
        ovController = [[OverlaySelectCustAcc alloc] initWithNibName:@"OverlaySelectCustAcc" bundle:NSBundle.mainBundle];
    
    CGFloat width = 1024;
    CGFloat height = 65000;
    
    //Parameters x = origion on x-axis, y = origon on y-axis.
    CGRect frame = CGRectMake(0, 0, width, height);
    ovController.view.frame = frame;
    ovController.view.backgroundColor = [UIColor grayColor];
    ovController.view.alpha = 0.5;
    
    ovController.rvController = self;
    
    [myTableView insertSubview:ovController.view aboveSubview:self.parentViewController.view];
    
    searching = YES;
    letUserSelectRow = NO;
    myTableView.scrollEnabled = NO;
    
    //Add the done button.
    RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Готово"];
    [closeButton addTarget:self
                    action:@selector(doneSearching_Clicked:)
          forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    
    self.navigationItem.rightBarButtonItem = barButton;
    /*self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemDone
     target:self action:@selector(doneSearching_Clicked:)];*/
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
    
    //Remove all objects first.
    [copyCustList removeAllObjects];
    [copyCustAccList removeAllObjects];
    [copyCustDetList removeAllObjects];
    
    if ([searchText length] > 0) {
        [ovController.view removeFromSuperview];
        searching = YES;
        letUserSelectRow = YES;
        myTableView.scrollEnabled = YES;
        [self searchTableView];
    } else {
        CGFloat width = 1024;
        CGFloat height = 65000;
        
        //Parameters x = origion on x-axis, y = origon on y-axis.
        CGRect frame = CGRectMake(0, 80, width, height);
        
        ovController.view.frame = frame;
        
        [self.view insertSubview:ovController.view aboveSubview:self.parentViewController.view];
        
        searching = NO;
        letUserSelectRow = NO;
        myTableView.scrollEnabled = NO;
    }
    
    [myTableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [self searchTableView];
}

- (void) searchTableView {
    NSString *searchText = searchBar.text;
    NSMutableArray *searchArray        = [NSMutableArray new];
    NSMutableArray *searchArrayDet     = [NSMutableArray new];
    NSMutableArray *searchArrayCustAcc = [NSMutableArray new];
    
    for (NSDictionary *dictionary in custList) {
        NSArray *array = [dictionary objectForKey:@"CustName"];
        [searchArray addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictDetail in custDetList) {
        NSArray *array = [dictDetail objectForKey:@"CustAddr"];
        [searchArrayDet addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictCustAcc in custAccList) {
        NSArray *array = [dictCustAcc objectForKey:@"CustAcc"];
        [searchArrayCustAcc addObjectsFromArray:array];
    }
    
    for (NSString *sTemp in searchArray) {
        i = i + 1;
        
        NSRange titleResultsRange = [sTemp rangeOfString:searchText options:NSCaseInsensitiveSearch];
        
        if (titleResultsRange.length > 0) {
            [copyCustList    addObject:sTemp];
            [copyCustDetList addObject:[searchArrayDet objectAtIndex:i - 1]];
            [copyCustAccList addObject:[searchArrayCustAcc objectAtIndex:i - 1]];
        }
        
    }
    
    i = 0;
    
    for (NSString *sTemp in searchArrayDet) {
        i = i + 1;
        
        NSRange titleResultsRange = [sTemp rangeOfString:searchText options:NSCaseInsensitiveSearch];
        
        if (titleResultsRange.length > 0) {
            [copyCustList    addObject:[searchArray objectAtIndex:i - 1]];
            [copyCustDetList addObject:sTemp];
            [copyCustAccList addObject:[searchArrayCustAcc objectAtIndex:i - 1]];
        }
        
    }
    
    i = 0;
    
    searchArray = nil;
    
    searchArrayDet = nil;
    
    searchArrayCustAcc = nil;
    
}

- (void)doneSearching_Clicked:(id)sender {
    
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    
    letUserSelectRow = YES;
    searching = NO;
    self.navigationItem.rightBarButtonItem = nil;
    myTableView.scrollEnabled = YES;
    
    [ovController.view removeFromSuperview];
    ovController = nil;
    
    if (isViewPushed == NO) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        
        self.navigationItem.rightBarButtonItem = barButton;
    }
    
    [myTableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {	
    NSString *custAccout;
    NSString *custName;
    
    if (searching) {
        custName                 = [copyCustList objectAtIndex:indexPath.row];
        custAccout               = [copyCustAccList objectAtIndex:indexPath.row];
    } else {
        NSDictionary *dictionary  = [custList objectAtIndex:indexPath.section];
        NSArray      *array       = [dictionary objectForKey:@"CustName"];
        
        custName                         = [array objectAtIndex:indexPath.row];
        
        NSDictionary *dictCustAcc  = [custAccList objectAtIndex:indexPath.section];
        NSArray      *arrayCustAcc = [dictCustAcc objectForKey:@"CustAcc"];
        
        custAccout                 = [arrayCustAcc objectAtIndex:indexPath.row];
    }
    
    [self.delegate custIsSelected:custAccout custName:custName];
    [self dismissViewControllerAnimated:YES completion:nil];
}


+ (void)finalizeStatements {
    if (database)
        sqlite3_close(database);
}

- (void)scrollToTop{
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [myTableView selectRowAtIndexPath:topIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

#pragma mark -
#pragma mark Managing the popover

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Button styling methods
- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}

@end
