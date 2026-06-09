//
//  NoticeViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 17.12.12.
//
//

#import "NoticeViewController.h"
#import "NoticeDescrViewController.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

@implementation NoticeViewController

static sqlite3 *database = nil;

@synthesize isViewPushed;
@synthesize idList, idListNew, nameList, nameListNew, descrList, descrListNew,tableView;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //NavBar Setup
    self.navigationItem.title = @"Уведомления";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    [self createNoticeList];

    if (isViewPushed == NO) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];

        self.navigationItem.rightBarButtonItem = barButton;
    }

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView setBackgroundColor:UIColor.clearColor];
}

- (void)createNoticeList {
    NSMutableArray *idToLiveInArray         = [NSMutableArray array];
    NSMutableArray *idNewToLiveInArray      = [NSMutableArray array];
    NSMutableArray *nameToLiveInArray       = [NSMutableArray array];
    NSMutableArray *nameNewToLiveInArray    = [NSMutableArray array];
    NSMutableArray *descrToLiveInArray      = [NSMutableArray array];
    NSMutableArray *descrNewToLiveInArray   = [NSMutableArray array];
    //NSMutableArray *statusToLiveInArray     = [NSMutableArray array];
    //NSMutableArray *statusNewToLiveInArray  = [NSMutableArray array];
    
    idList         = [NSMutableArray new];
    idListNew      = [NSMutableArray new];
    nameList       = [NSMutableArray new];
    nameListNew    = [NSMutableArray new];
    descrList      = [NSMutableArray new];
    descrListNew   = [NSMutableArray new];
    //statusList     = [NSMutableArray new];
    //statusListNew  = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        sql = "select ID, Name, Description, Status from  NoticeTable";
		
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
			while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *notId         = @"null";
                NSString *name          = @"null";
                NSString *descr         = @"null";
                NSString *status        = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    notId        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    name      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    descr          = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    status      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                
                if ([status isEqualToString:@"new"])
                {
                    [idNewToLiveInArray      addObject:notId];
                    [nameNewToLiveInArray    addObject:name];
                    [descrNewToLiveInArray   addObject:descr];
                } else {
                    [idToLiveInArray         addObject:notId];
                    [nameToLiveInArray       addObject:name];
                    [descrToLiveInArray      addObject:descr];
                }
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
        
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *idToLiveInDict        = [NSDictionary dictionaryWithObject:idToLiveInArray forKey:@"id"];
    NSDictionary *idNewToLiveInDict     = [NSDictionary dictionaryWithObject:idNewToLiveInArray forKey:@"idNew"];
    NSDictionary *nameToLiveInDict      = [NSDictionary dictionaryWithObject:nameToLiveInArray forKey:@"name"];
    NSDictionary *nameNewToLiveInDict   = [NSDictionary dictionaryWithObject:nameNewToLiveInArray forKey:@"nameNew"];
    NSDictionary *descrToLiveInDict     = [NSDictionary dictionaryWithObject:descrToLiveInArray forKey:@"descr"];
    NSDictionary *descrNewToLiveInDict  = [NSDictionary dictionaryWithObject:descrNewToLiveInArray forKey:@"descrNew"];
    
    [idList         addObject:idToLiveInDict];
    [idListNew      addObject:idNewToLiveInDict];
    [nameList       addObject:nameToLiveInDict];
    [nameListNew    addObject:nameNewToLiveInDict];
    [descrList      addObject:descrToLiveInDict];
    [descrListNew   addObject:descrNewToLiveInDict];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Новые";
    else
        return @"Обработанные";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        NSDictionary	*dictName  = [nameListNew objectAtIndex:0];
        NSArray			*arrayName = [dictName objectForKey:@"nameNew"];
        
        return [arrayName count];
    } else {
        NSDictionary	*dictName  = [nameList objectAtIndex:0];
        NSArray			*arrayName = [dictName objectForKey:@"name"];
        
        return [arrayName count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier: SimpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleTableIdentifier];
//        cell.layoutMargins = UIEdgeInsetsMake(0,35,0,35);
//        [cell setBackgroundColor:UIColor.clearColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize: 18.f];
        cell.accessoryType = UITableViewCellAccessoryNone;
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0,52.f - 1.f/UIScreen.mainScreen.scale,CGRectGetWidth(tableView.frame),1.f/UIScreen.mainScreen.scale)];
        [bottomLine setBackgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground]];
        [cell addSubview:bottomLine];
        [cell.textLabel setTextColor:[UIColor blackColor]];
        /*UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(20,0,CGRectGetWidth(tableView.frame)-40,52.f)];
        bgView.tag = 13;
        [cell addSubview:bgView];
        for (id subView in cell.subviews) {
            if ([subView isEqual:bgView])
                continue;
            [cell bringSubviewToFront:subView];
        }*/
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if ([indexPath section] == 0) {
        NSDictionary	*dictName  = [nameListNew objectAtIndex:0];
        NSArray			*arrayName = [dictName objectForKey:@"nameNew"];
        NSString        *nameValue = [arrayName objectAtIndex:indexPath.row];
        
        cell.textLabel.text  = nameValue;
        cell.imageView.image = [UIImage imageNamed:ACImageNameCheckmark];
    } else {
        NSDictionary	*dictName  = [nameList objectAtIndex:0];
        NSArray			*arrayName = [dictName objectForKey:@"name"];
        NSString        *nameValue = [arrayName objectAtIndex:indexPath.row];
        
        cell.textLabel.text  = nameValue;
        cell.imageView.image = [UIImage imageNamed:ACImageNameCheckmarkSelected];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UIColor *bgColor = indexPath.section == 1 ? [ASPFunctions colorFromHex:@"7DE77A"] : [ASPFunctions colorFromHex:@"F0BD59"];
    /*UIView *bgView = [cell viewWithTag:13];
    if (bgView)
        [bgView setBackgroundColor:bgColor];*/
    [cell setBackgroundColor:bgColor];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toindexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%li", (long)indexPath.row);
    
    NoticeDescrViewController *fvController = [[NoticeDescrViewController alloc] initWithNibName:@"NoticeDescrViewController"
                                                                                          bundle:NSBundle.mainBundle];
    
    
    if ([indexPath section] == 0) {
        NSDictionary	*dictId  = [idListNew objectAtIndex:0];
        NSArray			*arrayId = [dictId objectForKey:@"idNew"];
        NSString        *idValue = [arrayId objectAtIndex:indexPath.row];
        
        NSDictionary	*dictName  = [nameListNew objectAtIndex:0];
        NSArray			*arrayName = [dictName objectForKey:@"nameNew"];
        NSString        *nameValue = [arrayName objectAtIndex:indexPath.row];
        
        NSDictionary	*dictDescr  = [descrListNew objectAtIndex:0];
        NSArray			*arrayDescr = [dictDescr objectForKey:@"descrNew"];
        NSString        *descrValue = [arrayDescr objectAtIndex:indexPath.row];
        
        fvController.noticeId          = idValue;
        fvController.noticeName        = nameValue;
        fvController.noticeDescription = descrValue;
        fvController.isNewNotice = YES;
    } else {
        NSDictionary	*dictId  = [idList objectAtIndex:0];
        NSArray			*arrayId = [dictId objectForKey:@"id"];
        NSString        *idValue = [arrayId objectAtIndex:indexPath.row];
        
        NSDictionary	*dictName  = [nameList objectAtIndex:0];
        NSArray			*arrayName = [dictName objectForKey:@"name"];
        NSString        *nameValue = [arrayName objectAtIndex:indexPath.row];
        
        NSDictionary	*dictDescr  = [descrList objectAtIndex:0];
        NSArray			*arrayDescr = [dictDescr objectForKey:@"descr"];
        NSString        *descrValue = [arrayDescr objectAtIndex:indexPath.row];
        
        fvController.noticeId          = idValue;
        fvController.noticeName        = nameValue;
        fvController.noticeDescription = descrValue;
    }
    
    fvController.delegate = self;
    [self.navigationController.navigationBar setTitleTextAttributes:
            @{NSForegroundColorAttributeName:[ASPFunctions colorFromHex:@"f1f1f1"]}];
    [self.navigationController.navigationBar setTintColor:[ASPFunctions colorFromHex:@"f1f1f1"]];
    [self.navigationController pushViewController:fvController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)createNotice {
    NSMutableArray *idToLiveInArray         = [NSMutableArray array];
    NSMutableArray *idNewToLiveInArray      = [NSMutableArray array];
    NSMutableArray *nameToLiveInArray       = [NSMutableArray array];
    NSMutableArray *nameNewToLiveInArray    = [NSMutableArray array];
    NSMutableArray *descrToLiveInArray      = [NSMutableArray array];
    NSMutableArray *descrNewToLiveInArray   = [NSMutableArray array];
    
    idList         = [NSMutableArray new];
    idListNew      = [NSMutableArray new];
    nameList       = [NSMutableArray new];
    nameListNew    = [NSMutableArray new];
    descrList      = [NSMutableArray new];
    descrListNew   = [NSMutableArray new];
    
    [idNewToLiveInArray      addObject:@"1"];
    [nameNewToLiveInArray    addObject:@"Обновление версии"];
    [descrNewToLiveInArray   addObject:@"Вышла новая версия приложения 1.9.9"];
    [idNewToLiveInArray      addObject:@"3"];
    [nameNewToLiveInArray    addObject:@"Собрание"];
    [descrNewToLiveInArray   addObject:@"Собрание менеджеров в офисе"];
    [idNewToLiveInArray      addObject:@"4"];
    [nameNewToLiveInArray    addObject:@"Получить телефон"];
    [descrNewToLiveInArray   addObject:@"Получить у руководителся новый телефон"];
    
    NSDictionary *idToLiveInDict        = [NSDictionary dictionaryWithObject:idToLiveInArray forKey:@"id"];
    NSDictionary *idNewToLiveInDict     = [NSDictionary dictionaryWithObject:idNewToLiveInArray forKey:@"idNew"];
    NSDictionary *nameToLiveInDict      = [NSDictionary dictionaryWithObject:nameToLiveInArray forKey:@"name"];
    NSDictionary *nameNewToLiveInDict   = [NSDictionary dictionaryWithObject:nameNewToLiveInArray forKey:@"nameNew"];
    NSDictionary *descrToLiveInDict     = [NSDictionary dictionaryWithObject:descrToLiveInArray forKey:@"descr"];
    NSDictionary *descrNewToLiveInDict  = [NSDictionary dictionaryWithObject:descrNewToLiveInArray forKey:@"descrNew"];
    
    [idList         addObject:idToLiveInDict];
    [idListNew      addObject:idNewToLiveInDict];
    [nameList       addObject:nameToLiveInDict];
    [nameListNew    addObject:nameNewToLiveInDict];
    [descrList      addObject:descrToLiveInDict];
    [descrListNew   addObject:descrNewToLiveInDict];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        char *sErrMsg;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
        
        NSDictionary	*dictId  = [idListNew objectAtIndex:0];
        NSArray			*arrayId = [dictId objectForKey:@"idNew"];
        
        for (int y = 0; y < [arrayId count]; y++) {
            NSDictionary	*dictId  = [idListNew objectAtIndex:0];
            NSArray			*arrayId = [dictId objectForKey:@"idNew"];
            NSString        *idValue = [arrayId objectAtIndex:y];
            
            NSDictionary	*dictName  = [nameListNew objectAtIndex:0];
            NSArray			*arrayName = [dictName objectForKey:@"nameNew"];
            NSString        *nameValue = [arrayName objectAtIndex:y];
            
            NSDictionary	*dictDescr  = [descrListNew objectAtIndex:0];
            NSArray			*arrayDescr = [dictDescr objectForKey:@"descrNew"];
            NSString        *descrValue = [arrayDescr objectAtIndex:y];
            
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into NoticeTable (ID, Name, Description, Status) Values(?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [idValue UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [nameValue UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [descrValue UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [@"new" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
        }
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        sqlite3_close(database);
    } else
        sqlite3_close(database);

}

- (void)gridIsUpdated {

    [self createNoticeList];
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 40)];
    [headerView setBackgroundColor:UIColor.clearColor];
    tableView.sectionHeaderHeight = headerView.frame.size.height;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, headerView.frame.size.width - 35, 22)];
	label.text = [self tableView:tableView titleForHeaderInSection:section];
	label.font = [UIFont systemFontOfSize:17.0];
	label.backgroundColor = UIColor.clearColor;
    
	label.textColor = [UIColor blackColor];
    
	[headerView addSubview:label];
	return headerView;
}

-(BOOL)checkForNotice {
    BOOL haveNew = NO;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select ID from NoticeTable";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW)
                haveNew = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return haveNew;
}

@end
