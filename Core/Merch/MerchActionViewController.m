//
//  MerchActionViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 14.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MerchActionViewController.h"
#import "MyTableCell.h"
#import "OverlayActionViewViewController.h"
#import "MerchActDetViewController.h"

static sqlite3 *database = nil;

@implementation MerchActionViewController

@synthesize actionList,
            actionNameList,
            brandList,
            priceList,
            availQtyList,
            actionTypeList,
            amountSumList,
            amountQtyList,
            setList,
            setDescrList,
            brandId,
            typeId,
            brandIdList;

@synthesize searchBar;
@synthesize i;
@synthesize searching;
@synthesize letUserSelectRow;
@synthesize isViewPushed, mustClosingView, fromMerch;
@synthesize actionMark, actionType;
@synthesize custAccount, custName;
@synthesize endEditInSearch;
@synthesize brandBtn, cBtn; 

#define LABEL_TAG 1 
#define VALUE_TAG 2 
#define TEXTFIELD_TAG 3
#define FIRST_CELL_IDENTIFIER @"TrailItemCell" 
#define SECOND_CELL_IDENTIFIER @"RegularCell" 


- (void)loadView {	
    [super loadView];
    
    [self createItemList];
    
    if (isViewPushed == NO) {
		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStyleDone  target:self action:@selector(cancel_Clicked:)];
        
        barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        
        self.navigationItem.rightBarButtonItem = barButton;

        UIBarButtonItem *markBtn = [[UIBarButtonItem alloc] initWithTitle:@"Марка" style:UIBarButtonItemStyleDone  target:self action:@selector(showMark:)];
        
        brandBtn = markBtn;
        
        UIToolbar* tools = [[UIToolbar alloc] initWithFrame:CGRectMake (0, 1, 300, 44)];
        
        tools.tintColor = [UIColor blackColor];
        
        NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:3];
        
        UIBarButtonItem *bi = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        [buttons addObject:bi];

        [buttons addObject:markBtn];

        UIBarButtonItem *typeButton = [[UIBarButtonItem alloc] initWithTitle:@"Тип акции" style:UIBarButtonItemStyleDone  target:self action:@selector(showType:)];
        
        [buttons addObject:typeButton];

        //UIBarButtonItem *resetBtn = [[UIBarButtonItem alloc] initWithTitle:@"Сбросить фильтр" style:UIBarButtonItemStylePlain  target:self action:@selector(resetFilter:)];
        
        //resetBtn.tintColor = [UIColor redColor];
        
        //[buttons addObject:resetBtn];
        //[resetBtn release];
        
        [tools setItems:buttons animated:NO];

        // and put the toolbar in the nav bar
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:tools];
    }
    
    //SearchBar
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 1024.0, 40.0)];
    searchBar.delegate = self;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.tintColor = [UIColor blackColor];
    searchBar.searchTextField.backgroundColor = UIColor.whiteColor;
    
    searching        = NO;
	letUserSelectRow = YES;
    
    [self.view addSubview:searchBar];
    
    myTableView = [[UITableView alloc]initWithFrame:CGRectMake(0.0, 40.0, 1024.0, 650.0)];
    
    myTableView.delegate = self;
    myTableView.dataSource = self;
    
    myTableView.separatorColor = [UIColor blackColor];
    myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    [self.view addSubview:myTableView];
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    self.title = @"Акции";
}

- (void)createItemList {
    actionList              = [NSMutableArray new];
	actionToLiveInArray     = [NSMutableArray array];
    
    actionNameList          = [NSMutableArray new];
    actionNameToLiveInArray = [NSMutableArray array];
    
    brandList               = [NSMutableArray new];
    brandToLiveInArray      = [NSMutableArray array];
    
    priceList               = [NSMutableArray new];
    priceToLiveInArray      = [NSMutableArray array];
    
    availQtyList            = [NSMutableArray new];
    availQtyToLiveInArray   = [NSMutableArray array];
    
    actionTypeList          = [NSMutableArray new];
    actionTypeToLiveInArray = [NSMutableArray array];
    
    amountSumList           = [NSMutableArray new];
    amountSumToLiveInArray  = [NSMutableArray array];
    
    amountQtyList           = [NSMutableArray new];
    amountQtyToLiveInArray  = [NSMutableArray array];
    
    setList                 = [NSMutableArray new];
    setToLiveInArray        = [NSMutableArray array];
    
    setDescrList            = [NSMutableArray new];
    setDescrToLiveInArray   = [NSMutableArray array];
    
    brandIdList             = [NSMutableArray new];
    brandIdToLiveInArray    = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        NSString *squl = @"select ActionID, ActionName, ActionBrandID, ActionPrice, ActionAvailQty, ActionType, ActionAmountSum, ActionAmountQty, SetID, SetDescription from ActionTable where 1=1";
        
        if (brandId) {
            squl = [NSString stringWithFormat:@"%@ and ActionBrandID = '%@'", squl, brandId];
        }
        
        if (typeId) {
            squl = [NSString stringWithFormat:@"%@ and ActionType = '%@'", squl, typeId];
        }
        
        if (fromMerch == YES) {
            squl = [NSString stringWithFormat:@"%@ and exists(select * from BrandMerch where BrandMerch.BrandId == ActionTable.ActionBrandID) and not exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == ActionTable.ActionBrandID) order by ActionName", squl];
        } else {
            squl = [NSString stringWithFormat:@"%@ and exists(select * from PersonalPriceList where PersonalPriceList.CustAccount == ? and PersonalPriceList.BrandId == ActionTable.ActionBrandID) order by ActionName", squl];
        }
        sql = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *actionId    = @"null";
                NSString *actionName  = @"null";
                NSString *actionBrand = @"null";
                NSString *price       = @"null";
                NSString *availQty    = @"null";
                NSString *type        = @"null";
                NSString *amountSum   = @"null";
                NSString *amountQty   = @"null";
                NSString *setId       = @"null";
                NSString *setDescr    = @"null";
                NSString *brandName   = @"null";
                
                NSString *priceTypeId   = @"null";
                NSString *disc          = @"null";
                NSString *round         = @"null";
                NSString *comDiscount   = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    actionId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    actionName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    actionBrand  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                const char *sql_2;
                
                sql_2 = "select BrandName from Brand where BrandId = ?";
                
                sqlite3_stmt *selstmt_2;
                
                if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(selstmt_2, 1, [actionBrand UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_2) == SQLITE_ROW) 
                    {
                        
                        if (sqlite3_column_text(selstmt_2, 0))
                            brandName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                //if (sqlite3_column_text(selectstmt, 3))
                //    price  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    availQty  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                                
                if (sqlite3_column_text(selectstmt, 5))
                    type  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                if (sqlite3_column_text(selectstmt, 6))
                    amountSum  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 6)];
                
                if (sqlite3_column_text(selectstmt, 7))
                    amountQty  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 7)];
                
                if (sqlite3_column_text(selectstmt, 8))
                    setId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 8)];
                
                if (sqlite3_column_text(selectstmt, 9))
                    setDescr  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 9)];
                
                const char *sql_3;
                
                sql_3 = "select PriceTypeId, Discount, Round, ComDiscount from PersonalPriceList where BrandId = ? and CustAccount = ?";
                
                sqlite3_stmt *selstmt_3;
                
                if (sqlite3_prepare_v2(database, sql_3, -1, &selstmt_3, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(selstmt_3, 1, [actionBrand UTF8String], -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(selstmt_3, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt_3) == SQLITE_ROW) 
                    {
                        if (sqlite3_column_text(selstmt_3, 0))
                            priceTypeId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 0)];
                        
                        if (sqlite3_column_text(selstmt_3, 1))
                            disc  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 1)];
                        
                        if (sqlite3_column_text(selstmt_3, 2))
                            round  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 2)];
                        
                        if (sqlite3_column_text(selstmt_3, 3))
                            comDiscount  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_3, 3)];
                        
                    }
                }
                sqlite3_finalize(selstmt_2);
                
                const char *sql_4;
                
                if ([priceTypeId  isEqual: @"null"])
                    sql_4 = "select Price from BasePriceTable where ItemId = ?";
                else 
                    sql_4 = "select Price from BasePriceTable where ItemId = ? and PriceTypeId = ?";
                
                sqlite3_stmt *selstmt_4;
                
                if (sqlite3_prepare_v2(database, sql_4, -1, &selstmt_4, NULL) == SQLITE_OK) 
                {
                    if ([priceTypeId  isEqual: @"null"])
                        sqlite3_bind_text(selstmt_4, 1, [setId UTF8String], -1, SQLITE_TRANSIENT);
                    else
                    {
                        sqlite3_bind_text(selstmt_4, 1, [setId UTF8String], -1, SQLITE_TRANSIENT);
                        sqlite3_bind_text(selstmt_4, 2, [priceTypeId UTF8String], -1, SQLITE_TRANSIENT);
                    }
                    
                    if (sqlite3_step(selstmt_4) == SQLITE_ROW) 
                    {
                        if ([disc  isEqual: @"null"])
                        {
                            if (sqlite3_column_text(selstmt_4, 0))
                                price  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_4, 0)];
                            
                            if (![comDiscount  isEqual: @"null"])
                            {
                                double totalPrice = 0.0;
                                
                                totalPrice = [price doubleValue]*(100.0 - [comDiscount doubleValue])/100.0;
                                
                                price = [NSString stringWithFormat:@"%0.2lf", totalPrice];
                            }
                        }
                        else
                        {
                            if (sqlite3_column_text(selstmt_4, 0))
                                price  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_4, 0)];
                            
                            double totalPrice = 0.0;
                            
                            if (![comDiscount  isEqual: @"null"])
                            { 
                                totalPrice = ([price doubleValue] - ([price doubleValue]*[disc doubleValue]/100.0)*(100.0 - [comDiscount doubleValue])/100.0);
                                
                                price = [NSString stringWithFormat:@"%0.2lf", totalPrice];
                                
                            }
                            else 
                            {
                                //totalPrice = [price doubleValue] - ([price doubleValue]*[disc doubleValue]/100.0); 
                                totalPrice = ([price doubleValue]*(100.0 - [disc doubleValue]/100));
                                
                                price = [NSString stringWithFormat:@"%0.2lf", totalPrice];
                                
                            }
                        }
                        
                        price = [self roundedNum:[price doubleValue] round:[round doubleValue]];
                    }
                }
                sqlite3_finalize(selstmt_4);

                if (![type isEqualToString:@"2"])
                {
                    const char *sql_5;
                
                    sql_5 = "select Qty from ItemTable where ItemId = ?";
                
                    sqlite3_stmt *selstmt_5;
                
                    if (sqlite3_prepare_v2(database, sql_5, -1, &selstmt_5, NULL) == SQLITE_OK) 
                    {
                        sqlite3_bind_text(selstmt_5, 1, [setId UTF8String], -1, SQLITE_TRANSIENT);
                    
                        if (sqlite3_step(selstmt_5) == SQLITE_ROW) 
                        {
                            if (sqlite3_column_text(selstmt_5, 0))
                            {
                                availQty = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_5, 0)];
                                availQty = [NSString stringWithFormat:@"%0.0f", [availQty doubleValue]];
                            }
                        }
                    }
                    sqlite3_finalize(selstmt_5);
                }

                
                [actionToLiveInArray     addObject:actionId];
                [actionNameToLiveInArray addObject:actionName];
                [brandToLiveInArray      addObject:brandName];
                [priceToLiveInArray      addObject:price];
                [availQtyToLiveInArray   addObject:availQty];
                [actionTypeToLiveInArray addObject:type];
                [amountSumToLiveInArray  addObject:amountSum];
                [amountQtyToLiveInArray  addObject:amountQty];
                [setToLiveInArray        addObject:setId];
                [setDescrToLiveInArray   addObject:setDescr];
                [brandIdToLiveInArray    addObject:actionBrand];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *actionIdToLiveInDict   = [NSDictionary dictionaryWithObject:actionToLiveInArray forKey:@"actionId"];
    NSDictionary *actionNameToLiveInDict = [NSDictionary dictionaryWithObject:actionNameToLiveInArray forKey:@"actionName"];
    NSDictionary *brandToLiveInDict      = [NSDictionary dictionaryWithObject:brandToLiveInArray forKey:@"brandName"];
    NSDictionary *priceToLiveInDict      = [NSDictionary dictionaryWithObject:priceToLiveInArray forKey:@"price"];
    NSDictionary *availQtyToLiveInDict   = [NSDictionary dictionaryWithObject:availQtyToLiveInArray forKey:@"availQty"];
    NSDictionary *typeToLiveInDict       = [NSDictionary dictionaryWithObject:actionTypeToLiveInArray forKey:@"type"];
    NSDictionary *amountSumToLiveInDict  = [NSDictionary dictionaryWithObject:amountSumToLiveInArray forKey:@"amountSum"];
    NSDictionary *amountQtyToLiveInDict  = [NSDictionary dictionaryWithObject:amountQtyToLiveInArray forKey:@"amountQty"];
    NSDictionary *setToLiveInDict        = [NSDictionary dictionaryWithObject:setToLiveInArray forKey:@"setId"];
    NSDictionary *setDescrToLiveInDict   = [NSDictionary dictionaryWithObject:setDescrToLiveInArray forKey:@"setDescr"];
    NSDictionary *brandIdToLiveInDict    = [NSDictionary dictionaryWithObject:brandIdToLiveInArray forKey:@"brandId"];
    
    [actionList     addObject:actionIdToLiveInDict];
    [actionNameList addObject:actionNameToLiveInDict];
    [brandList      addObject:brandToLiveInDict];
    [priceList      addObject:priceToLiveInDict];
    [availQtyList   addObject:availQtyToLiveInDict];
    [actionTypeList addObject:typeToLiveInDict];
    [amountSumList  addObject:amountSumToLiveInDict];
    [amountQtyList  addObject:amountQtyToLiveInDict];
    [setList        addObject:setToLiveInDict];
    [setDescrList   addObject:setDescrToLiveInDict];
    [brandIdList    addObject:brandIdToLiveInDict];
    
    copyActionList     = [NSMutableArray new];
    copyActionNameList = [NSMutableArray new];
    copyBrandList      = [NSMutableArray new];
    copyPriceList      = [NSMutableArray new];
    copyAvailQtyList   = [NSMutableArray new];
    copyActionTypeList = [NSMutableArray new];
    copyAmountSumList  = [NSMutableArray new];
    copyAmountQtyList  = [NSMutableArray new];
    copySetList        = [NSMutableArray new];
    copySetDescrList   = [NSMutableArray new];
    copyBrandIdList    = [NSMutableArray new];
}

- (void)refreshData{

    [self createItemList];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (searching)
	{
		return 1;
	}
	else
	{
		return [actionList count];
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
    if (searching)
	{
		return [copyActionList count];
	}
	else 
	{
        NSDictionary *dictionary = [actionList objectAtIndex:section];
        NSArray		 *array = [dictionary objectForKey:@"actionId"];
        
        return [array count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *MyIdentifier = [NSString stringWithFormat:@"MyIdentifier %li", (long)indexPath.row];
    
    MyTableCell *cell = (MyTableCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    NSString		*actionValue;
    NSString        *brandValue;
    NSString		*nameValue;
    NSString		*priceValue;
    NSString        *qtyValue;
    NSString        *typeValue;
    NSString        *setId;
    
    BOOL inSale = NO;
    
    if (searching) {
        if ([copyActionList count] > 0)
            setId = [copySetList objectAtIndex:indexPath.row];
    } else {
        NSDictionary	*dictSet   = [setList objectAtIndex:indexPath.section];
        NSArray			*arraySet  = [dictSet objectForKey:@"setId"];
        setId                      = [arraySet objectAtIndex:indexPath.row];
        
        inSale = [self actionInSalesToday:setId];
    }
    
    //BOOL inSale = [self actionInSalesToday:setId];
    
    UIColor *mycolor= [UIColor colorWithRed:245.0/255.0 green:222.0/255.0 blue:179.0/255.0 alpha:1.0];
    
    if (cell == nil) {
        cell = [[MyTableCell alloc] initWithFrame:CGRectZero];
        
        [cell addColumn:40];
        [cell addColumn:140];
        [cell addColumn:240];
        [cell addColumn:720];
        [cell addColumn:800];
        //[cell addColumn:820];
        [cell addColumn:870];
    }
    
    UILabel *label = [[UILabel	alloc] initWithFrame:CGRectMake(5.0, 0, 30.0,
                                                                tableView.rowHeight)];
    
    label.tag = LABEL_TAG;
    label.font = [UIFont systemFontOfSize:10.0];
    label.text = [NSString stringWithFormat:@"%d", (int) (indexPath.row + 1)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    if (inSale)
        label.backgroundColor = mycolor;
    else {
        label.backgroundColor = UIColor.clearColor;
    }
    [cell.contentView addSubview:label];
    //[label release];
    
    UILabel *actionId = [[UILabel	alloc] initWithFrame:CGRectMake(45.0, 0, 90.0,
                                                                    tableView.rowHeight)];
    
    actionId.tag = LABEL_TAG;
    actionId.font = [UIFont systemFontOfSize:12.0];
    actionId.textAlignment = NSTextAlignmentCenter;
    actionId.textColor = [UIColor blackColor];
    actionId.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    if (inSale)
        actionId.backgroundColor = mycolor;
    else {
        actionId.backgroundColor = UIColor.clearColor;
    }
    [cell.contentView addSubview:actionId];
    //[itemId release];
    
    UILabel *brand = [[UILabel	alloc] initWithFrame:CGRectMake(145.0, 0, 90.0,
                                                                tableView.rowHeight)];
    
    brand.tag = LABEL_TAG;
    brand.font = [UIFont systemFontOfSize:12.0];
    brand.textAlignment = NSTextAlignmentCenter;
    brand.textColor = [UIColor blackColor];
    brand.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    if (inSale) {
        brand.backgroundColor = mycolor;
    } else {
        brand.backgroundColor = UIColor.clearColor;
    }
    [cell.contentView addSubview:brand];
    //[itemId release];
    
    
    
    UILabel *name = [[UILabel	alloc] initWithFrame:CGRectMake(245.0, 0, 475.0,
                                                                tableView.rowHeight)];
    
    name.tag = LABEL_TAG;
    name.font = [UIFont systemFontOfSize:16.0];
    name.textAlignment = NSTextAlignmentCenter;
    name.textColor = [UIColor blackColor];
    name.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    [name setLineBreakMode:NSLineBreakByTruncatingTail];
    [name setNumberOfLines:2];
    if (inSale)
        name.backgroundColor = mycolor;
    else {
        name.backgroundColor = UIColor.clearColor;
    }
    [cell.contentView addSubview:name];
    //[name release];
    
    UILabel *price = [[UILabel	alloc] initWithFrame:CGRectMake(725.0, 0, 70.0,
                                                                tableView.rowHeight)];
    
    price.tag = LABEL_TAG;
    price.font = [UIFont systemFontOfSize:12.0];
    price.textAlignment = NSTextAlignmentCenter;
    price.textColor = [UIColor blackColor];
    price.autoresizingMask = UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleHeight;
    if (inSale) {
        price.backgroundColor = mycolor;
    } else {
        price.backgroundColor = UIColor.clearColor;
    }
    [cell.contentView addSubview:price];
    
    UILabel *qty = [[UILabel	alloc] initWithFrame:CGRectMake(805.0, 0, 60.0,
                                                                tableView.rowHeight)];
    
    qty.tag = LABEL_TAG; 
    qty.font = [UIFont systemFontOfSize:12.0];
    qty.textAlignment = NSTextAlignmentCenter;
    qty.textColor = [UIColor blackColor]; 
    qty.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    if (inSale) {
        qty.backgroundColor = mycolor;
    } else {
        qty.backgroundColor = UIColor.clearColor;
    }
    [cell.contentView addSubview:qty];

    
    UILabel *type = [[UILabel	alloc] initWithFrame:CGRectMake(875.0, 0, 140.0,
                                                                    tableView.rowHeight)];
    
    type.tag = LABEL_TAG; 
    type.font = [UIFont systemFontOfSize:12.0]; 
    type.textAlignment = NSTextAlignmentCenter;
    type.textColor = [UIColor blackColor]; 
    type.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [type setLineBreakMode:NSLineBreakByTruncatingTail];
	[type setNumberOfLines:2];
    if (inSale)
        type.backgroundColor = mycolor;
    else {
        type.backgroundColor = UIColor.clearColor;
    }
    [cell.contentView addSubview:type];
    
    if (searching) {
        if ([copyActionList count] > 0) {
            actionValue    = [copyActionList objectAtIndex:indexPath.row];
            brandValue     = [copyBrandList objectAtIndex:indexPath.row];
            nameValue      = [copyActionNameList objectAtIndex:indexPath.row];
            priceValue     = [copyPriceList objectAtIndex:indexPath.row];
            qtyValue       = [copyAvailQtyList objectAtIndex:indexPath.row];
            typeValue      = [copyActionTypeList objectAtIndex:indexPath.row];
            
            if ([typeValue isEqualToString:@"1"]) {
                typeValue = @"Акция на запуск";
            }
            else
            if ([typeValue isEqualToString:@"2"]) {
                typeValue = @"Акция на сумму/кол-во";
            }
            else
            if ([typeValue isEqualToString:@"3"]) {
                typeValue = @"Комбинированная акция";
            }
            
            actionId.text  = [NSString stringWithFormat:@"%@", actionValue];
            brand.text     = [NSString stringWithFormat:@"%@", brandValue];
            name.text      = [NSString stringWithFormat:@"%@", nameValue];
            price.text     = [NSString stringWithFormat:@"%@", priceValue];
            qty.text       = [NSString stringWithFormat:@"%@", qtyValue];
            type.text      = [NSString stringWithFormat:@"%@", typeValue];
        }
    } else {
        NSDictionary	*dictAction   = [actionList objectAtIndex:indexPath.section];
        NSArray			*arrayAction  = [dictAction objectForKey:@"actionId"];
        actionValue                   = [arrayAction objectAtIndex:indexPath.row];
        
        NSDictionary	*dictBrand    = [brandList objectAtIndex:indexPath.section];
        NSArray			*arrayBrand	  = [dictBrand objectForKey:@"brandName"];
        brandValue	                  = [arrayBrand objectAtIndex:indexPath.row];
        
        NSDictionary	*dictName     = [actionNameList objectAtIndex:indexPath.section];
        NSArray			*arrayName	  = [dictName objectForKey:@"actionName"];
        nameValue                     = [arrayName objectAtIndex:indexPath.row];
        
        NSDictionary	*dictPrice    = [priceList objectAtIndex:indexPath.section];
        NSArray			*arrayPrice   = [dictPrice objectForKey:@"price"];
        priceValue                    = [arrayPrice objectAtIndex:indexPath.row];
        
        NSDictionary	*dictQty      = [availQtyList objectAtIndex:indexPath.section];
        NSArray			*arrayQty 	  = [dictQty objectForKey:@"availQty"];
        qtyValue                      = [arrayQty objectAtIndex:indexPath.row];
        
        NSDictionary	*dictType     = [actionTypeList objectAtIndex:indexPath.section];
        NSArray			*arrayType    = [dictType objectForKey:@"type"];
        typeValue                     = [arrayType objectAtIndex:indexPath.row];
        
        if ([typeValue isEqualToString:@"1"]) {
            typeValue = @"Акция на запуск";
        }
        else if ([typeValue isEqualToString:@"2"]) {
            typeValue = @"Акция на сумму/кол-во";
        }
        else if ([typeValue isEqualToString:@"3"]) {
            typeValue = @"Комбинированная акция";
        }
        
        actionId.text  = actionValue;
        brand.text     = brandValue;
        name.text      = nameValue;
        price.text     = priceValue;
        qty.text       = qtyValue;
        type.text      = typeValue;
    }
    
    CALayer *cellLayer = cell.layer;
    cellLayer.borderColor = [[UIColor blackColor] CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.backgroundColor = [UIColor greenColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary	*dictAction   = [actionList objectAtIndex:indexPath.section];
    NSArray			*arrayAction  = [dictAction objectForKey:@"actionId"];
    NSString        *actionValue  = [arrayAction objectAtIndex:indexPath.row];
    
    if ([self actionInSalesToday:actionValue] == YES) {
        UIColor *mycolor= [UIColor colorWithRed:245.0/255.0 green:222.0/255.0 blue:179.0/255.0 alpha:1.0];
        cell.backgroundColor = mycolor;
    } else {
        cell.backgroundColor = UIColor.clearColor;
    }
}

-(BOOL)actionInSalesToday:(NSString*)actionId {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    BOOL inSales = FALSE;
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        //const char *sql = "select * from SalesLine where ItemId = ? and exists(select * from SalesTable where SalesTable.SalesId == SalesLine.SalesId and SalesDate = ? and CustAccount = ?)";
        
        const char *sql = "select * from SalesTable where  ActionId = ? and SalesDate = ? and CustAccount = ?";
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [actionId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 3, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) == SQLITE_ROW)
                inSales = YES;
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    } else
        sqlite3_close(database);
    
    return inSales;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary	*dictAction   = [actionList objectAtIndex:indexPath.section];
    NSArray			*arrayAction  = [dictAction objectForKey:@"actionId"];
    
    NSDictionary	*dictBrand    = [brandList objectAtIndex:indexPath.section];
    NSArray			*arrayBrand	  = [dictBrand objectForKey:@"brandName"];
    
    NSDictionary	*dictName     = [actionNameList objectAtIndex:indexPath.section];
    NSArray			*arrayName	  = [dictName objectForKey:@"actionName"];
    
    NSDictionary	*dictPrice    = [priceList objectAtIndex:indexPath.section];
    NSArray			*arrayPrice   = [dictPrice objectForKey:@"price"];
    
    NSDictionary	*dictQty      = [availQtyList objectAtIndex:indexPath.section];
    NSArray			*arrayQty 	  = [dictQty objectForKey:@"availQty"];
    
    NSDictionary	*dictType     = [actionTypeList objectAtIndex:indexPath.section];
    NSArray			*arrayType    = [dictType objectForKey:@"type"];
    
    NSDictionary	*dictAmountSum     = [amountSumList objectAtIndex:indexPath.section];
    NSArray			*arrayAmountSum    = [dictAmountSum objectForKey:@"amountSum"];
    
    NSDictionary	*dictAmountQty     = [amountQtyList objectAtIndex:indexPath.section];
    NSArray			*arrayAmountQty    = [dictAmountQty objectForKey:@"amountQty"];
    
    NSDictionary	*dictSet     = [setList objectAtIndex:indexPath.section];
    NSArray			*arraySet    = [dictSet objectForKey:@"setId"];
    
    NSDictionary	*dictSetDescr     = [setDescrList objectAtIndex:indexPath.section];
    NSArray			*arraySetDescr    = [dictSetDescr objectForKey:@"setDescr"];
    
    NSDictionary	*dictBrandId    = [brandIdList objectAtIndex:indexPath.section];
    NSArray			*arrayBrandId	= [dictBrandId objectForKey:@"brandId"];
    
    MerchActDetViewController *fvController = [[MerchActDetViewController alloc] init];
    
    fvController.actionId  = [arrayAction objectAtIndex:indexPath.row];
    fvController.brand     = [arrayBrand objectAtIndex:indexPath.row];
    fvController.name      = [arrayName objectAtIndex:indexPath.row];
    fvController.price     = [arrayPrice objectAtIndex:indexPath.row];
    fvController.availQty  = [arrayQty objectAtIndex:indexPath.row];
    fvController.type      = [arrayType objectAtIndex:indexPath.row];
    fvController.amountSum = [arrayAmountSum objectAtIndex:indexPath.row];
    fvController.amountQty = [arrayAmountQty objectAtIndex:indexPath.row];
    fvController.setId     = [arraySet objectAtIndex:indexPath.row];
    fvController.setDescr  = [arraySetDescr objectAtIndex:indexPath.row];
    fvController.brandId   = [arrayBrandId objectAtIndex:indexPath.row];
    fvController.fromMerch = fromMerch;
    fvController.custAccount = custAccount;
    fvController.delegate  = self;
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];

    fvController = nil;
    infoNavController = nil;
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    
    if (mustClosingView == YES) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //section text as a label
    UIView *sectionHead = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 30)];
    //[sectionHead setBackgroundColor:UIColor.whiteColor];
    
    UILabel *label = [[UILabel	alloc] initWithFrame:CGRectMake(0.0, 0, 40.0, 30)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"№";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer = label.layer;
    cellLayer.borderColor = [[UIColor blackColor] CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(40.0, 0, 100.0, 30)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Код акции";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer1 = label.layer;
    cellLayer1.borderColor = [[UIColor blackColor] CGColor];
    cellLayer1.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(140.0, 0, 100.0, 30)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Марка";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer2 = label.layer;
    cellLayer2.borderColor = [[UIColor blackColor] CGColor];
    cellLayer2.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(240.0, 0, 480.0, 30)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Наименование акции";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer3 = label.layer;
    cellLayer3.borderColor = [[UIColor blackColor] CGColor];
    cellLayer3.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(720.0, 0, 80.0, 30)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Цена";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor]; ; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer4 = label.layer;
    cellLayer4.borderColor = [[UIColor blackColor] CGColor];
    cellLayer4.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(800.0, 0, 70.0, 30)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Доступно";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer6 = label.layer;
    cellLayer6.borderColor = [[UIColor blackColor] CGColor];
    cellLayer6.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(870.0, 0, 154.0, 30)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Тип акции";
    label.textAlignment = NSTextAlignmentCenter; 
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer7 = label.layer;
    cellLayer7.borderColor = [[UIColor blackColor] CGColor];
    cellLayer7.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    return sectionHead;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark -
#pragma mark Search Bar 

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	//This method is called again when the user clicks back from teh detail view.
	//So the overlay is displayed on the results, which is something we do not want to happen.
    if (searching)
		return;
	
	//Add the overlay view.
	if (ovController == nil)
		ovController = [[OverlayActionViewViewController alloc] initWithNibName:@"OverlayActionViewViewController" bundle:nil];
	
	CGFloat width = 1024;
	CGFloat height = 65000;
	
	//Parameters x = origion on x-axis, y = origon on y-axis.
	CGRect frame = CGRectMake(0, 30, width, height);
	ovController.view.frame = frame;	
	ovController.view.backgroundColor = [UIColor grayColor];
	ovController.view.alpha = 0.5;
	
	ovController.rvController = self;
	
	[myTableView insertSubview:ovController.view aboveSubview:self.parentViewController.view];
	
	searching = YES;
	letUserSelectRow = NO;
	myTableView.scrollEnabled = NO;
	
	//Add the done button.
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
											   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
											   target:self action:@selector(doneSearching_Clicked:)];
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
	
	//Remove all objects first.
    [copyActionList     removeAllObjects];
    [copyActionNameList removeAllObjects];
    [copyBrandList      removeAllObjects];
    [copyPriceList      removeAllObjects];
    [copyAvailQtyList   removeAllObjects];
    [copyActionTypeList removeAllObjects];
    [copyAmountSumList  removeAllObjects];
    [copyAmountQtyList  removeAllObjects];
    [copySetList        removeAllObjects];
    [copySetDescrList   removeAllObjects];
    [copyBrandIdList    removeAllObjects];
    
	if ([searchText length] > 0) {
		[ovController.view removeFromSuperview];
		searching = YES;
		letUserSelectRow = YES;
		myTableView.scrollEnabled = YES;
		[self searchTableView];
	}
	else 
	{
		CGFloat width = 1024;
        CGFloat height = 65000;
        
        //Parameters x = origion on x-axis, y = origon on y-axis.
        CGRect frame = CGRectMake(0, 70, width, height);
        
        ovController.view.frame = frame;
        
        [self.view insertSubview:ovController.view aboveSubview:self.parentViewController.view];
		
		searching = NO;
		letUserSelectRow = NO;
		myTableView.scrollEnabled = NO;
    }
	
	[myTableView reloadData];
}

- (void)searchTableView {
    NSString       *searchText       = searchBar.text;
	NSMutableArray *searchArray      = [NSMutableArray new];
    NSMutableArray *searchActionId   = [NSMutableArray new];
    NSMutableArray *searchBrand      = [NSMutableArray new];
    NSMutableArray *searchPrice      = [NSMutableArray new];
    NSMutableArray *searchAvailQty   = [NSMutableArray new];
    NSMutableArray *searchType       = [NSMutableArray new];
    NSMutableArray *searchAmountSum  = [NSMutableArray new];
    NSMutableArray *searchAmountQty  = [NSMutableArray new];
    NSMutableArray *searchSetId      = [NSMutableArray new];
    NSMutableArray *searchSetDescr   = [NSMutableArray new];
    NSMutableArray *searchBrandId    = [NSMutableArray new];
    
	for (NSDictionary *dictionary in actionNameList)
	{
		NSArray *array = [dictionary objectForKey:@"actionName"];
		[searchArray addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictActionId in actionList)
	{
		NSArray *array = [dictActionId objectForKey:@"actionId"];
		[searchActionId addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictBrand in brandList)
	{
		NSArray *array = [dictBrand objectForKey:@"brandName"];
		[searchBrand addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictPrice in priceList)
	{
		NSArray *array = [dictPrice objectForKey:@"price"];
		[searchPrice addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictAvailQty in availQtyList)
	{
		NSArray *array = [dictAvailQty objectForKey:@"availQty"];
		[searchAvailQty addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictType in actionTypeList)
	{
		NSArray *array = [dictType objectForKey:@"type"];
		[searchType addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictAmountSum in amountSumList)
	{
		NSArray *array = [dictAmountSum objectForKey:@"amountSum"];
		[searchAmountSum addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictAmountQty in amountQtyList)
	{
		NSArray *array = [dictAmountQty objectForKey:@"amountQty"];
		[searchAmountQty addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictSetId in setList)
	{
		NSArray *array = [dictSetId objectForKey:@"setId"];
		[searchSetId addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictSetDescr in setDescrList)
	{
		NSArray *array = [dictSetDescr objectForKey:@"setDescr"];
		[searchSetDescr addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictBrandId in brandIdList)
	{
		NSArray *array = [dictBrandId objectForKey:@"brandId"];
		[searchBrandId addObjectsFromArray:array];
    }
    
    for (NSString *sTemp in searchArray)
	{
        //i = i + 1;
        
        NSRange titleResultsRange = [sTemp rangeOfString:searchText options:NSCaseInsensitiveSearch];
		
		if (titleResultsRange.length > 0) {
            [copyActionNameList addObject:sTemp];
            [copyActionList     addObject:[searchActionId   objectAtIndex:i]];
            [copyBrandList      addObject:[searchBrand      objectAtIndex:i]];
            [copyPriceList      addObject:[searchPrice      objectAtIndex:i]];
            [copyAvailQtyList   addObject:[searchAvailQty   objectAtIndex:i]];
            [copyActionTypeList addObject:[searchType       objectAtIndex:i]];
            [copyAmountSumList  addObject:[searchAmountSum  objectAtIndex:i]];
            [copyAmountQtyList  addObject:[searchAmountQty  objectAtIndex:i]];
            [copySetList        addObject:[searchSetId      objectAtIndex:i]];
            [copySetDescrList   addObject:[searchSetDescr   objectAtIndex:i]];
            [copyBrandIdList    addObject:[searchBrandId    objectAtIndex:i]];
        }
        i++;
	}
	
    i = 0;

    searchArray = nil;

    searchActionId = nil;

    searchBrand = nil;

    searchPrice = nil;

    searchAvailQty = nil;

    searchType = nil;

    searchAmountSum = nil;

    searchAmountQty = nil;

    searchSetId = nil;

    searchSetDescr = nil;

    searchBrandId = nil;
}

- (void)doneSearching_Clicked:(id)sender {
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	
	letUserSelectRow = YES;
	searching = NO;
    
    endEditInSearch = YES;
    
	self.navigationItem.rightBarButtonItem = nil;
	myTableView.scrollEnabled = YES;
	
	[ovController.view removeFromSuperview];
    ovController = nil;
    
    if (isViewPushed == NO) {
		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStylePlain target:self action:@selector(cancel_Clicked:)];
        
        barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        
        self.navigationItem.rightBarButtonItem = barButton;
    }
    
    [myTableView reloadData];
}

- (void)cancel_Clicked:(id)sender {
    if (actionMark.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        actionMark = nil;
    }
    
    if (actionType.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        actionType = nil;
    }
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showMark:(id)sender {
    if (!actionMark) {
        actionMark             = [[ActionMarkViewController alloc] init];
        actionMark.delegate    = self;
        actionMark.custAccount = custAccount;
        
        actionMark.modalPresentationStyle = UIModalPresentationPopover;
        actionMark.popoverPresentationController.barButtonItem = brandBtn;
        
        [self presentViewController:actionMark animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        actionMark = nil;
    }
}

- (void)resetFilter:(id)sender {
    [myTableView reloadData];
    
    NSString *searchText = searchBar.text;
    
    brandId = nil;
    typeId  = nil;
    
    [brandBtn setTintColor:UIColor.clearColor];
    [typeBtn setTintColor:UIColor.clearColor];
    
    [self refreshData];
    [myTableView reloadData];
    
    searchBar.text = searchText; 
}

- (void)scrollToTop{
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [myTableView selectRowAtIndexPath:topIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)markIsSelected:(NSString *)brand {
    [myTableView reloadData];
    
    brandId = nil;
    [self refreshData];
    
    brandId = brand;

    [self refreshData];
    [myTableView reloadData];
    
    if (actionMark.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        actionMark = nil;
    }
    
    if (brandId == nil) {
        [brandBtn setTintColor:UIColor.clearColor];
    } else {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [brandBtn setTintColor:color];
    }
}

- (void)showType:(id)sender {
    if (!actionType) {
        actionType             = [[ActionTypeViewController alloc] init];
        actionType.delegate    = self;
        actionType.custAccount = custAccount;
        
        actionType.modalPresentationStyle = UIModalPresentationPopover;
        actionType.popoverPresentationController.barButtonItem = sender;
        
        [self presentViewController:actionType animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        actionType = nil;
    }
    typeBtn = sender;
}

- (void)typeIsSelected:(NSString *)type {
    [myTableView reloadData];
    
    typeId = nil;
    [self refreshData];
    
    typeId = type;

    [self refreshData];
    [myTableView reloadData];
    
    if (actionType.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        actionType = nil;
    }
    
    if (typeId == nil) {
        [typeBtn setTintColor:UIColor.clearColor];
    } else {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [typeBtn setTintColor:color];
    }
}

- (void)closeView:(BOOL)closeAll {
    mustClosingView = closeAll;
}

-(NSString *)roundedNum:(double)num round:(double)round {
    double result = 0.0;
    double numOfRound = 0.0;
    double numOfRounds_Int = 0.0;
    
    numOfRound = num/round;
    
    numOfRounds_Int = trunc(numOfRound);
    
    if (numOfRound == numOfRounds_Int) {
        result = num;
    } else {
        result = round * (numOfRounds_Int + 1);
    }
    
    return [NSString stringWithFormat:@"%0.2lf", result];
}


@end
