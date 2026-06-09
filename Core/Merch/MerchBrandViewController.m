//
//  MerchBrandViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 24.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "MerchBrandViewController.h"

@implementation MerchBrandViewController

static sqlite3 *database = nil;

@synthesize brandList, brandIdList, brandInList;
@synthesize groupId, custAccount;
@synthesize delegate;

- (void)brandListCreate {
    brandList                            = [NSMutableArray new];
	NSMutableArray *brandToLiveInArray   = [NSMutableArray array];
    
    brandIdList                            = [NSMutableArray new];
	NSMutableArray *brandIdToLiveInArray   = [NSMutableArray array];
    
    brandInList                            = [NSMutableArray new];
	NSMutableArray *brandInToLiveInArray   = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select BrandId from MerchGroupBrands where GroupId = ? and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == MerchGroupBrands.BrandId and PersonalPriceList.Active = '1')";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            sqlite3_bind_text(selectstmt, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *brand = @"null";
                NSString *brandName = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    brand  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                const char *sql_2;
                
                sql_2 = "select BrandName from Brand where BrandId = ?";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(selstmt_2, 1, [brand UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW) 
                    {
                        
                        if (sqlite3_column_text(selstmt_2, 0))
                            brandName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                [brandToLiveInArray    addObject:brandName];
                [brandIdToLiveInArray  addObject:brand];
                [brandInToLiveInArray  addObject:@"in"];
            }
		}
        sqlite3_finalize(selectstmt);
        
        //const char *sqlIn = "select BrandId, BrandName from BrandMerch where 1 = 1 and exists(select * from MerchGroupBrands where MerchGroupBrands.BrandId == BrandMerch.BrandId and MerchGroupBrands.GroupId == ?) and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == BrandMerch.BrandId and PersonalPriceList.Active = '0')";
        
        const char *sqlIn = "select BrandId from MerchGroupBrands where GroupId = ? and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == MerchGroupBrands.BrandId and PersonalPriceList.Active = '0')";
        
        sqlite3_stmt *selectstmtIn;
		
		if (sqlite3_prepare_v2(database, sqlIn, -1, &selectstmtIn, NULL) == SQLITE_OK) 
		{
            sqlite3_bind_text(selectstmtIn, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmtIn, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmtIn) == SQLITE_ROW) 
			{
				NSString *brand = @"null";
                NSString *brandName = @"null";
                
                if (sqlite3_column_text(selectstmtIn, 0))
                    brand  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmtIn, 0)];
                
                const char *sql_3;
                
                sql_3 = "select BrandName from Brand where BrandId = ?";
                
                sqlite3_stmt *selstmt_3;
                
                if (sqlite3_prepare_v2(database, sql_3, -1, &selstmt_3, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt_3, 1, [brand UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_3) == SQLITE_ROW)
                    {
                        
                        if (sqlite3_column_text(selstmt_3, 0))
                            brandName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 0)];
                    }
                }
                sqlite3_finalize(selstmt_3);
                
                [brandToLiveInArray    addObject:brandName];
                [brandIdToLiveInArray  addObject:brand];
                [brandInToLiveInArray   addObject:@"out"];
            }
		}
        sqlite3_finalize(selectstmtIn);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *brandToLiveInDict    = [NSDictionary dictionaryWithObject:brandToLiveInArray forKey:@"brandName"];
    NSDictionary *brandIdToLiveInDict  = [NSDictionary dictionaryWithObject:brandIdToLiveInArray forKey:@"brandId"];
    NSDictionary *brandInToLiveInDict  = [NSDictionary dictionaryWithObject:brandInToLiveInArray forKey:@"brandin"];
    
    [brandList    addObject:brandToLiveInDict];
    [brandIdList  addObject:brandIdToLiveInDict];
    [brandInList  addObject:brandInToLiveInDict];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self brandListCreate];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [brandList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the section
    NSDictionary *dictionary = [brandList objectAtIndex:section];
    NSArray		 *array      = [dictionary objectForKey:@"brandName"];
		
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];

        [cell setBackgroundColor:UIColor.clearColor];

        UIView *selView = [[UIView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(tableView.frame),70.f)];
        selView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
        selView.tag = 13;
        [selView setHidden:YES];
        [cell addSubview:selView];

		UIFont *cellFont = [UIFont systemFontOfSize:18.0];
		UIFont *detailCellFont = [UIFont systemFontOfSize:14.0];
        
        cell.textLabel.font = cellFont;
        cell.detailTextLabel.font = detailCellFont;

        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(
                0,
                70.f - 1.f/UIScreen.mainScreen.scale,
                CGRectGetWidth(tableView.frame),
                1.f/UIScreen.mainScreen.scale)
        ];
        [bottomLine setBackgroundColor:[UIColor blackColor]];
        [cell addSubview:bottomLine];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	
    NSDictionary	*dictionary = [brandList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"brandName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    NSDictionary	*dictIn     = [brandInList objectAtIndex:0];
    NSArray			*arrayIn	= [dictIn objectForKey:@"brandin"];
    NSString		*valueIn	= [arrayIn objectAtIndex:indexPath.row];
        
    cell.textLabel.text	 	  = cellValue;
    
    if ([valueIn isEqualToString:@"in"])
        cell.textLabel.textColor = [UIColor blackColor];
    else 
        cell.textLabel.textColor = [UIColor yellowColor];

    UIView *bg = [cell viewWithTag:13];
    if (bg) {
        [bg setHidden:YES];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //UIColor *mycolor= [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:128.0/255.0 alpha:1.0];
    cell.backgroundColor = UIColor.clearColor;
    
}

- (void)refreshData{
    [self brandListCreate];
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (selectedIndex) {
        UITableViewCell *previousSelected = [tableView cellForRowAtIndexPath:selectedIndex];
        UIView *bg = [previousSelected viewWithTag:13];
        if (bg)
            [bg setHidden:YES];
        NSDictionary	*dictIn     = [brandInList objectAtIndex:0];
        NSArray			*arrayIn	= [dictIn objectForKey:@"brandin"];
        NSString		*valueIn	= [arrayIn objectAtIndex:selectedIndex.row];

        if ([valueIn isEqualToString:@"in"])
            previousSelected.textLabel.textColor = [UIColor blackColor];
        else
            previousSelected.textLabel.textColor = [UIColor yellowColor];
    }

    selectedIndex = indexPath;

    UITableViewCell *selected = [tableView cellForRowAtIndexPath:selectedIndex];
    UIView *bg = [selected viewWithTag:13];
    if (bg)
        [bg setHidden:NO];
    selected.textLabel.textColor = UIColor.whiteColor;
    
    NSDictionary	*dictionary = [brandIdList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"brandId"];
    NSString		*brandId	= [array objectAtIndex:indexPath.row];
    
    [self.delegate brandSelected:brandId];
}


- (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}

@end
