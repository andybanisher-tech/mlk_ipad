//
//  ActionTypeViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 11.04.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "ActionTypeViewController.h"

@interface ActionTypeViewController ()

@end

@implementation ActionTypeViewController

static sqlite3 *database = nil;

@synthesize typeList;
@synthesize delegate;
@synthesize custAccount;

- (void)listCreate {
    typeList              = [NSMutableArray new];
	typeToLiveInArray     = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        NSString *squl = @"select ActionType from ActionTable group by ActionType";
        
        //squl = [NSString stringWithFormat:@"%@ and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == ActionTable.BrandId) group by ActionType", squl];
        
        sql = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            [typeToLiveInArray addObject:@"Убрать фильтр"];
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *type = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    type  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                [typeToLiveInArray addObject:type];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *typeToLiveInDict    = [NSDictionary dictionaryWithObject:typeToLiveInArray forKey:@"Type"];
    
    [typeList addObject:typeToLiveInDict];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.frame = CGRectMake(0, 0, 150, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self listCreate];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [typeList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [typeList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"Type"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
    NSDictionary	*dictionary = [typeList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"Type"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    if ([cellValue isEqualToString:@"1"]) {
        cell.textLabel.text = @"Акция на запуск";
    } else if ([cellValue isEqualToString:@"2"]) {
        cell.textLabel.text = @"Акция на сумму/кол-во";
    } else if ([cellValue isEqualToString:@"3"]) {
        cell.textLabel.text = @"Комбинированная акция";
    }
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
    
    if (indexPath.row == 0)
	{
        cell.textLabel.text = @"Убрать фильтр";
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary  = [typeList objectAtIndex:indexPath.section];
    NSArray      *array       = [dictionary objectForKey:@"Type"];
    NSString     *type     = [array objectAtIndex:indexPath.row];
    
    if (indexPath.row == 0)
        [self.delegate typeIsSelected:nil];
    else
        [self.delegate typeIsSelected:type];
}

+ (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}


@end
