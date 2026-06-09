//
//  DNGrid.m
//  MLK
//
//  Created by Rustem Galyamov on 20.11.12.
//
//

#import "DNGrid.h"
#import "MyTableCell.h"

#import "GeneratedAssetSymbols.h"

static sqlite3 *database = nil;

@implementation DNGrid

@synthesize brandIdList, brandNameList, monthList, sysStatusList, managerStatusList, commentList, sendStatusList;
@synthesize delegate;
@synthesize custAccount;

#define LABEL_TAG 1
#define VALUE_TAG 2
#define FIRST_CELL_IDENTIFIER @"TrailItemCell"
#define SECOND_CELL_IDENTIFIER @"RegularCell"


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createLineList];
}

- (void)createLineList {
    NSMutableArray *brandIdToLiveInArray        = [NSMutableArray array];
    NSMutableArray *brandNameToLiveInArray      = [NSMutableArray array];
    NSMutableArray *monthToLiveInArray          = [NSMutableArray array];
    NSMutableArray *sysStatusToLiveInArray      = [NSMutableArray array];
    NSMutableArray *managerStatusToLiveInArray  = [NSMutableArray array];
    NSMutableArray *commentToLiveInArray        = [NSMutableArray array];
    NSMutableArray *sendStatusToLiveInArray     = [NSMutableArray array];
    
    brandIdList         = [NSMutableArray new];
    brandNameList       = [NSMutableArray new];
    monthList           = [NSMutableArray new];
    sysStatusList       = [NSMutableArray new];
    managerStatusList   = [NSMutableArray new];
    commentList         = [NSMutableArray new];
    sendStatusList      = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        sql = "select BrandId, BrandName, Date, SysStatus, MngrStatus, Comment, SendStatus from  DNTable where CustAccount = ?";
		
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
			sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            //NSLog(custAccount);
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *brandId       = @"null";
                NSString *brandName     = @"null";
                NSString *month         = @"null";
                NSString *sysStatus     = @"null";
                NSString *managerStatus = @"null";
                NSString *comment       = @"null";
                NSString *sendStatus    = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    brandId        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    brandName      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    month          = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    sysStatus      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    managerStatus  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    comment        = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    sendStatus     = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                [brandIdToLiveInArray       addObject:brandId];
                [brandNameToLiveInArray     addObject:brandName];
                [monthToLiveInArray         addObject:month];
                [sysStatusToLiveInArray     addObject:sysStatus];
                [managerStatusToLiveInArray addObject:managerStatus];
                [commentToLiveInArray       addObject:comment];
                [sendStatusToLiveInArray    addObject:sendStatus];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
        
	}
	else
	{
		sqlite3_close(database);
	}
    
    
    NSDictionary *brandIdToLiveInDict       = [NSDictionary dictionaryWithObject:brandIdToLiveInArray forKey:@"BrandId"];
    NSDictionary *brandNameToLiveInDict     = [NSDictionary dictionaryWithObject:brandNameToLiveInArray forKey:@"BrandName"];
    NSDictionary *monthToLiveInDict         = [NSDictionary dictionaryWithObject:monthToLiveInArray forKey:@"Month"];
    NSDictionary *sysStatusToLiveInDict     = [NSDictionary dictionaryWithObject:sysStatusToLiveInArray forKey:@"SysStatus"];
    NSDictionary *managerStatusToLiveInDict = [NSDictionary dictionaryWithObject:managerStatusToLiveInArray forKey:@"ManagerStatus"];
    NSDictionary *commentToLiveInDict       = [NSDictionary dictionaryWithObject:commentToLiveInArray forKey:@"Comment"];
    NSDictionary *sendStatusToLiveInDict    = [NSDictionary dictionaryWithObject:sendStatusToLiveInArray forKey:@"SendStatus"];
    
    [brandIdList        addObject:brandIdToLiveInDict];
    [brandNameList      addObject:brandNameToLiveInDict];
    [monthList          addObject:monthToLiveInDict];
    [sysStatusList      addObject:sysStatusToLiveInDict];
    [managerStatusList  addObject:managerStatusToLiveInDict];
    [commentList        addObject:commentToLiveInDict];
    [sendStatusList     addObject:sendStatusToLiveInDict];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
    NSDictionary	*dictBrand       = [brandIdList objectAtIndex:section];
    NSArray			*arrayBrand      = [dictBrand objectForKey:@"BrandId"];
    
    return [arrayBrand count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSString *MyIdentifier = [NSString stringWithFormat:@"MyIdentifier %li", (long)indexPath.row];
    MyTableCell *cell = (MyTableCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	
    
	if (cell == nil) {
		cell = [[MyTableCell alloc] initWithFrame:CGRectZero];
		
		[cell addColumn:45];
        [cell addColumn:250];
		[cell addColumn:350];
		[cell addColumn:500];
		[cell addColumn:650];
    }
    
    //NSDictionary	*dictBrand      = [brandIdList objectAtIndex:indexPath.section];
    //NSArray			*arrayBrand     = [dictBrand objectForKey:@"BrandId"];
    //NSString        *brandValue     = [arrayBrand objectAtIndex:indexPath.row];
    
    NSDictionary	*dictBrandName  = [brandNameList objectAtIndex:indexPath.section];
    NSArray			*arrayBrandName = [dictBrandName objectForKey:@"BrandName"];
    NSString        *brandNameValue = [arrayBrandName objectAtIndex:indexPath.row];
    
    NSDictionary	*dictMonth      = [monthList objectAtIndex:indexPath.section];
    NSArray			*arrayMonth     = [dictMonth objectForKey:@"Month"];
    NSString        *monthValue     = [arrayMonth objectAtIndex:indexPath.row];
    
    NSDictionary	*dictSys        = [sysStatusList objectAtIndex:indexPath.section];
    NSArray			*arraySys       = [dictSys objectForKey:@"SysStatus"];
    NSString        *sysValue       = [arraySys objectAtIndex:indexPath.row];
    
    NSDictionary	*dictManager    = [managerStatusList objectAtIndex:indexPath.section];
    NSArray			*arrayManager 	= [dictManager objectForKey:@"ManagerStatus"];
    NSString        *managerValue	= [arrayManager objectAtIndex:indexPath.row];
    
    NSDictionary	*dictComment    = [commentList objectAtIndex:indexPath.section];
    NSArray			*arrayComment 	= [dictComment objectForKey:@"Comment"];
    NSString        *commentValue	= [arrayComment objectAtIndex:indexPath.row];
    
    NSDictionary	*dictSndStatus  = [sendStatusList objectAtIndex:indexPath.section];
    NSArray			*arraySndStatus = [dictSndStatus objectForKey:@"SendStatus"];
    NSString        *sndStatusValue	= [arraySndStatus objectAtIndex:indexPath.row];
    
    UIColor *mycolor= [UIColor colorWithRed:245.0/255.0 green:222.0/255.0 blue:179.0/255.0 alpha:1.0];
    
    UILabel *label;
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(50.0, 0, 195.0, tableView.rowHeight)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = brandNameValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
	[label setNumberOfLines:2];
    
    if (![sysValue isEqualToString:managerValue])
        label.backgroundColor = mycolor;
    else
        label.backgroundColor = UIColor.whiteColor;
    
    [cell.contentView addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(255.0, 0, 90.0, tableView.rowHeight)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = monthValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
	[label setNumberOfLines:2];
    
    if (![sysValue isEqualToString:managerValue])
        label.backgroundColor = mycolor;
    else
        label.backgroundColor = UIColor.whiteColor;
    
    [cell.contentView addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(355.0, 0, 140.0, tableView.rowHeight)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = sysValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
	[label setNumberOfLines:2];
    
    if (![sysValue isEqualToString:managerValue])
        label.backgroundColor = mycolor;
    else
        label.backgroundColor = UIColor.whiteColor;
    
    [cell.contentView addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(505.0, 0, 140.0, tableView.rowHeight)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = managerValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    if (![sysValue isEqualToString:managerValue])
        label.backgroundColor = mycolor;
    else
        label.backgroundColor = UIColor.whiteColor;
    
    [cell.contentView addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(655.0, 0, 320.0, tableView.rowHeight)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = commentValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
	[label setNumberOfLines:2];
    
    if (![sysValue isEqualToString:managerValue])
        label.backgroundColor = mycolor;
    else
        label.backgroundColor = UIColor.whiteColor;
    
    [cell.contentView addSubview:label];
    
    CALayer *cellLayer = cell.layer;
    cellLayer.borderColor = [[UIColor blackColor] CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    if ([sndStatusValue isEqual:@"Sended"])
        cell.imageView.image = [UIImage imageNamed:ACImageNameChecked];
    else
        cell.imageView.image = [UIImage imageNamed:ACImageNameUnchecked];
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary	*dictBrand      = [brandIdList objectAtIndex:indexPath.section];
    NSArray			*arrayBrand     = [dictBrand objectForKey:@"BrandId"];
    NSString        *brandValue     = [arrayBrand objectAtIndex:indexPath.row];
    
    [self.delegate showDNActionSheet:[NSNumber numberWithUnsignedInteger:indexPath.row] title:@"Список действий" custAccount:custAccount brandId:brandValue];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //section text as a label
    UIView *sectionHead = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 984, 20)];
    
    UILabel *label = [[UILabel	alloc] initWithFrame:CGRectMake(0.0, 0, 50.0, 20)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = @"О/Н";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer = label.layer;
    cellLayer.borderColor = [[UIColor blackColor] CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(50.0, 0, 200.0, 20)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = @"Марка";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer2 = label.layer;
    cellLayer2.borderColor = [[UIColor blackColor] CGColor];
    cellLayer2.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(250.0, 0, 100.0, 20)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = @"Месяц";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer3 = label.layer;
    cellLayer3.borderColor = [[UIColor blackColor] CGColor];
    cellLayer3.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(350.0, 0, 150.0, 20)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = @"Статус системы";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer4 = label.layer;
    cellLayer4.borderColor = [[UIColor blackColor] CGColor];
    cellLayer4.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(500.0, 0, 150.0, 20)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = @"Статус менеджера";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer5 = label.layer;
    cellLayer5.borderColor = [[UIColor blackColor] CGColor];
    cellLayer5.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(650.0, 0, 335.0, 20)];
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = @"Комментарий менеджера";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer6 = label.layer;
    cellLayer6.borderColor = [[UIColor blackColor] CGColor];
    cellLayer6.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    return sectionHead;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary	*dictSys        = [sysStatusList objectAtIndex:indexPath.section];
    NSArray			*arraySys       = [dictSys objectForKey:@"SysStatus"];
    NSString        *sysValue       = [arraySys objectAtIndex:indexPath.row];
    
    NSDictionary	*dictManager    = [managerStatusList objectAtIndex:indexPath.section];
    NSArray			*arrayManager 	= [dictManager objectForKey:@"ManagerStatus"];
    NSString        *managerValue	= [arrayManager objectAtIndex:indexPath.row];
    
    if (![sysValue isEqualToString:managerValue]) {
        UIColor *mycolor= [UIColor colorWithRed:245.0/255.0 green:222.0/255.0 blue:179.0/255.0 alpha:1.0];
        cell.backgroundColor = mycolor;
    } else
        cell.backgroundColor = UIColor.whiteColor;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)finalizeStatements {
	if (database)
		sqlite3_close(database);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)refreshData {
    [self createLineList];
}


@end
