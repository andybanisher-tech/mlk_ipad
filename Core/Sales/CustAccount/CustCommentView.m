//
//  CustCommentView.m
//  MLK
//
//  Created by Rustem Galyamov on 04.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CustCommentView.h"
#import "PutCommentsRequest.h"

@implementation CustCommentView

static sqlite3 *database = nil;

@synthesize dateList, userList, commentList, statusList, commentIdList;
@synthesize delegate;
@synthesize custAccount, commentType, dateSelected;

- (void)createCommentList {
    dateList    = [NSMutableArray new];
	userList    = [NSMutableArray new];
    commentList = [NSMutableArray new];
    statusList  = [NSMutableArray new];
    commentIdList  = [NSMutableArray new];
    self.timeList    = [NSMutableArray new];
    
    dateToLiveInArray     = [NSMutableArray array];
    userToLiveInArray     = [NSMutableArray array];
    commentToLiveInArray  = [NSMutableArray array];
    statusToLiveInArray   = [NSMutableArray array];
    commentIdToLiveInArray   = [NSMutableArray array];
    timeToLiveInArray     = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (dateSelected)
            sql = "select Date, UserId, Description, SendStatus, CommentId, Time from CustComment where CustAccount = ? and CommentType = ? and Date = ? and ForDelete = '0' order by substr(Date,7)||substr(Date,4,2)||substr(Date,1,2) desc, time(Time) desc";
        else
            sql = "select Date, UserId, Description, SendStatus, CommentId, Time from CustComment where CustAccount = ? and CommentType = ? and ForDelete = '0' order by substr(Date,7)||substr(Date,4,2)||substr(Date,1,2) desc, time(Time) desc";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [commentType UTF8String], -1, SQLITE_TRANSIENT);
            
            if (dateSelected)
                sqlite3_bind_text(selectstmt, 3, [dateSelected UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *date;
                NSString *user;
                NSString *descr;
                NSString *status;
                NSString *commentId;
                NSString *time;
                
                if (! sqlite3_column_text(selectstmt, 0))
                    date = @"";
                else
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (! sqlite3_column_text(selectstmt, 1))
                    user = @"";
                else
                    user  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (! sqlite3_column_text(selectstmt, 2))
                    descr = @"";
                else
                    descr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (! sqlite3_column_text(selectstmt, 3))
                    status = @"";
                else
                    status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (! sqlite3_column_text(selectstmt, 4))
                    commentId = @"";
                else
                    commentId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (! sqlite3_column_text(selectstmt, 5))
                    time = @"";
                else
                    time  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                [dateToLiveInArray      addObject:date];
                [userToLiveInArray      addObject:user];
                [commentToLiveInArray   addObject:descr];
                [statusToLiveInArray    addObject:status];
                [commentIdToLiveInArray    addObject:commentId];
                [timeToLiveInArray      addObject:time];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *dateToLiveInDict     = [NSDictionary dictionaryWithObject:dateToLiveInArray forKey:@"Date"];
    NSDictionary *userToLiveInDict     = [NSDictionary dictionaryWithObject:userToLiveInArray forKey:@"User"];
    NSDictionary *commentToLiveInDict  = [NSDictionary dictionaryWithObject:commentToLiveInArray forKey:@"Comment"];
    NSDictionary *statusToLiveInDict   = [NSDictionary dictionaryWithObject:statusToLiveInArray forKey:@"Status"];
    NSDictionary *commentIdToLiveInDict   = [NSDictionary dictionaryWithObject:commentIdToLiveInArray forKey:@"CommentId"];
    NSDictionary *timeToLiveInDict     = [NSDictionary dictionaryWithObject:timeToLiveInArray forKey:@"Time"];
    
    [dateList       addObject:dateToLiveInDict];
    [userList       addObject:userToLiveInDict];
    [commentList    addObject:commentToLiveInDict];
    [statusList     addObject:statusToLiveInDict];
    [commentIdList     addObject:commentIdToLiveInDict];
    [self.timeList       addObject:timeToLiveInDict];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createCommentList];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [dateList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Number of rows it should expect should be based on the secti
    NSDictionary *dictionary = [dateList objectAtIndex:0];
    NSArray		 *array = [dictionary objectForKey:@"Date"];
    
    return [array count];
}

 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
     return 50.f;
 }

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UIFont *cellFont = [UIFont systemFontOfSize:16.0];
		UIFont *detailCellFont = [UIFont systemFontOfSize:18.0];
        
        cell.textLabel.font = cellFont;
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(100,10,CGRectGetWidth(tableView.frame) - 100,30)];
        descriptionLabel.tag = 1001;
        descriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [cell addSubview:descriptionLabel];
        descriptionLabel.font = detailCellFont;
        /*UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0,50.f - 1.f/UIScreen.mainScreen.scale,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
        [separator setBackgroundColor:[UIColor blackColor]];
        [cell addSubview:separator];*/
    }
    if (selectedIndex && selectedIndex.row == indexPath.row) {
        cell.backgroundColor = [ASPFunctions colorFromHex:@"598BEB"];
    } else
        [cell setBackgroundColor:UIColor.clearColor];
    
    NSDictionary	*ddictionary = [dateList objectAtIndex:0];
    NSArray			*darray		 = [ddictionary objectForKey:@"Date"];
    NSString		*date   	 = [darray objectAtIndex:indexPath.row];
    
    NSDictionary	*tdictionary = [self.timeList objectAtIndex:0];
    NSArray			*tarray		 = [tdictionary objectForKey:@"Time"];
    NSString		*tvalue   	 = [tarray objectAtIndex:indexPath.row];
    
    if (tvalue.length<1)
        cell.textLabel.text	 	  = [NSString stringWithFormat:@"%@",date];
    else
        cell.textLabel.text	 	  = [NSString stringWithFormat:@"%@ - %@",date,tvalue];
//    UILabel *descrLabel = [cell viewWithTag:1001];
//    descrLabel.text = comment;
    
    return cell;
}

- (void)refreshData{
    [self createCommentList];
    selectedIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    NSDictionary	*dictionary  = [commentList objectAtIndex:0];
    NSArray			*array		 = [dictionary objectForKey:@"Comment"];

    NSString		*comment   	 = @"";
    if ([array count]>0)
        comment = [array objectAtIndex:selectedIndex.row];

    [self.delegate setComment:comment];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (selectedIndex) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:selectedIndex];
        cell.backgroundColor = UIColor.clearColor;
    }

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [ASPFunctions colorFromHex:@"598BEB"];

    selectedIndex = indexPath;

    
    NSDictionary	*dictionary  = [commentList objectAtIndex:0];
    NSArray			*array		 = [dictionary objectForKey:@"Comment"];
    NSString		*comment   	 = [array objectAtIndex:indexPath.row];
    
    [self.delegate setComment:comment]; 
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)updateArrays:(NSIndexPath *)indexPath {
    NSDictionary *dateDict  = [dateList objectAtIndex:indexPath.section];
    NSArray		 *dateArray = [dateDict objectForKey:@"Date"];
    
    NSDictionary *commentIdDict  = [commentIdList objectAtIndex:indexPath.section];
    NSArray		 *commentIdArray = [commentIdDict objectForKey:@"CommentId"];
    NSString     *commentId = [commentIdArray objectAtIndex:indexPath.row];

    NSDictionary *userDict  = [userList objectAtIndex:indexPath.section];
    NSArray		 *userArray = [userDict objectForKey:@"User"];
    
    NSDictionary *statusDict  = [statusList objectAtIndex:indexPath.section];
    NSArray		 *statusArray = [statusDict objectForKey:@"Status"];
    
    NSDictionary *commentDict  = [commentList objectAtIndex:indexPath.section];
    NSArray		 *commentArray = [commentDict objectForKey:@"Comment"];
    
    NSDictionary *timeDict  = [self.timeList objectAtIndex:indexPath.section];
    NSArray		 *timeArray = [timeDict objectForKey:@"Time"];
    
    NSMutableArray *afterRemDate        = [NSMutableArray arrayWithArray:dateArray];
    NSMutableArray *afterRemCommentId       = [NSMutableArray arrayWithArray:commentIdArray];
    NSMutableArray *afterRemUser        = [NSMutableArray arrayWithArray:userArray];
    NSMutableArray *afterRemStatus      = [NSMutableArray arrayWithArray:statusArray];
    NSMutableArray *afterRemComment         = [NSMutableArray arrayWithArray:commentArray];
    NSMutableArray *afterRemTime         = [NSMutableArray arrayWithArray:timeArray];
    
    [afterRemDate           removeObjectAtIndex:indexPath.row];
    [afterRemCommentId      removeObject:commentId];
    [afterRemUser           removeObjectAtIndex:indexPath.row];
    [afterRemStatus         removeObjectAtIndex:indexPath.row];
    [afterRemComment        removeObjectAtIndex:indexPath.row];
    [afterRemTime           removeObjectAtIndex:indexPath.row];
    
    NSDictionary *dateToLiveInDict          = [NSDictionary dictionaryWithObject:afterRemDate forKey:@"Date"];
    NSDictionary *commentIdToLiveInDict     = [NSDictionary dictionaryWithObject:afterRemCommentId forKey:@"CommentId"];
    NSDictionary *userToLiveInDict          = [NSDictionary dictionaryWithObject:afterRemUser forKey:@"User"];
    NSDictionary *statusToLiveInDict        = [NSDictionary dictionaryWithObject:afterRemStatus forKey:@"STatus"];
    NSDictionary *commentToLiveInDict       = [NSDictionary dictionaryWithObject:afterRemComment forKey:@"Comment"];
    NSDictionary *timeToLiveInDict          = [NSDictionary dictionaryWithObject:afterRemTime forKey:@"Time"];
    
    [dateList           removeAllObjects];
    [commentIdList      removeAllObjects];
    [userList           removeAllObjects];
    [statusList         removeAllObjects];
    [commentList        removeAllObjects];
    [self.timeList           removeAllObjects];
    
    [dateList           addObject:dateToLiveInDict];
    [commentIdList      addObject:commentIdToLiveInDict];
    [userList           addObject:userToLiveInDict];
    [statusList         addObject:statusToLiveInDict];
    [commentList        addObject:commentToLiveInDict];
    [self.timeList           addObject:timeToLiveInDict];
    
    [self removeComment:commentId];
    
    commentId = nil;
}

- (void)removeComment:(NSString *)commentId {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        const char *sql_3 = "update CustComment Set ForDelete = '1', SendStatus = 'New' where CommentId = ?";
        
        sqlite3_stmt *updateStmt;
        
        if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(updateStmt, 1, [commentId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(updateStmt);
            sqlite3_finalize(updateStmt);
            
        }
        
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
    }
    sqlite3_close(database);
    
    PutCommentsRequest *putComments = [PutCommentsRequest new];
    putComments.custAccount     = custAccount;
    putComments.commentId       = commentId;
    putComments.notShowProgress = YES;
    [putComments sendComments];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self updateArrays:indexPath];
            
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
        [tableView reloadData];
        [self refreshData];
    }
}



+ (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}


@end
