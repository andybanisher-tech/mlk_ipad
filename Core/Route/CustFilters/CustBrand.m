//
//  CustBrand.m
//  MLK
//
//  Created by Rustem Galyamov on 05.10.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "CustBrand.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

@implementation CustBrand

static sqlite3 *database = nil;

@synthesize brandList, brandIdList;
@synthesize delegate;
@synthesize visitPlan;
@synthesize addCust,brandSelected, selected, setBtn;

- (void)brandCreate {
    brandList             = [NSMutableArray new];
	brandToLiveInArray    = [NSMutableArray array];
    
    brandIdList           = [NSMutableArray new];
	brandIdToLiveInArray  = [NSMutableArray array];
    
    if (!brandSelected)
        brandSelected         = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (addCust)
            sql = "select BrandName, BrandId from BrandDop order by BrandName";
        else
            sql = "select BrandName, BrandId from Brand where exists(select * from PersonalPriceList where Brand.BrandId == PersonalPriceList.BrandId and PersonalPriceList.Active = '1') order by BrandName";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            //[brandToLiveInArray     addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				
                NSString *brand     = @"null";
                NSString *brandId   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    brand  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    brandId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [brandToLiveInArray     addObject:brand];
                [brandIdToLiveInArray   addObject:brandId];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *brandToLiveInDict     = [NSDictionary dictionaryWithObject:brandToLiveInArray forKey:@"Brand"];
    NSDictionary *brandIdToLiveInDict   = [NSDictionary dictionaryWithObject:brandIdToLiveInArray forKey:@"BrandId"];
    
    [brandList      addObject:brandToLiveInDict];
    [brandIdList    addObject:brandIdToLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self brandCreate];
    
    /*
    
    UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 250, 44)];
    
    NSMutableArray* btns = [[NSMutableArray alloc] initWithCapacity:3];
    
    UIBarButtonItem *custkey = [[[UIBarButtonItem alloc] initWithTitle:@"Очистить" style:UIBarButtonItemStyleDone target:self action:@selector(removeFilter:)] autorelease];
    
    [btns addObject:custkey];
    
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    [fixed setWidth:60.0f];
    [btns addObject:fixed];
    
    UIBarButtonItem *sourcekey = [[[UIBarButtonItem alloc] initWithTitle:@"Применить" style:UIBarButtonItemStyleDone target:self action:@selector(useFilter:)] autorelease];
    
    setBtn = sourcekey;
    
    [btns addObject:sourcekey];
    
    [sectionHead setItems:btns animated:NO];
    
    [btns release];
    
    sectionHead.tintColor = [UIColor blackColor];
    
    [self.view addSubview:sectionHead];
    [sectionHead release];
    
    [setBtn setEnabled:NO];*/
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.tableView.frame = CGRectMake(0, 0, 260, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 250, 44)];
    
    NSMutableArray* btns = [[NSMutableArray alloc] initWithCapacity:3];

    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,80,44)];
    [clearButton setTitle:@"Очистить" forState:UIControlStateNormal];
    [clearButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.f]];
    [clearButton setTitleColor:[UIColor colorNamed:ACColorNameMLKBlue] forState:UIControlStateNormal];
    [clearButton addTarget:self
                    action:@selector(removeFilter:)
          forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *custkey = [[UIBarButtonItem alloc] initWithCustomView:clearButton];
    [btns addObject:custkey];

    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];

    [fixed setWidth:45.0f];
    [btns addObject:fixed];

    UIButton *applyButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,100,44)];
    [applyButton setTitle:@"Применить" forState:UIControlStateNormal];
    [applyButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.f]];
    [applyButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [applyButton addTarget:self
                    action:@selector(useFilter:)
          forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *sourcekey = [[UIBarButtonItem alloc] initWithCustomView:applyButton];

    setBtn = sourcekey;

    [btns addObject:sourcekey];
    
    [sectionHead setItems:btns animated:NO];

    sectionHead.tintColor = [UIColor blackColor];
    [self enableApplyButton:[brandSelected count] > 0];
    return sectionHead;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}


- (void)removeFilter:(id)sender {
    if ([self.delegate respondsToSelector:@selector(userDidSelectBrand:)]) {
        [self.delegate userDidSelectBrand:nil];
    }
}

- (void)useFilter:(id)sender {
    if (brandSelected.count != 0) {
        if ([self.delegate respondsToSelector:@selector(userDidSelectBrand:)]) {
            [self.delegate userDidSelectBrand:brandSelected];
        }
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [brandList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [brandList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"Brand"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
	
    NSDictionary	*dictionary = [brandList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Brand"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    NSDictionary *dictionaryId  = [brandIdList objectAtIndex:indexPath.section];
    NSArray      *arrayId       = [dictionaryId objectForKey:@"BrandId"];
    NSString     *brandId	  = [arrayId objectAtIndex:indexPath.row];
    
    cell.textLabel.text	 	  = cellValue;
    
    cell.textLabel.textColor = [UIColor blackColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    if ([selected containsObject:brandId]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [brandSelected addObject:brandId];
    } else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([brandSelected containsObject:brandId]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    /*if (indexPath.row == 0)
        cell.backgroundColor = UIColor.lightGrayColor;*/
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	/*
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [brandIdList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"BrandId"];
    NSString     *brandId	  = [array objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0)
        [self.delegate selectBrand:nil];
    else
        [self.delegate selectBrand:brandId];
    */
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [brandIdList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"BrandId"];
    NSString     *brandId	  = [array objectAtIndex:indexPath.row];
    
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (currentCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        currentCell.accessoryType = UITableViewCellAccessoryNone;
        [brandSelected removeObject:brandId];
    } else {
        currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [brandSelected addObject:brandId];
    }

    [self enableApplyButton:[brandSelected count] > 0];
}

- (void)enableApplyButton:(BOOL)state {
    UIButton *customViewButton = ((UIBarButtonItem *) setBtn).customView;
    if (state) {
        [customViewButton setTitleColor:[UIColor colorNamed:ACColorNameMLKBlue] forState:UIControlStateNormal];
        [setBtn setEnabled:YES];
    } else {
        [customViewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [setBtn setEnabled:FALSE];
    }
}

+ (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}


@end
