//
//  GroupView.m
//  MLK
//
//  Created by Rustem Galyamov on 28.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GroupView.h"

#define CELL_CONTENT_WIDTH 700.0f
#define CELL_CONTENT_MARGIN 10.0f

static sqlite3 *database = nil;

@implementation GroupView

@synthesize isViewPushed;

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.tableView.frame = CGRectMake(0, 0, 450, CGRectGetHeight(self.tableView.frame));
    self.preferredContentSize = self.tableView.contentSize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Группы";
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    if (isViewPushed == NO) {
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel_Clicked:)];
        
        barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        self.navigationItem.leftBarButtonItem = barButton;
    }
    
    self.groupsArray = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        //const char *sql = "select BrandId, BrandName from Brand order by BrandName asc";
        const char *sql = "select GroupId, GroupName from ItemGroup where BrandId = ? order by GroupName";
        
        NSString *requiredIDsQueryString = [self.requiredGroupIDsArray componentsJoinedByString:@"','"];
        if (requiredIDsQueryString) {
            NSString *sqlQuery = [NSString stringWithFormat:@"select GroupId, GroupName from ItemGroup where BrandId = ? and GroupId IN ('%@') order by GroupName", requiredIDsQueryString];
            sql = [sqlQuery UTF8String];
        }
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [self.selectedBrandID UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *groupObject = [NSMutableDictionary new];
                
                NSString *groupID   = @"null";
                NSString *groupName = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    groupID  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    groupName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                groupObject[@"groupID"] = groupID;
                groupObject[@"groupName"] = groupName;
                
                [self.groupsArray addObject:groupObject];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }
    
    if (self.groupsArray.count > 0) {
        NSDictionary *groupObject = @{@"groupName" : @"ВСЕ"};
        [self.groupsArray insertObject:groupObject atIndex:0];
    }
    [self.tableView reloadData];
    
    if (self.selectedGroupID) {
        NSUInteger searchIndex = [self.groupsArray indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj[@"groupID"] isEqual:self.selectedGroupID];
        }];
        
        if (searchIndex != NSNotFound) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:searchIndex inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            });
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groupsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel	*lblTitle = nil;
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 440.f, 44.f)];
        lblTitle.tag = 1;
        
        [cell.contentView addSubview:lblTitle];
    } else {
        lblTitle = (UILabel *)[cell viewWithTag:1];
    }
    
    NSDictionary *object = self.groupsArray[indexPath.row];
    lblTitle.text = object[@"groupName"];
    
    if (indexPath.row == 0) {
        lblTitle.textColor = [UIColor blueColor];
        lblTitle.font = [UIFont boldSystemFontOfSize:22.0];
    } else {
        lblTitle.textColor = [UIColor blackColor];
        lblTitle.font = [UIFont boldSystemFontOfSize:18.0];
    }
    
    if ([object[@"groupID"] isEqual:self.selectedGroupID]) {
        cell.backgroundColor = UIColor.lightGrayColor;
    } else {
        cell.backgroundColor = UIColor.whiteColor;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object = self.groupsArray[indexPath.row];
    self.selectedGroupID = object[@"groupID"];
    
    if (self.delegate) {
        if ([object[@"groupName"] isEqual:@"ВСЕ"]) {
            [self.delegate markIsSelected:self.selectedBrandID];
        } else {
            [self.delegate groupIsSelected:self.selectedGroupID];
        }
    }
}

@end
