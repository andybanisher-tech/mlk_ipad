//
//  MerchTTViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 14.06.12.
//
//

#import "MerchTTViewController.h"
#import "CameraViewController.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

@interface MerchTTViewController ()

@end

@implementation MerchTTViewController

static sqlite3 *database = nil;

@synthesize isViewPushed, inVisit;
@synthesize propIdList, propNameList, propTypeList, propValueList, propSendStatusList,propMultiple;
@synthesize selectedForPropId, valueForProperty, custAccount, selectedDate, propElementListId;
@synthesize propertyListViewController;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //NavBar Setup
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    if (isViewPushed == NO) {

        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
        self.navigationItem.rightBarButtonItem = barButton;
	}
    
    self.navigationItem.title = @"Паспорт точки";
    UIImageView *bgImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];

    [self.tableView setBackgroundView:bgImage];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    if (selectedDate == nil) {
        selectedDate = [dateFormatter stringFromDate:date];
    }
    
    if (inVisit)
        [self createTodayPropValue];
    else
        [self propListCreate];
    
    propElementListId = @"null";
}

- (void)propListCreate {
    propIdList                             = [NSMutableArray new];
	NSMutableArray *propIdToLiveInArray    = [NSMutableArray array];
    
    propNameList                           = [NSMutableArray new];
	NSMutableArray *propNameToLiveInArray  = [NSMutableArray array];
    
    propTypeList                           = [NSMutableArray new];
	NSMutableArray *propTypeToLiveInArray  = [NSMutableArray array]; 
    
    propValueList                          = [NSMutableArray new];
	NSMutableArray *propValueToLiveInArray = [NSMutableArray array]; 
    
    propSendStatusList                          = [NSMutableArray new];
	NSMutableArray *propSendStatusToLiveInArray = [NSMutableArray array];
    
    propMultiple                                = [NSMutableArray new];
    NSMutableArray *propMultipleToLiveInArray   = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select PropertyId, PropertyType, PropertyName, isMultiple from MerchTTProperties where 1=1 and exists(select * from CustTable where CustTable.CustAccount == ? and CustTable.TTId == MerchTTProperties.TTId) order by PropertyName";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *propertyId   = @"";
                NSString *propetyType  = @"";
                NSString *propertyName = @"";
                NSString *multiple     = @"NO";
                NSString *propValue    = @"";
                NSString *sendStatus   = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    propertyId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    propetyType  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    propertyName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                unsigned int multipleVal = sqlite3_column_int(selectstmt, 3);
                if (multipleVal == 1) {
                    multiple = @"YES";
                }
                
                const char *sql_2;
                
                //sql_2 = "select Value, SendStatus from TTPropertiesValue where Date <= ? and PropertyId = ? and CustAccount = ? and Value != '' order by Date desc";
                sql_2 = "select Value, SendStatus from TTPropertiesValue where Date <= ? and PropertyId = ? and CustAccount = ? order by Date desc";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) 
                {

                    NSString *strDate = [ASPFunctions changeDateFormatOfString:selectedDate];

                    sqlite3_bind_text(selstmt_2, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 2, [propertyId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW) 
                    {
                        if (sqlite3_column_text(selstmt_2, 0))
                            propValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                        
                        NSLog(@"propVal for refresh - %@",propValue);
                        
                        if (sqlite3_column_text(selstmt_2, 1))
                            sendStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 1)];
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                [propIdToLiveInArray         addObject:propertyId];
                [propNameToLiveInArray       addObject:propertyName];
                [propTypeToLiveInArray       addObject:propetyType];
                [propValueToLiveInArray      addObject:propValue];
                [propSendStatusToLiveInArray addObject:sendStatus];
                [propMultipleToLiveInArray   addObject:multiple];
                
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *propIdToLiveInDict     = [NSDictionary dictionaryWithObject:propIdToLiveInArray forKey:@"propId"];
    NSDictionary *propNameToLiveInDict   = [NSDictionary dictionaryWithObject:propNameToLiveInArray forKey:@"propName"];
    NSDictionary *propTypeToLiveInDict   = [NSDictionary dictionaryWithObject:propTypeToLiveInArray forKey:@"propType"];
    NSDictionary *propValueToLiveInDict  = [NSDictionary dictionaryWithObject:propValueToLiveInArray forKey:@"propValue"];
    NSDictionary *propStatusToLiveInDict = [NSDictionary dictionaryWithObject:propSendStatusToLiveInArray forKey:@"sendStatus"];
    NSDictionary *propMultipleToLiveInDict = [NSDictionary dictionaryWithObject:propMultipleToLiveInArray forKey:@"multiple"];
    
    [propIdList         addObject:propIdToLiveInDict];
    [propNameList       addObject:propNameToLiveInDict];
    [propTypeList       addObject:propTypeToLiveInDict];
    [propValueList      addObject:propValueToLiveInDict];
    [propSendStatusList addObject:propStatusToLiveInDict];
    [propMultiple       addObject:propMultipleToLiveInDict];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return [propIdList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSDictionary *dictionary = [propIdList objectAtIndex:section];
    NSArray		 *array      = [dictionary objectForKey:@"propId"];
    
    return [array count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel     *label = nil;
    
    NSDictionary	*dictionary = [propNameList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"propName"];
    NSString		*cellValue	= [array objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionaryType = [propTypeList objectAtIndex:0];
    NSArray			*arrayType		= [dictionaryType objectForKey:@"propType"];
    NSString		*cellValueType	= [arrayType objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionaryValue = [propValueList objectAtIndex:0];
    NSArray			*arrayValue		 = [dictionaryValue objectForKey:@"propValue"];
    NSString		*cellValueValue	 = [arrayValue objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionarySS   = [propSendStatusList objectAtIndex:0];
    NSArray			*arraySS		= [dictionarySS objectForKey:@"sendStatus"];
    NSString		*cellSS         = [arraySS objectAtIndex:indexPath.row];
    
    if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
		UIFont *cellFont       = [UIFont systemFontOfSize:20.0];
		UIFont *detailCellFont = [UIFont systemFontOfSize:10.0];
        
        cell.textLabel.font       = cellFont;
        cell.detailTextLabel.font = detailCellFont;
        
        label = [[UILabel	alloc] initWithFrame:CGRectMake(360, 0, 170.0, 48.f)];
        
        label.tag = 1;
        label.text = cellValueValue;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor blackColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
    if (! label)
	{
        label = (UILabel*)[cell viewWithTag:1];
        label.text = cellValueValue;
    }
	
    [cell.contentView addSubview:label];
    
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    
    if ([cellValueType isEqualToString:@"List"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if ([cellValueType isEqualToString:@"Boolean"]) {
        //Switch
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchview.tag = indexPath.row;
        switchview.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.8];
        switchview.tintColor = UIColor.clearColor;
        switchview.onTintColor = [ASPFunctions colorFromHex:@"00b4ff"];
        switchview.layer.cornerRadius = switchview.bounds.size.height / 2.0;
        
        cell.accessoryView = switchview;
            
        if ([cellValueValue isEqualToString:@"Yes"])
            switchview.on = YES;
        else
            switchview.on = FALSE;
            
        [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventTouchUpInside];

        label.text = @"";
    }
    
    if ([cellValueType isEqualToString:@"Photo"]) {
        NSString *imageName;

        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;

        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];

        NSString *strDate;

        if (selectedDate) {

            strDate = [ASPFunctions changeDateFormatOfString:selectedDate];
        }
        else
            strDate = [dateFormatter stringFromDate:date];

        NSDictionary	*dictionary = [propIdList objectAtIndex:0];
        NSArray			*array		= [dictionary objectForKey:@"propId"];
        NSString		*propId  	= [array objectAtIndex:indexPath.row];

        UIImage *image = [self getTTImage:strDate property:propId];


        if (image) {
            if ([cellSS isEqual:@"Sended"])
                imageName = ACImageNameBlueCameraSelected;
            else
                imageName = ACImageNameWhiteCameraSelected;
        } else {
            imageName = ACImageNameWhiteCamera;
        }

        UIImageView *imv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];

        cell.accessoryView = imv;
        label.text = @"";
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", cellValue];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MMM_YYYY];
    
    if ([selectedDate isEqualToString:[dateFormatter stringFromDate:date]]) {
        if (inVisit == YES)
            cell.userInteractionEnabled = YES;
        else
        {
            cell.userInteractionEnabled = NO;
        }
    } else {
        cell.userInteractionEnabled = NO;
    }
    return cell;
}


-(UIImage *)getTTImage:(NSString *)strDate property:(NSString*)property{
    UIImage *image = nil;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Image from TTPropertiesValue where PropertyId = ? and CustAccount = ? and Date = ?";

        sqlite3_stmt *selectstmt;

        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);

            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSData *imgData = nil;

                if (sqlite3_column_blob(selectstmt, 0))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 0) length:sqlite3_column_bytes(selectstmt, 0)];

                    image = [UIImage imageWithData:imgData];
                }
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    } else {
        sqlite3_close(database);
    }

    return image;

}

- (void)updateSwitchAtIndexPath:(id)sender {
    UISwitch *switchView = sender;
    propElementListId    = @"null";
    
    NSDictionary	*dictionary = [propIdList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"propId"];
    NSString		*propId  	= [array objectAtIndex:switchView.tag];
    
    selectedForPropId = propId;
    
    if ([switchView isOn]) {
        valueForProperty = @"Yes";
        
        [self readValue];
    } else {
        valueForProperty = @"No";
        
        [self readValue];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = UIColor.clearColor;
}

- (void)refreshData{

    [self propListCreate];
    [self.tableView reloadData];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary	*dictionary = [propIdList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"propId"];
    NSString		*propId  	= [array objectAtIndex:indexPath.row];
    
    selectedForPropId = propId;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSDictionary	*dictionaryType = [propTypeList objectAtIndex:0];
    NSArray			*arrayType		= [dictionaryType objectForKey:@"propType"];
    NSString		*cellValueType	= [arrayType objectAtIndex:indexPath.row];
    
    NSDictionary	*dictPropName   = [propNameList objectAtIndex:0];
    NSArray			*arrayPropName	= [dictPropName objectForKey:@"propName"];
    NSString		*propName   	= [arrayPropName objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionaryValue = [propValueList objectAtIndex:0];
    NSArray			*arrayValue		 = [dictionaryValue objectForKey:@"propValue"];
    NSString		*propValue	     = [arrayValue objectAtIndex:indexPath.row];
    
    NSDictionary	*dictionaryMultiple = [propMultiple objectAtIndex:0];
    NSArray			*arrayMultiple		 = [dictionaryMultiple objectForKey:@"multiple"];
    NSString		*propMultiple	     = [arrayMultiple objectAtIndex:indexPath.row];
    
    if ([cellValueType isEqualToString:@"List"])
        [self showList:cell rowNum:indexPath.row+1 propId:propId multiple:propMultiple];
    
    if ([cellValueType isEqualToString:@"Integer"] || [cellValueType isEqualToString:@"String"]) {
        UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"Введите текст" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        if ([cellValueType isEqualToString:@"Integer"]) {
            alertVC.title = @"Введите значение";
        }
        
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            self->alertTextField = textField;
            self->alertTextField.placeholder = propName;
            self->alertTextField.text = propValue;
            if ([cellValueType isEqualToString:@"Integer"]) {
                self->alertTextField.keyboardType = UIKeyboardTypeNumberPad;
                [self->alertTextField addTarget:self action:@selector(alertViewTextFieldDidChanged) forControlEvents:UIControlEventEditingChanged];
            }
        }];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            self->valueForProperty  = self->alertTextField.text;
            self->propElementListId = @"null";
            
            [self readValue];
        }];
        
        [alertVC addAction:okAction];
        
        [ASPFunctions.topMostController presentViewController:alertVC animated:YES completion:nil];
    }
    
    if ([cellValueType isEqualToString:@"Photo"]) {
        [self makePhoto:propId];
    }
}

- (void)alertViewTextFieldDidChanged {
    NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    
    for (int y = 0; y < [alertTextField.text length]; y++) {
        unichar c = [alertTextField.text characterAtIndex:y];
        
        if ([myCharSet characterIsMember:c]) {
        }
        else 
        {
            alertTextField.text = [alertTextField.text substringToIndex:[alertTextField.text length] - 1];
        }
    }
}

- (void)finalizeStatements {
	if (database) 
		sqlite3_close(database);
}


- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSMutableDictionary *)getMultipleSelectedCollection:(NSString *)propId custAccount:(NSString *)custAcc strDate:(NSString *)strDate {
    NSMutableDictionary* outputDict = [[NSMutableDictionary alloc]init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_2;
        
        sql_2 = "select Value, ElementListId from TTPropertiesValue where Date = ? and PropertyId = ? and CustAccount = ? ";
        
        sqlite3_stmt *selstmt_2;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_2, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 2, [propId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 3, [custAcc UTF8String], -1, SQLITE_TRANSIENT);

            if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
                NSString* valueStr = @"";
                NSString* elemIdStr = @"";
                if (sqlite3_column_text(selstmt_2, 0))
                    valueStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                
                if (sqlite3_column_text(selstmt_2, 1))
                    elemIdStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 1)];
                if (valueStr.length>0 && elemIdStr.length>0) {
                    NSArray* valueArray = [valueStr componentsSeparatedByString:@","];
                    NSArray* elemIdArray = [elemIdStr componentsSeparatedByString:@","];
                    for(unsigned int i=0; i<[valueArray count]; i++) {
                        NSMutableDictionary* addRow = [[NSMutableDictionary alloc]init];
                        [addRow setObject:[valueArray objectAtIndex:i] forKey:@"elementName"];
                        [addRow setObject:[elemIdArray objectAtIndex:i] forKey:@"elementId"];
                        [addRow setObject:propId forKey:@"propId"];
                        
                        [outputDict setObject:addRow forKey:[elemIdArray objectAtIndex:i]];
                        addRow = nil;
                    }
                }
            }
        }
        sqlite3_finalize(selstmt_2);
    }
    return outputDict;
}

- (void)multipleSelect:(NSMutableDictionary *)selectedCollection propId:(NSString *)propId {
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString     = [timeFormat stringFromDate:date];
    NSString *dateTimeString = [NSString stringWithFormat:@"%@ %@", strDate, timeString];
    
    NSString *valueString = @"";
    NSString *elementIdString = @"";
    
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_tt;
        NSString   *ttid;
        
        sql_tt = "select TTId from CustTable where CustAccount = ?";
        
        sqlite3_stmt *selstmt_tt;
        
        if (sqlite3_prepare_v2(database, sql_tt, -1, &selstmt_tt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_tt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_tt) == SQLITE_ROW) {
                if (sqlite3_column_text(selstmt_tt, 0))
                    ttid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_tt, 0)];
            }
        }
        sqlite3_finalize(selstmt_tt);
        int i = 0;
        NSString* stringFormat;
        for(NSString *collectionKey in selectedCollection) {
            
            NSDictionary* collectionItem = [selectedCollection objectForKey:collectionKey];
            
            if (i==0) {
                stringFormat = @"%@%@";
            } else {
                stringFormat = @"%@,%@";
            }
            valueString = [NSString stringWithFormat:stringFormat,valueString,[collectionItem objectForKey:@"elementName"]];
            elementIdString = [NSString stringWithFormat:stringFormat,elementIdString,[collectionItem objectForKey:@"elementId"]];
            i++;
        }
        
        const char* sql_2;
        sql_2 = "select Value from TTPropertiesValue where CustAccount = ? and PropertyId = ? and Date = ?";
        
        sqlite3_stmt *selstmt_2;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_2, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 2, [propId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
                const char *sql_3 = "update TTPropertiesValue Set Value = ?, SendStatus = ?, ElementListId = ?, ttId = ?, CreatedDateTime = ?, isMultiple = 1 where PropertyId = ? and CustAccount = ? and Date = ?";
                
                sqlite3_stmt *updateStmt;
                
                if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK)
                {
                    if (valueString.length>0) {
                        sqlite3_bind_text(updateStmt, 1, [valueString UTF8String], -1, SQLITE_TRANSIENT);
                    } else {
                        sqlite3_bind_text(updateStmt, 1, NULL, -1, SQLITE_TRANSIENT);
                    }
                    sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (![elementIdString isEqualToString:@""])
                        sqlite3_bind_text(updateStmt, 3, [elementIdString UTF8String], -1, SQLITE_TRANSIENT);
                    else
                        sqlite3_bind_text(updateStmt, 3, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_bind_text(updateStmt, 4, [ttid UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 5, [dateTimeString UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 6, [propId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 7, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 8, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_step(updateStmt);
                    sqlite3_finalize(updateStmt);
                }
            } else {
                char *sErrMsg;
                sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
                
                static sqlite3_stmt *addStmt;
                
                const char *sql = "insert or ignore into TTPropertiesValue (PropertyId, Value, Date, CustAccount, SendStatus, ttId, ElementListId, isMultiple, CreatedDateTime) Values(?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                sqlite3_bind_text(addStmt, 1, [propId UTF8String], -1, SQLITE_TRANSIENT);
                
                if (valueString.length>0) {
                    sqlite3_bind_text(addStmt, 2, [valueString UTF8String], -1, SQLITE_TRANSIENT);
                } else {
                    sqlite3_bind_text(addStmt, 2, NULL, -1, SQLITE_TRANSIENT);
                }
                
                sqlite3_bind_text(addStmt, 3, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 6, [ttid UTF8String], -1, SQLITE_TRANSIENT);
                
                if (![elementIdString isEqualToString:@""])
                    sqlite3_bind_text(addStmt, 7, [elementIdString UTF8String], -1, SQLITE_TRANSIENT);
                else
                    sqlite3_bind_text(addStmt, 7, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_bind_int(addStmt, 8, 1);
                sqlite3_bind_text(addStmt, 9, [dateTimeString UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(addStmt) != SQLITE_DONE)
                {
                    NSLog(@"Commit Failed!");
                }
                
                sqlite3_finalize(addStmt);
                sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
                sqlite3_close(database);
            }
        }
        sqlite3_finalize(selstmt_2);
    } else {
        sqlite3_close(database);
    }
    
    [self refreshData];
    
    if (propertyListViewController.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        propertyListViewController = nil;
    }
}

- (void)elementIsSelected:(NSString *)listElement propId:(NSString *)propId propElementId:(NSString *)propElementId {
    valueForProperty  = listElement;
    propElementListId = propElementId;
    
    [self readValue];
    
    if (propertyListViewController.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        propertyListViewController = nil;
    }
}

- (void)readValue {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (valueForProperty)
        [self addPropValue:strDate property:selectedForPropId value:valueForProperty];
    
    [self refreshData];
}

- (void)addPropValue:(NSString*)valueDate property:(NSString*)property value:(NSString*)value {
    NSDate          *date       = NSDate.date;
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString     = [timeFormat stringFromDate:date];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *dateString = [dateFormat stringFromDate:date];
    
    NSString *dateTimeString = [NSString stringWithFormat:@"%@ %@", valueDate, timeString];
    
    if (! valueDate)
        dateTimeString = [NSString stringWithFormat:@"%@ %@", dateString, timeString];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_tt;
        NSString   *ttid;
        
        sql_tt = "select TTId from CustTable where CustAccount = ?";
        
        sqlite3_stmt *selstmt_tt;
        
        if (sqlite3_prepare_v2(database, sql_tt, -1, &selstmt_tt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_tt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_tt) == SQLITE_ROW) {
                if (sqlite3_column_text(selstmt_tt, 0))
                    ttid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_tt, 0)];
            }
        }
        sqlite3_finalize(selstmt_tt);
    
        const char *sql_2;
        
        sql_2 = "select Value from TTPropertiesValue where CustAccount = ? and PropertyId = ? and Date = ?";
        
        sqlite3_stmt *selstmt_2;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_2, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 2, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 3, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_2) == SQLITE_ROW) 
            {
                const char *sql_3 = "update TTPropertiesValue Set Value = ?, SendStatus = ?, ElementListId = ?, ttId = ?, CreatedDateTime = ? where PropertyId = ? and CustAccount = ? and Date = ?";
                
                sqlite3_stmt *updateStmt;
                
                if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(updateStmt, 1, [value UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (![propElementListId isEqualToString:@"null"])
                        sqlite3_bind_text(updateStmt, 3, [propElementListId UTF8String], -1, SQLITE_TRANSIENT);
                    else
                        sqlite3_bind_text(updateStmt, 3, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_bind_text(updateStmt, 4, [ttid UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 5, [dateTimeString UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 6, [property UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 7, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 8, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
                    
                    sqlite3_step(updateStmt);
                    sqlite3_finalize(updateStmt);
                }
            } else {
                char *sErrMsg;
                sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
                
                static sqlite3_stmt *addStmt;
                
                const char *sql = "insert or ignore into TTPropertiesValue (PropertyId, Value, Date, CustAccount, SendStatus, ttId, ElementListId, CreatedDateTime) Values(?, ?, ?, ?, ?, ?, ?, ?)";
                
                if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                sqlite3_bind_text(addStmt, 1, [property UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [value UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 6, [ttid UTF8String], -1, SQLITE_TRANSIENT);
                
                if (![propElementListId isEqualToString:@"null"])
                    sqlite3_bind_text(addStmt, 7, [propElementListId UTF8String], -1, SQLITE_TRANSIENT);
                else
                    sqlite3_bind_text(addStmt, 7, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_bind_text(addStmt, 8, [dateTimeString UTF8String], -1, SQLITE_TRANSIENT);
                
                if (sqlite3_step(addStmt) != SQLITE_DONE)
                {
                    NSLog(@"Commit Failed!");
                }
                
                sqlite3_finalize(addStmt);
                sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
                sqlite3_close(database);
            }
        }
        sqlite3_finalize(selstmt_2);
    } else
        sqlite3_close(database);
}

- (void)showList:(UITableViewCell*)cell rowNum:(NSInteger)rowNum propId:(NSString *)propId multiple:(NSString *)multiple {
    if ([multiple isEqualToString:@"YES"]) {
        propertyListViewController = [[PropertyMultipleListViewController alloc] init];
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;
        
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        NSString *strDate = [dateFormatter stringFromDate:date];
        propertyListViewController.savedCollection = [self getMultipleSelectedCollection:propId custAccount:custAccount strDate:strDate];
    } else {
        propertyListViewController = [[PropertyListViewController alloc] init];
    }
    
    propertyListViewController.delegate   = self;
    propertyListViewController.propertyId = propId;
    
    propertyListViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    if (propertyListViewController.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        propertyListViewController = nil;
    } else {
        propertyListViewController.popoverPresentationController.sourceView = cell;
        propertyListViewController.popoverPresentationController.sourceRect = CGRectMake(cell.bounds.origin.x, cell.bounds.origin.y+(44*rowNum), cell.bounds.size.width, cell.bounds.size.height);
        [self presentViewController:propertyListViewController animated:YES completion:nil];
    }
}

- (void)makePhoto:(NSString *)property{
    if ([self custInVisitPhoto:custAccount]) {
        CameraViewController *fvController = [[CameraViewController alloc] init];
    
        fvController.propertyId  = property;
        fvController.photoType   = @"tt";
        fvController.custAccount = custAccount;
        fvController.inVisit     = [self custInVisitPhoto:custAccount];

        [self presentViewController:fvController animated:YES completion:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                                 selector:@selector(updateTable)
                                                     name:kTTPhotoSaved
                                                   object:nil];
        fvController = nil;
    } else {
        [AlertWorkerObjc alertWithTitle:@"Для создания фотографии клиент должен быть в режиме посещения"];
    }
}

- (void)updateTable {
    [self.tableView reloadData];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

-(BOOL)custInVisit:(NSString *)custAcc {
    BOOL visit = YES;//FALSE;
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                visit = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return visit;
}

-(BOOL)custInVisitPhoto:(NSString *)custAcc {
    BOOL visit = FALSE;
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Status from CustForRoute where DateOfRoute = ? and CustAccount = ? and Status = ?";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [@"visit" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                visit = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return visit;
}


- (void)createTodayPropValue {
    propIdList                             = [NSMutableArray new];
	NSMutableArray *propIdToLiveInArray    = [NSMutableArray array];
    
    propNameList                           = [NSMutableArray new];
	NSMutableArray *propNameToLiveInArray  = [NSMutableArray array];
    
    propTypeList                           = [NSMutableArray new];
	NSMutableArray *propTypeToLiveInArray  = [NSMutableArray array];
    
    propValueList                          = [NSMutableArray new];
	NSMutableArray *propValueToLiveInArray = [NSMutableArray array];
    
    propSendStatusList                          = [NSMutableArray new];
	NSMutableArray *propSendStatusToLiveInArray = [NSMutableArray array];
    
    propMultiple                                = [NSMutableArray new];
    NSMutableArray *propMultipleToLiveInArray   = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select PropertyId, PropertyType, PropertyName, isMultiple from MerchTTProperties where 1=1 and exists(select * from CustTable where CustTable.CustAccount == ? and CustTable.TTId == MerchTTProperties.TTId) order by PropertyName";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				NSString *propertyId   = @"";
                NSString *propetyType  = @"";
                NSString *propertyName = @"";
                NSString *multiple     = @"NO";
                NSString *propValue    = @"";
                NSString *sendStatus   = @"";
                NSString *valueDate    = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    propertyId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    propetyType  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    propertyName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                unsigned int multipleVal = sqlite3_column_int(selectstmt, 3);
                if (multipleVal == 1) {
                    multiple = @"YES";
                }
                
                const char *sql_2;
                
                //sql_2 = "select Value, SendStatus, Date, ElementListId from TTPropertiesValue where Date <= ? and PropertyId = ? and CustAccount = ? and Value != '' order by Date desc";
                
                //sql_2 = "select Value, SendStatus, Date, ElementListId from TTPropertiesValue where Date <= ? and PropertyId = ? and CustAccount = ? order by Date desc";
                
                sql_2 = "select Value, SendStatus, Date, ElementListId from TTPropertiesValue where PropertyId = ? and CustAccount = ? order by Date desc";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK)
                {
                    NSString *strDate = [ASPFunctions changeDateFormatOfString:selectedDate];
                    //sqlite3_bind_text(selstmt_2, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 1, [propertyId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW)
                    {
                        if (sqlite3_column_text(selstmt_2, 0))
                            propValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                        
                        if (sqlite3_column_text(selstmt_2, 1))
                            sendStatus = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 1)];
                        
                        if (sqlite3_column_text(selstmt_2, 2))
                            valueDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 2)];
                        
                        if (sqlite3_column_text(selstmt_2, 3))
                            propElementListId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 3)];
                        
                        if (! [valueDate isEqualToString:strDate])
                            [self addTodayPropValue:strDate property:propertyId value:propValue];
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                [propIdToLiveInArray         addObject:propertyId];
                [propNameToLiveInArray       addObject:propertyName];
                [propTypeToLiveInArray       addObject:propetyType];
                [propValueToLiveInArray      addObject:propValue];
                [propSendStatusToLiveInArray addObject:sendStatus];
                [propMultipleToLiveInArray   addObject:multiple];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *propIdToLiveInDict     = [NSDictionary dictionaryWithObject:propIdToLiveInArray forKey:@"propId"];
    NSDictionary *propNameToLiveInDict   = [NSDictionary dictionaryWithObject:propNameToLiveInArray forKey:@"propName"];
    NSDictionary *propTypeToLiveInDict   = [NSDictionary dictionaryWithObject:propTypeToLiveInArray forKey:@"propType"];
    NSDictionary *propValueToLiveInDict  = [NSDictionary dictionaryWithObject:propValueToLiveInArray forKey:@"propValue"];
    NSDictionary *propStatusToLiveInDict = [NSDictionary dictionaryWithObject:propSendStatusToLiveInArray forKey:@"sendStatus"];
    NSDictionary *propMultipleToLiveInDict = [NSDictionary dictionaryWithObject:propMultipleToLiveInArray forKey:@"multiple"];
    
    [propIdList         addObject:propIdToLiveInDict];
    [propNameList       addObject:propNameToLiveInDict];
    [propTypeList       addObject:propTypeToLiveInDict];
    [propValueList      addObject:propValueToLiveInDict];
    [propSendStatusList addObject:propStatusToLiveInDict];
    [propMultiple       addObject:propMultipleToLiveInDict];
}

- (void)addTodayPropValue:(NSString*)valueDate property:(NSString*)property value:(NSString*)value {
    NSDate          *date       = NSDate.date;
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    
    NSString *timeString     = [timeFormat stringFromDate:date];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *dateString = [dateFormat stringFromDate:date];
    
    NSString *dateTimeString = [NSString stringWithFormat:@"%@ %@", valueDate, timeString];
    
    if (! valueDate)
        dateTimeString = [NSString stringWithFormat:@"%@ %@", dateString, timeString];
    
    const char *sql_tt;
    NSString   *ttid;
    
    sql_tt = "select TTId from CustTable where CustAccount = ?";
    
    sqlite3_stmt *selstmt_tt;
    
    if (sqlite3_prepare_v2(database, sql_tt, -1, &selstmt_tt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selstmt_tt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selstmt_tt) == SQLITE_ROW) {
            if (sqlite3_column_text(selstmt_tt, 0))
                ttid = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_tt, 0)];
        }
    }
    sqlite3_finalize(selstmt_tt);
    
    const char *sql_2;
    
    sql_2 = "select Value from TTPropertiesValue where CustAccount = ? and PropertyId = ? and Date = ?";
    
    sqlite3_stmt *selstmt_2;
    
    if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selstmt_2, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selstmt_2, 2, [property UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selstmt_2, 3, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
            const char *sql_3 = "update TTPropertiesValue Set Value = ?, SendStatus = ?, ttId = ?, CreatedDateTime = ? where PropertyId = ? and CustAccount = ? and Date = ?";
            
            sqlite3_stmt *updateStmt;
            
            if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(updateStmt, 1, [value UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 3, [ttid UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 4, [dateTimeString UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 5, [property UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 6, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 7, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_step(updateStmt);
                sqlite3_finalize(updateStmt);
            }
        } else {
            char *sErrMsg;
            sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &sErrMsg);
            
            static sqlite3_stmt *addStmt;
            
            const char *sql = "insert or ignore into TTPropertiesValue (PropertyId, Value, Date, CustAccount, SendStatus, ttId, ElementListId, CreatedDateTime) Values(?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [value UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [ttid UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [propElementListId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 8, [dateTimeString UTF8String], -1, SQLITE_TRANSIENT);
            
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
            sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
            sqlite3_close(database);
        }
    }
    sqlite3_finalize(selstmt_2);
}

@end
