//
//  ActionMarkViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 11.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "ActionMarkViewController.h"

static sqlite3      *database = nil;

@implementation ActionMarkViewController

@synthesize delegate;
@synthesize brandList;
@synthesize brandIdList;
@synthesize custAccount;

#define LABEL_TAG 1

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.frame = CGRectMake(0, 0, 250, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void) viewDidLoad {
    [super viewDidLoad];
	
	brandList            = [NSMutableArray new];
	brandsToLiveInArray  = [NSMutableArray array];
    
    brandIdList            = [NSMutableArray new];
	brandsIdToLiveInArray  = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		//const char *sql = "select BrandId, BrandName from Brand order by BrandName asc";
		const char *sql = "select BrandId from PersonalPriceList where CustAccount = ?";
		
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            [brandsIdToLiveInArray addObject:@"clear"];
            [brandsToLiveInArray   addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *brandId   = @"null";
                NSString *brandName = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    brandId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                const char *sql_1;
                
                sql_1 = "select BrandName from Brand where BrandId = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(selstmt, 1, [brandId UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt) == SQLITE_ROW) 
                    {
                        if (sqlite3_column_text(selstmt, 0))
                            brandName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                    }
                }
                sqlite3_finalize(selstmt);
                
                [brandsIdToLiveInArray addObject:brandId];
                [brandsToLiveInArray   addObject:brandName];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *brandIdToLiveInDict    = [NSDictionary dictionaryWithObject:brandsIdToLiveInArray forKey:@"BrandId"];
    NSDictionary *brandToLiveInDict = [NSDictionary dictionaryWithObject:brandsToLiveInArray forKey:@"BrandName"];
    
    [brandIdList addObject:brandIdToLiveInDict];
    [brandList   addObject:brandToLiveInDict];
    
    copyBrandIdList = [NSMutableArray new];
    copyBrandList   = [NSMutableArray new];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [brandList count];
}
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dictionary = [brandList objectAtIndex:section];
    NSArray		 *array = [dictionary objectForKey:@"BrandName"];
    
    return [array count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Get the label for the current cell
	NSDictionary	*dictionary = [brandList objectAtIndex:indexPath.section];
    NSArray			*array		= [dictionary objectForKey:@"BrandName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    cell.textLabel.text       = cellValue;
    
    if (indexPath.row == 0)
	{
		cell.textLabel.textColor = [UIColor blueColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0)
        cell.backgroundColor = UIColor.lightGrayColor;
}

- (void) tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary	*dictionaryId  = [brandIdList objectAtIndex:indexPath.section];
    NSArray			*arrayId	   = [dictionaryId objectForKey:@"BrandId"];
    NSString		*brandId       = [arrayId objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0) {
        if (self.delegate) {
            [self.delegate markIsSelected:nil];
        }
    } else {
        if (self.delegate) {
            [self.delegate markIsSelected:brandId];
        }
    }
}

- (void)markIsSelected:(NSString *)brand {
    if ([brand isEqualToString:@"clear"])
        [self.delegate markIsSelected:nil];
    else
        [self.delegate markIsSelected:brand];
}

@end
