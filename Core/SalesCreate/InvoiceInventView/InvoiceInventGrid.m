//
//  InvoiceInventView.m
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//
#import "InvoiceInventGrid.h"
#import "MyTableCell.h"

static sqlite3 *database = nil;

@implementation InvoiceInventGrid

@synthesize delegate;

@synthesize itemList,
            itemNameList,
            brandList,
            unitList,
            qtyList,
            brandId,
            basePriceList,
            sectionArray;

@synthesize qtyTotal;
@synthesize sumTotal;
@synthesize i;
@synthesize custAccount;

#define LABEL_TAG 1 
#define VALUE_TAG 2 
#define FIRST_CELL_IDENTIFIER @"TrailItemCell" 
#define SECOND_CELL_IDENTIFIER @"RegularCell" 


- (void)viewDidLoad {	
    [super viewDidLoad];
    
    [self createItemList];
}

- (void)createItemList {
    itemList                 = [NSMutableArray new];
	itemToLiveInArray        = [NSMutableArray array];
    
    itemNameList             = [NSMutableArray new];
    itemNameToLiveInArray    = [NSMutableArray array];
    
    brandList                = [NSMutableArray new];
    brandToLiveInArray       = [NSMutableArray array];
    
    unitList                 = [NSMutableArray new];
    unitToLiveInArray        = [NSMutableArray array];
    
    qtyList                  = [NSMutableArray new];
    qtyToLiveInArray         = [NSMutableArray array];
    
    basePriceList            = [NSMutableArray new];
    bPToLiveInArray          = [NSMutableArray array];
    
    sectionArray             = [NSMutableArray new];
    textToLiveInArray        = [NSMutableArray array];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql;
        
        if (brandId && ![brandId  isEqual: @""])
            sql = "select ItemId, ItemName, BrandId, Unit, Qty from ItemTable where BrandId = ?";
        else
            sql = "select ItemId, ItemName, BrandId, Unit, Qty from ItemTable";
		
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			if (brandId)
                sqlite3_bind_text(selectstmt, 1, [brandId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
			{
				NSString *itemId    = @"null";
                NSString *itemName  = @"null";
                NSString *brand     = @"null";
                NSString *unit      = @"null";
                NSString *qty       = @"null";
                NSString *price     = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    itemId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    itemName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    brand  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    unit  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    qty  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                const char *sql_1;
                
                sql_1 = "select Price from BasePriceTable where ItemId = ?";
                
                sqlite3_stmt *selstmt;
                
                if (sqlite3_prepare_v2(database, sql_1, -1, &selstmt, NULL) == SQLITE_OK) 
                {
                    sqlite3_bind_text(selstmt, 1, [itemId UTF8String], -1, SQLITE_TRANSIENT);
                    
                    if (sqlite3_step(selstmt) == SQLITE_ROW) 
                    {
                        if (sqlite3_column_text(selstmt, 0))
                            price  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt, 0)];
                        
                        const char *sql_2;
                        
                        sql_2 = "select Price from BasePriceTable where ItemId = ?";
                        
                        sqlite3_stmt *selstmt_2;
                        
                        if (sqlite3_prepare_v2(database, sql_2, -1, &selstmt_2, NULL) == SQLITE_OK) 
                        {
                            sqlite3_bind_text(selstmt_2, 1, [itemId UTF8String], -1, SQLITE_TRANSIENT);
                            
                            if (sqlite3_step(selstmt_2) == SQLITE_ROW) 
                            {
                                if (sqlite3_column_text(selstmt_2, 0))
                                    price  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selstmt_2, 0)];
                                
                            }
                            sqlite3_reset(selstmt_2);
                            sqlite3_finalize(selstmt_2);
                        }
                    }
                }
                sqlite3_finalize(selstmt);
                
                [itemToLiveInArray     addObject:itemId];
                [itemNameToLiveInArray addObject:itemName];
                [brandToLiveInArray    addObject:brand];
                [unitToLiveInArray     addObject:unit];
                [qtyToLiveInArray      addObject:qty];
                [bPToLiveInArray       addObject:price];
                [textToLiveInArray     addObject:@""];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *itemToLiveInDict     = [NSDictionary dictionaryWithObject:itemToLiveInArray forKey:@"ItemId"];
    NSDictionary *itemNameToLiveInDict = [NSDictionary dictionaryWithObject:itemNameToLiveInArray forKey:@"ItemName"];
    NSDictionary *brandToLiveInDict    = [NSDictionary dictionaryWithObject:brandToLiveInArray forKey:@"BrandId"];
    NSDictionary *unitToLiveInDict     = [NSDictionary dictionaryWithObject:unitToLiveInArray forKey:@"Unit"];
    NSDictionary *qtyToLiveInDict      = [NSDictionary dictionaryWithObject:qtyToLiveInArray forKey:@"Qty"];
    NSDictionary *bpToLiveInDict      = [NSDictionary dictionaryWithObject:bPToLiveInArray forKey:@"Price"];
    NSDictionary *textToLiveInDict     = [NSDictionary dictionaryWithObject:textToLiveInArray forKey:@"Text"];
    
    [itemList       addObject:itemToLiveInDict];
    [itemNameList   addObject:itemNameToLiveInDict];
    [brandList      addObject:brandToLiveInDict];
    [unitList       addObject:unitToLiveInDict];
    [qtyList        addObject:qtyToLiveInDict];
    [basePriceList  addObject:bpToLiveInDict];
    [sectionArray   addObject:textToLiveInDict];
}

- (void)refreshData{

    [self createItemList];
    
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [itemList count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
    NSDictionary *dictionary = [itemList objectAtIndex:section];
    NSArray		 *array = [dictionary objectForKey:@"ItemId"];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {		
    NSString *MyIdentifier = [NSString stringWithFormat:@"MyIdentifier %li", (long)indexPath.row];
	
	MyTableCell *cell = (MyTableCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    UITextField *playerTextField = [[UITextField alloc] initWithFrame:CGRectMake(555, 0, 40, tableView.rowHeight)];
    
	NSString		*itemValue;
    NSString		*nameValue;
    //NSString		*brandValue;
    NSString		*unitValue;
    NSString		*qtyValue;
    NSString        *priceValue;
    NSString		*textValue;
    
    if (cell == nil) {
		cell = [[MyTableCell alloc] initWithFrame:CGRectZero];

        [cell addColumn:40];
        [cell addColumn:140];
        [cell addColumn:400];
		[cell addColumn:450];
        [cell addColumn:500];
        [cell addColumn:550];
        [cell addColumn:600];
    }
    
    NSDictionary	*dictItem   = [itemList objectAtIndex:indexPath.section];
    NSArray			*arrayItem	= [dictItem objectForKey:@"ItemId"];
    itemValue	= [arrayItem objectAtIndex:indexPath.row];
        
    NSDictionary	*dictName   = [itemNameList objectAtIndex:indexPath.section];
    NSArray			*arrayName	= [dictName objectForKey:@"ItemName"];
    nameValue	= [arrayName objectAtIndex:indexPath.row];
        
    //NSDictionary	*dictBrand  = [brandList objectAtIndex:indexPath.section];
    //NSArray			*arrayBrand	= [dictBrand objectForKey:@"BrandId"];
    //brandValue	= [arrayBrand objectAtIndex:indexPath.row];
        
    NSDictionary	*dictUnit   = [unitList objectAtIndex:indexPath.section];
    NSArray			*arrayUnit	= [dictUnit objectForKey:@"Unit"];
    unitValue	= [arrayUnit objectAtIndex:indexPath.row];
        
    NSDictionary	*dictQty    = [qtyList objectAtIndex:indexPath.section];
    NSArray			*arrayQty 	= [dictQty objectForKey:@"Qty"];
    qtyValue	= [arrayQty objectAtIndex:indexPath.row];
        
    NSDictionary	*dictBP    = [basePriceList objectAtIndex:indexPath.section];
    NSArray			*arrayBP 	= [dictBP objectForKey:@"Price"];
    priceValue	= [arrayBP objectAtIndex:indexPath.row];
        
    NSDictionary	*dictText   = [sectionArray objectAtIndex:indexPath.section];
    NSArray			*arrayText	= [dictText objectForKey:@"Text"];
    textValue	= [arrayText objectAtIndex:indexPath.row];
    
    UILabel *label = [[UILabel	alloc] initWithFrame:CGRectMake(5.0, 0, 30.0,
                                                                tableView.rowHeight)];
    
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = [NSString stringWithFormat:@"%d", (int)(indexPath.row + 1)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:label];  
    //[label release];
    
    UILabel *itemId = [[UILabel	alloc] initWithFrame:CGRectMake(45.0, 0, 90.0,
                                                                    tableView.rowHeight)];
    
    itemId.tag = LABEL_TAG; 
    itemId.font = [UIFont systemFontOfSize:12.0]; 
    itemId.text = itemValue;
    itemId.textAlignment = NSTextAlignmentCenter;
    itemId.textColor = [UIColor blackColor]; 
    itemId.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:itemId];
    //[itemId release];
    
    
    UILabel *name = [[UILabel	alloc] initWithFrame:CGRectMake(145.0, 0, 250.0,
                                                                tableView.rowHeight)];
    
    name.tag = LABEL_TAG; 
    name.font = [UIFont systemFontOfSize:12.0]; 
    name.text = nameValue;
    name.textAlignment = NSTextAlignmentCenter;
    name.textColor = [UIColor blackColor]; 
    name.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:name];
    //[name release];
    
    UILabel *qty = [[UILabel	alloc] initWithFrame:CGRectMake(455.0, 0, 40.0,
                                                                tableView.rowHeight)];
    
    qty.tag = LABEL_TAG; 
    qty.font = [UIFont systemFontOfSize:12.0]; 
    qty.text = qtyValue;
    qty.textAlignment = NSTextAlignmentCenter;
    qty.textColor = [UIColor blackColor]; 
    qty.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:qty];
    //[qty release];
    
    UILabel *unit = [[UILabel	alloc] initWithFrame:CGRectMake(505.0, 0, 40.0,
                                                                tableView.rowHeight)];
    
    unit.tag = LABEL_TAG; 
    unit.font = [UIFont systemFontOfSize:12.0]; 
    unit.text = unitValue;
    unit.textAlignment = NSTextAlignmentCenter;
    unit.textColor = [UIColor blackColor]; 
    unit.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:unit];
    //[unit release];
    
    UILabel *brand = [[UILabel	alloc] initWithFrame:CGRectMake(605.0, 0, 80.0,
                                                                tableView.rowHeight)];
    
    brand.tag = LABEL_TAG; 
    brand.font = [UIFont systemFontOfSize:12.0]; 
    brand.text = priceValue;
    brand.textAlignment = NSTextAlignmentCenter;
    brand.textColor = [UIColor blackColor]; 
    brand.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | 
    UIViewAutoresizingFlexibleHeight; 
    [cell.contentView addSubview:brand];
    //[brand release];
    
    playerTextField.tag  = indexPath.row;
    playerTextField.font = [UIFont systemFontOfSize:12.0];
    playerTextField.textColor = [UIColor blackColor];
    //playerTextField.placeholder = @"0";
    playerTextField.delegate = self;
    
    playerTextField.text = textValue;
    playerTextField.keyboardType = UIKeyboardTypeNumberPad;
    playerTextField.returnKeyType = UIReturnKeyDone;
    
    playerTextField.backgroundColor = UIColor.whiteColor;
    playerTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
    playerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
    playerTextField.textAlignment = NSTextAlignmentCenter;
    playerTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    playerTextField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    playerTextField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
    [playerTextField setEnabled: YES];
    [cell addSubview:playerTextField];
        
    //[playerTextField release];

	
    CALayer *cellLayer = cell.layer;
    cellLayer.borderColor = [[UIColor blackColor] CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    //section text as a label
    UIView *sectionHead = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 703, 20)];
    //[sectionHead setBackgroundColor:UIColor.whiteColor];
    
    UILabel *label = [[UILabel	alloc] initWithFrame:CGRectMake(0.0, 0, 40.0, 20)];
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
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(40.0, 0, 100.0, 20)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Код товара";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer1 = label.layer;
    cellLayer1.borderColor = [[UIColor blackColor] CGColor];
    cellLayer1.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(140.0, 0, 260.0, 20)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Наименование";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer2 = label.layer;
    cellLayer2.borderColor = [[UIColor blackColor] CGColor];
    cellLayer2.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(400.0, 0, 50.0, 20)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Цена";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor]; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer3 = label.layer;
    cellLayer3.borderColor = [[UIColor blackColor] CGColor];
    cellLayer3.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(450.0, 0, 50.0, 20)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Доступно";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor]; ; 
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer4 = label.layer;
    cellLayer4.borderColor = [[UIColor blackColor] CGColor];
    cellLayer4.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(500.0, 0, 50.0, 20)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Ед.изм.";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer5 = label.layer;
    cellLayer5.borderColor = [[UIColor blackColor] CGColor];
    cellLayer5.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(550.0, 0, 50.0, 20)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"В заказ";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.whiteColor; 
    label.backgroundColor = [UIColor blackColor];  
    label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight; 
    
    CALayer *cellLayer6 = label.layer;
    cellLayer6.borderColor = [[UIColor blackColor] CGColor];
    cellLayer6.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [sectionHead addSubview:label];
    
    label = [[UILabel	alloc] initWithFrame:CGRectMake(600.0, 0, 103.0, 20)];
    label.tag = LABEL_TAG; 
    label.font = [UIFont systemFontOfSize:10.0]; 
    label.text = @"Цена";
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

@end

