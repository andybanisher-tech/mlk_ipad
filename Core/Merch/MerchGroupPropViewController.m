//
//  MerchGroupPropViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 30.05.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "MerchGroupPropViewController.h"

#import "GeneratedAssetSymbols.h"

@implementation MerchGroupPropViewController

static sqlite3 *database = nil;

@synthesize propIdList, propNameList, propTypeList, propValueList, propSendStatusList;
@synthesize groupId, brandId, listElement, selectedForPropId, valueForProperty, custAccount, selectedDate, propElementListId;
@synthesize delegate;
@synthesize custInVisit;

- (void)createTodayPropValue {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select PropertyId from MerchGroupProperties where GroupId = ? and exists(select * from MerchGroupBrands where MerchGroupBrands.GroupId == MerchGroupProperties.GroupId and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == MerchGroupBrands.BrandId)) order by PropertyName";
        
        sqlite3_stmt *selectstmt_1;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt_1, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt_1, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt_1, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt_1) == SQLITE_ROW)
			{
				NSString *propertyId   = @"";
                
                if (sqlite3_column_text(selectstmt_1, 0))
                    propertyId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt_1, 0)];
                
                const char *sql_2;
                
                sql_2 = "select Value, Date, ElementListId from PropertiesValue where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date <= ? and Value != '' order by Date desc";
                
                sqlite3_stmt *selstmt_11;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_11, NULL) == SQLITE_OK)
                {
                    sqlite3_bind_text(selstmt_11, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_11, 2, [brandId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_11, 3, [propertyId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_11, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_11, 5, [selectedDate UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_11) == SQLITE_ROW) {
                        NSString *propValue    = @"";
                        NSString *valueDate    = @"";
                        
                        propElementListId = @"null";
                        
                        if (sqlite3_column_text(selstmt_11, 0))
                            propValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_11, 0)];
                        
                        if (sqlite3_column_text(selstmt_11, 1))
                            valueDate = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_11, 1)];
                        
                        if (sqlite3_column_text(selstmt_11, 2))
                            propElementListId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_11, 2)];
                        
                        if (![valueDate isEqualToString:selectedDate])
                            [self addTodayPropValue:selectedDate group:groupId brandId:brandId property:propertyId value:propValue];
                    }
                }
                sqlite3_finalize(selstmt_11);
            }
		}
        sqlite3_finalize(selectstmt_1);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
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
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select PropertyId, PropertyType, PropertyName from MerchGroupProperties where GroupId = ? and exists(select * from MerchGroupBrands where MerchGroupBrands.GroupId == MerchGroupProperties.GroupId and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == MerchGroupBrands.BrandId)) order by PropertyName";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
            sqlite3_bind_text(selectstmt, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *propertyId   = @"";
                NSString *propetyType  = @"";
                NSString *propertyName = @"";
                NSString *propValue    = @"";
                NSString *sendStatus   = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    propertyId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    propetyType  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    propertyName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                const char *sql_2;
                
                sql_2 = "select Value, SendStatus from PropertiesValue where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date <= ? and Value != '' order by Date desc";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(selstmt_2, 1, [groupId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 2, [brandId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 3, [propertyId UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_2, 5, [selectedDate UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW) 
                    {
                        if (sqlite3_column_text(selstmt_2, 0))
                            propValue = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                        
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
    
    [propIdList         addObject:propIdToLiveInDict];
    [propNameList       addObject:propNameToLiveInDict];
    [propTypeList       addObject:propTypeToLiveInDict];
    [propValueList      addObject:propValueToLiveInDict];
    [propSendStatusList addObject:propStatusToLiveInDict];
}

- (void)viewDidLoad {
    propElementListId = @"null";
    
    if (selectedDate == nil) {
        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;
        
        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
        
        selectedDate = [dateFormatter stringFromDate:date];
    }
    
    [super viewDidLoad];
    
    [self propListCreate];
    [NSNotificationCenter.defaultCenter addObserver:self
                                             selector:@selector(refreshData)
                                                 name:@"BrandImageSaved" object:nil];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [propIdList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.brandId)
        return 0;
    //Number of rows it should expect should be based on the section
    NSDictionary *dictionary = [propIdList objectAtIndex:section];
    NSArray		 *array      = [dictionary objectForKey:@"propId"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *label = nil;

    NSDictionary	*dictionaryIDs = [propIdList objectAtIndex:0];
    NSArray			*arrayIDs	= [dictionaryIDs objectForKey:@"propId"];
    NSString		*propertyID	= [arrayIDs objectAtIndex:indexPath.row];
    
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
		UIFont *detailCellFont = [UIFont systemFontOfSize:14.0];
        
        cell.textLabel.font       = cellFont;
        cell.detailTextLabel.font = detailCellFont;
        //cell.textLabel.textColor = UIColor.whiteColor;
        
        label = [[UILabel	alloc] initWithFrame:CGRectMake(300, 14, 180.0, 24)];
        
        label.tag = 1;
        label.text = cellValueValue;
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        label.font = cellFont;
        cell.accessoryType = UITableViewCellAccessoryNone;
//        cell.accessoryView = UITableViewCellAccessoryNone;
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
//    cell.accessoryView = UITableViewCellAccessoryNone;
    
    if (!label)
	{
        label = (UILabel*)[cell viewWithTag:1];
        label.text = cellValueValue;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }
	
    [cell.contentView addSubview:label];
    
    if ([cellValueType isEqualToString:@"Boolean"]) {
        //Switch
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventTouchUpInside];
        switchview.tag = indexPath.row;
        switchview.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.8];
        switchview.tintColor = UIColor.clearColor;
        switchview.layer.cornerRadius = switchview.bounds.size.height / 2.0;
        
        cell.accessoryView = switchview;
        if ([cellValueValue isEqualToString:@"Yes"]) {
            switchview.on = YES;
        } else {
            switchview.on = NO;
        }

        label.text = @"";
    }
    
    if ([cellValueType isEqualToString:@"List"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        label.text = @"";
    }
    
    if ([cellValueType isEqualToString:@"Photo"]) {
        NSString *imageName;

        NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
        NSDate          *date           = NSDate.date;

        [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];

        NSString *strDate;

        if (selectedDate) {
            NSDateFormatter *selDateFormatter = [[NSDateFormatter alloc] init];
            [selDateFormatter setDateFormat:dateFormat_dd_MMM_YYYY];
            NSDate *selDate = [selDateFormatter dateFromString:selectedDate];
            strDate = [dateFormatter stringFromDate:selDate];
        }
        else
            strDate = [dateFormatter stringFromDate:date];

        UIImage *image = [self getBrandImage:strDate group:groupId brandId:brandId property:propertyID];


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
    NSString *dateString = [dateFormatter stringFromDate:date];
    if (brandId) {
        if ([selectedDate isEqualToString:dateString]) {
            if (custInVisit == YES)
                cell.userInteractionEnabled = YES;
            else
            {
                cell.userInteractionEnabled = NO;
            }
        } else {
            cell.userInteractionEnabled = NO;
        }
    } else {
        cell.userInteractionEnabled = NO;
    }

    return cell;
}

- (void)updateSwitchAtIndexPath:(id)sender {
    UISwitch *switchView = sender;

    NSDictionary	*dictionary = [propIdList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"propId"];
    NSString		*propId  	= [array objectAtIndex:switchView.tag];
            
    selectedForPropId = propId;
    propElementListId = nil;
            
    if ([switchView isOn]) {
        [self.delegate elementIsSelected:@"Yes" propId:selectedForPropId propElementId:propElementListId];
    } else {
        [self.delegate elementIsSelected:@"No" propId:selectedForPropId propElementId:propElementListId];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //UIColor *mycolor= [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:128.0/255.0 alpha:1.0];
    cell.backgroundColor = UIColor.clearColor;
    
}

- (void)refreshData{
    [self propListCreate];
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary	*dictionary = [propIdList objectAtIndex:0];
    NSArray			*array		= [dictionary objectForKey:@"propId"];
    NSString		*propId  	= [array objectAtIndex:indexPath.row];
    
    selectedForPropId = propId;
    propElementListId = @"null";
    
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
    
    if ([cellValueType isEqualToString:@"List"])
        [self.delegate showList:cell rowNum:indexPath.row+1 propId:propId];
    
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
            [self.delegate elementIsSelected:self->alertTextField.text propId:self->selectedForPropId propElementId:self->propElementListId];
        }];
        
        [alertVC addAction:okAction];
        
        [ASPFunctions.topMostController presentViewController:alertVC animated:YES completion:nil];
    }
    
    if ([cellValueType isEqualToString:@"Photo"]) {
        [self.delegate makePhoto:propId];
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

/*-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.text = @"";
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [self.delegate elementIsSelected:textField.text propId:selectedForPropId];
    
    [textField resignFirstResponder];
    
    return YES; 
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
	return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    //if (isNewText == YES)
    //{
    //    textField.text = @"";
    //    isNewText = FALSE;
    //}
    
    if ([string length] == 0) {
        return YES;
    }
    
    NSDictionary	*dictionaryType = [propTypeList objectAtIndex:0];
    NSArray			*arrayType		= [dictionaryType objectForKey:@"propType"];
    NSString		*cellValueType	= [arrayType objectAtIndex:textField.tag];
    
    if ([cellValueType isEqualToString:@"Integer"]) {
        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    
        for (int y = 0; y < [string length]; y++) {
            unichar c = [string characterAtIndex:y];
        
            if ([myCharSet characterIsMember:c]) 
            {
                return YES;
            }
        }
    } else {
        return YES;
    }
    
    return NO;
}*/

//- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
//{
    //NSDictionary	*dictionaryType = [propTypeList objectAtIndex:0];
    //NSArray			*arrayType		= [dictionaryType objectForKey:@"propType"];
    //NSString		*cellValueType	= [arrayType objectAtIndex:indexPath.row];
//}

- (void)readValue {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    //NSLog([NSString stringWithFormat:@"%@ %@ %@ %@", groupId, brandId, selectedForPropId, valueForProperty]);
    
    if (valueForProperty)
        [self addPropValue:strDate group:groupId brandId:brandId property:selectedForPropId value:valueForProperty];
    
    [self.delegate brandSelected:brandId];
}

- (void)addPropValue:(NSString*)valueDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property value:(NSString*)value {
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql_2;
        
        sql_2 = "select Value from PropertiesValue where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date = ?";
        
        sqlite3_stmt *selstmt_2;
        
        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selstmt_2, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 2, [brand UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selstmt_2, 5, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selstmt_2) == SQLITE_ROW) 
            {
                const char *sql_3 = "update PropertiesValue Set Value = ?, SendStatus = ?, ElementListId = ? where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date = ?";
    
                sqlite3_stmt *updateStmt;
    
                if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(updateStmt, 1, [value UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (![propElementListId isEqualToString:@"null"])
                        sqlite3_bind_text(updateStmt, 3, [propElementListId UTF8String], -1, SQLITE_TRANSIENT);
                    else
                        sqlite3_bind_text(updateStmt, 3, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                    
                    
                    sqlite3_bind_text(updateStmt, 4, [group UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(updateStmt, 5, [brand UTF8String], -1, SQLITE_TRANSIENT);
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
                
                const char *sql = "insert or ignore into PropertiesValue (GroupId, BrandId, PropertyId, Value, Date, CustAccount, SendStatus, ElementListId) Values(?, ?, ?, ?, ?, ?, ?, ?)";
                
                if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                    NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
                
                sqlite3_bind_text(addStmt, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 2, [brand UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 4, [value UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 5, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 6, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(addStmt, 7, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                
                if (![propElementListId isEqualToString:@"null"])
                    sqlite3_bind_text(addStmt, 8, [propElementListId UTF8String], -1, SQLITE_TRANSIENT);
                else
                    sqlite3_bind_text(addStmt, 8, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                
                
                if (sqlite3_step(addStmt) != SQLITE_DONE)
                {
                    NSLog(@"Commit Failed!");
                }
                
                sqlite3_finalize(addStmt);
                sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
                //sqlite3_close(database);
            }
        }
        sqlite3_finalize(selstmt_2);
    } else
        sqlite3_close(database);
}

- (void)addTodayPropValue:(NSString*)valueDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property value:(NSString*)value {
    const char *sql_2;
    
    sql_2 = "select Value from PropertiesValue where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date = ?";
    
    sqlite3_stmt *selstmt_2;
    
    if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) {
        sqlite3_bind_text(selstmt_2, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selstmt_2, 2, [brand UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selstmt_2, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selstmt_2, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(selstmt_2, 5, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selstmt_2) == SQLITE_ROW) {
            const char *sql_3 = "update PropertiesValue Set Value = ?, SendStatus = ? ElementListId = ? where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date = ?";
            
            sqlite3_stmt *updateStmt;
            
            if (sqlite3_prepare_v2(database, sql_3, -1, &updateStmt, NULL) == SQLITE_OK) {
                sqlite3_bind_text(updateStmt, 1, [value UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 2, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
                
                if (![propElementListId isEqualToString:@"null"])
                    sqlite3_bind_text(updateStmt, 3, [propElementListId UTF8String], -1, SQLITE_TRANSIENT);
                else
                    sqlite3_bind_text(updateStmt, 3, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
                
                sqlite3_bind_text(updateStmt, 4, [group UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(updateStmt, 5, [brand UTF8String], -1, SQLITE_TRANSIENT);
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
            
            const char *sql = "insert or ignore into PropertiesValue (GroupId, BrandId, PropertyId, Value, Date, CustAccount, SendStatus, ElementListId) Values(?, ?, ?, ?, ?, ?, ?, ?)";
            
            if (sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
                NSAssert1(0, @"Error while creating add statement. '%s'", sqlite3_errmsg(database));
            
            sqlite3_bind_text(addStmt, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 2, [brand UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 4, [value UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 5, [valueDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 6, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStmt, 7, [@"New" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (![propElementListId isEqualToString:@"null"])
                sqlite3_bind_text(addStmt, 8, [propElementListId UTF8String], -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(addStmt, 8, [@"null" UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(addStmt) != SQLITE_DONE) {
                NSLog(@"Commit Failed!");
            }
            
            sqlite3_finalize(addStmt);
            sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &sErrMsg);
        }
    }
    sqlite3_finalize(selstmt_2);
}

-(UIImage *)getBrandImage:(NSString *)strDate group:(NSString*)group brandId:(NSString*)brand property:(NSString*)property{
    UIImage *image = nil;

    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Image from PropertiesValue where GroupId = ? and BrandId = ? and PropertyId = ? and CustAccount = ? and Date = ?";

        sqlite3_stmt *selectstmt;

        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [group UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [brand UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 3, [property UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 4, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 5, [strDate UTF8String], -1, SQLITE_TRANSIENT);

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

@end
