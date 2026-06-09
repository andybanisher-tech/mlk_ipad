//
//  CustTasksViewController.m
//  MLK
//
//  Created by garu on 11/24/14.
//
//

#import "CustTasksViewController.h"
#import "OverlayCustTasksViewController.h"
#import "MyTableCell.h"
#import "TaskCreateViewController.h"
#import "TaskTransViewController.h"
#import "SetTaskToCustViewController.h"
#import "RWBorderedButton.h"

static sqlite3 *database = nil;

@implementation CustTasksViewController

@synthesize navigationBarTitle;
@synthesize searchBar;
@synthesize taskDetList, taskList;
@synthesize deleteButton;
@synthesize toolbar;
@synthesize custBrand, custDream;
@synthesize fmark, fdream;
@synthesize markBtn;
@synthesize myTableView;
@synthesize mButton;
@synthesize i;
@synthesize aButton;
@synthesize isViewPushed, custAccount;
@synthesize dreamBtn;
@synthesize taskSource, fsource, sourceBtn;
@synthesize setTask, fset, setBtn;

#define LABEL_TAG 1
#define VALUE_TAG 2

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
#define TableViewTag 8888

- (void)loadView{
    [super loadView];
    
    [self selectAllTasks];
    
    self.navigationItem.title = @"Список задач клиента";
    
    UIToolbar* tools = [[UIToolbar alloc] initWithFrame:CGRectMake (0, 1, 200, 44)];
    
    tools.tintColor = [UIColor blackColor];
    
    NSMutableArray* btnsTask = [[NSMutableArray alloc] initWithCapacity:3];
    
    UIBarButtonItem *bitTask = [[UIBarButtonItem alloc]
                            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [btnsTask addObject:bitTask];

//    UIBarButtonItem *addCustomerButton = [[UIBarButtonItem alloc] initWithTitle:@"Создать" style:UIBarButtonItemStyleDone target:self action:@selector(createTask:)];
//    [btnsTask addObject:addCustomerButton];
    
    UIBarButtonItem *addTaskButton = [[UIBarButtonItem alloc] initWithTitle:@"Назначить" style:UIBarButtonItemStyleDone target:self action:@selector(addTask:)];
    
    [btnsTask addObject:addTaskButton];
    
    [tools setItems:btnsTask animated:NO];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:tools];

    //SearchBar
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 768, 40.0)];
    searchBar.delegate = self;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.tintColor = [UIColor blackColor];
    searchBar.searchTextField.backgroundColor = UIColor.whiteColor;
    
    searching        = NO;
	letUserSelectRow = YES;
    
    [self.view addSubview:searchBar];
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    myTableView = [[UITableView alloc]initWithFrame:CGRectMake(0.0, 115.0, 768, 590.0)];
    
    myTableView.delegate = self;
    myTableView.dataSource = self;
    
    myTableView.separatorColor = [UIColor blackColor];
    myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [myTableView setBackgroundView:nil];
    [myTableView setBackgroundView:[[UIView alloc] init]];
    
    [self.view addSubview:myTableView];
    UIView *tableHead = [[UIView alloc] initWithFrame:CGRectMake(0, 84, 768, 30)];
    tableHead.backgroundColor = UIColor.lightGrayColor;
    
    UILabel *label_2 = [[UILabel	alloc] initWithFrame:CGRectMake(0.0, 0, 280.0, 29)];
    label_2.tag = LABEL_TAG;
    label_2.font = [UIFont systemFontOfSize:14.0];
    label_2.text = @"  Наименование задачи";
    label_2.textAlignment = NSTextAlignmentLeft;
    label_2.textColor = [UIColor blackColor];
    label_2.backgroundColor = UIColor.whiteColor;
    label_2.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer = label_2.layer;
    cellLayer.borderColor = [[UIColor blackColor] CGColor];
    cellLayer.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [tableHead addSubview:label_2];
    
    UILabel *label_de = [[UILabel	alloc] initWithFrame:CGRectMake(280.0, 0, 100.0, 29)];
    label_de.tag = LABEL_TAG;
    label_de.font = [UIFont systemFontOfSize:14.0];
    label_de.text = @"Срок исп.";
    label_de.textAlignment = NSTextAlignmentCenter;
    label_de.textColor = [UIColor blackColor];
    label_de.backgroundColor = UIColor.whiteColor;
    label_de.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer_de = label_de.layer;
    cellLayer_de.borderColor = [[UIColor blackColor] CGColor];
    cellLayer_de.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [tableHead addSubview:label_de];
    
    UILabel *label_3 = [[UILabel	alloc] initWithFrame:CGRectMake(380.0, 0, 70.0, 29)];
    label_3.tag = LABEL_TAG;
    label_3.font = [UIFont systemFontOfSize:14.0];
    label_3.text = @"Источник";
    label_3.textAlignment = NSTextAlignmentCenter;
    label_3.textColor = [UIColor blackColor];
    label_3.backgroundColor = UIColor.whiteColor;
    label_3.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer_3 = label_3.layer;
    cellLayer_3.borderColor = [[UIColor blackColor] CGColor];
    cellLayer_3.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [tableHead addSubview:label_3];
    
    UILabel *label_4 = [[UILabel	alloc] initWithFrame:CGRectMake(450.0, 0, 100.0, 29)];
    label_4.tag = LABEL_TAG;
    label_4.font = [UIFont systemFontOfSize:14.0];
    label_4.text = @"Результат";
    label_4.textAlignment = NSTextAlignmentCenter;
    label_4.textColor = [UIColor blackColor];
    label_4.backgroundColor = UIColor.whiteColor;
    label_4.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer_4 = label_4.layer;
    cellLayer_4.borderColor = [[UIColor blackColor] CGColor];
    cellLayer_4.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [tableHead addSubview:label_4];
    
    UILabel *label_5 = [[UILabel	alloc] initWithFrame:CGRectMake(550.0, 0, 100.0, 29)];
    label_5.tag = LABEL_TAG;
    label_5.font = [UIFont systemFontOfSize:14.0];
    label_5.text = @"Статус";
    label_5.textAlignment = NSTextAlignmentCenter;
    label_5.textColor = [UIColor blackColor];
    label_5.backgroundColor = UIColor.whiteColor;
    label_5.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer_5 = label_5.layer;
    cellLayer_5.borderColor = [[UIColor blackColor] CGColor];
    cellLayer_5.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [tableHead addSubview:label_5];
    
    UILabel *label_6 = [[UILabel	alloc] initWithFrame:CGRectMake(650.0, 0, 118.0, 29)];
    label_6.tag = LABEL_TAG;
    label_6.font = [UIFont systemFontOfSize:14.0];
    label_6.text = @"Дата действия";
    label_6.textAlignment = NSTextAlignmentCenter;
    label_6.textColor = [UIColor blackColor];
    label_6.backgroundColor = UIColor.whiteColor;
    label_6.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    CALayer *cellLayer_6 = label_6.layer;
    cellLayer_6.borderColor = [[UIColor blackColor] CGColor];
    cellLayer_6.borderWidth = 1.f/UIScreen.mainScreen.scale;
    
    [tableHead addSubview:label_6];
    
    //myTableView.tableHeaderView = tableHead;
    [self.view addSubview:tableHead];
    
	UIToolbar *sectionHead = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 40, 768, 44)];
    
    NSMutableArray* btns = [[NSMutableArray alloc] initWithCapacity:3];
    
    // create a spacer
    UIBarButtonItem *bit = [[UIBarButtonItem alloc]
                            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [btns addObject:bit];

    UIBarButtonItem *custkey = [[UIBarButtonItem alloc] initWithTitle:@"Статус задачи" style:UIBarButtonItemStyleDone target:self action:@selector(showDream:)];
    
    [btns addObject:custkey];
    
    UIBarButtonItem *sourcekey = [[UIBarButtonItem alloc] initWithTitle:@"Источник" style:UIBarButtonItemStyleDone target:self action:@selector(showSource:)];
    
    [btns addObject:sourcekey];
    
    //UIBarButtonItem *setkey = [[[UIBarButtonItem alloc] initWithTitle:@"Назначено" style:UIBarButtonItemStyleDone target:self action:@selector(showSet:)] autorelease];
    
    //[btns addObject:setkey];
    
    [sectionHead setItems:btns animated:NO];

    sectionHead.tintColor = [UIColor blackColor];
    
    [self.view addSubview:sectionHead];

    if (isViewPushed == NO) {
		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStyleDone target:self action:@selector(cancel_Clicked:)];
        
        barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        
        self.navigationItem.rightBarButtonItem = barButton;
	}
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refresh) name:@"updateTasks" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(taskAdded) name:@"updateTasksNew" object:nil];
}

- (void)selectAllTasks {
    NSMutableArray *taskToLiveInArray   = [NSMutableArray array];
    NSMutableArray *taskDetToLiveInArray = [NSMutableArray array];
    
    taskList     = [NSMutableArray new];
    taskDetList  = [NSMutableArray new];
    
    copyTaskList    = [NSMutableArray new];
    copyTaskDetList = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        NSString *squl;
        
        squl = @"select TaskId, TaskName from TaskTable where CustAccount = ? group by TaskId, TaskName";
        
        sql  = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                NSString *taskId    = @"null";
                NSString *taskName  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    taskId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    taskName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [taskToLiveInArray   addObject:taskName];
                [taskDetToLiveInArray addObject:taskId];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}

    NSDictionary *taskToLiveInDict    = [NSDictionary dictionaryWithObject:taskToLiveInArray forKey:@"TaskName"];
    NSDictionary *taskDetToLiveInDict = [NSDictionary dictionaryWithObject:taskDetToLiveInArray forKey:@"TaskDetail"];
    
    [taskList    addObject:taskToLiveInDict];
    [taskDetList addObject:taskDetToLiveInDict];
}

- (void)selectWithFilters {
    NSMutableArray *taskToLiveInArray   = [NSMutableArray array];
    NSMutableArray *taskDetToLiveInArray = [NSMutableArray array];
    
    taskList     = [NSMutableArray new];
    taskDetList  = [NSMutableArray new];
    
    copyTaskList    = [NSMutableArray new];
    copyTaskDetList = [NSMutableArray new];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        NSString *squl;
        
        squl = @"select TaskId, TaskName from TaskTable where CustAccount = ? and 1=1 ";
        
        if (fdream) {
            squl = [NSString stringWithFormat:@"%@ and Status = '%@'", squl, fdream];
        }
        
        if (fsource)
            squl = [NSString stringWithFormat:@"%@ and %@", squl, fsource];
        
        if (fset) {
            squl = [NSString stringWithFormat:@"%@ and Setted = '%@'", squl, fset];
        }
        
        squl = [NSString stringWithFormat:@"%@ group by TaskId, TaskName", squl];
        sql  = [squl UTF8String];
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                NSString *taskId    = @"null";
                NSString *taskName  = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    taskId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    taskName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                [taskToLiveInArray   addObject:taskName];
                [taskDetToLiveInArray addObject:taskId];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    NSDictionary *taskToLiveInDict    = [NSDictionary dictionaryWithObject:taskToLiveInArray forKey:@"TaskName"];
    NSDictionary *taskDetToLiveInDict = [NSDictionary dictionaryWithObject:taskDetToLiveInArray forKey:@"TaskDetail"];
    
    [taskList    addObject:taskToLiveInDict];
    [taskDetList addObject:taskDetToLiveInDict];
}

- (void)showDream:(id)sender {
    [myTableView reloadData];
    
    if (!custDream) {
        custDream = [[CustDream alloc] init];
        custDream.delegate = self;
        custDream.fromTask = YES;
        custDream.fromCustTask = YES;
        custDream.custAcccount = custAccount;
        
        custDream.modalPresentationStyle = UIModalPresentationPopover;
        custDream.popoverPresentationController.barButtonItem = dreamBtn;
        
        [self presentViewController:custDream animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        custDream = nil;
    }
}

- (void)showBrand:(id)sender {
    [myTableView reloadData];
    
    if (!custBrand) {
        custBrand = [[CustBrand alloc] init];
        custBrand.delegate  = self;
        
        custBrand.modalPresentationStyle = UIModalPresentationPopover;
        custBrand.popoverPresentationController.barButtonItem = markBtn;
        
        [self presentViewController:custBrand animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        custBrand = nil;
    }
}

- (void)userDidSelectBrand:(NSMutableArray *)brandArray{
    if (custBrand.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        custBrand = nil;
    }
    
    fmark = brandArray.firstObject;
    
    [self selectWithFilters];
    [myTableView reloadData];
    
    
    [self setBarButton:markBtn highlighted:fmark != nil];
}

- (void)userDidSelectDream:(NSMutableArray *)dreamArray{
    if (custDream.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        custDream = nil;
    }

    fdream = dreamArray.firstObject;

    [self selectWithFilters];
    [myTableView reloadData];

    [self setBarButton:dreamBtn highlighted:fdream != nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (void)clearFilter {
    NSString *searchText = searchBar.text;

    fmark = nil;
    
    [self setBarButton:markBtn highlighted:NO];
    [self selectAllTasks];
    [myTableView reloadData];
    
    searchBar.text = searchText;
}

#pragma mark -
#pragma mark Managing the popover

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (searching) {
        return [copyTaskDetList count];
    } else {
        NSDictionary *dictionary = [taskDetList objectAtIndex:0];
        NSArray		 *array = [dictionary objectForKey:@"TaskDetail"];
    
        return [array count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    MyTableCell *cell = (MyTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[MyTableCell alloc] initWithFrame:CGRectZero];
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    if (searching) {
        UILabel *label_2 = [[UILabel	alloc] initWithFrame:CGRectMake(0.0, 0, 280.0, cell.bounds.size.height)];
        label_2.tag = LABEL_TAG;
        label_2.font = [UIFont systemFontOfSize:14.0];
        label_2.text = [NSString stringWithFormat:@"  %@", [copyTaskList objectAtIndex:indexPath.row]];
        label_2.textAlignment = NSTextAlignmentLeft;
        label_2.textColor = [UIColor blackColor];
        label_2.backgroundColor = UIColor.whiteColor;
        label_2.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_2];
        
        UILabel *label_de = [[UILabel	alloc] initWithFrame:CGRectMake(280.0, 0, 100.0, cell.bounds.size.height)];
        label_de.tag = LABEL_TAG;
        label_de.font = [UIFont systemFontOfSize:14.0];
        label_de.text = [self getTaskDateEnd:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
        label_de.textAlignment = NSTextAlignmentCenter;
        label_de.textColor = [UIColor blackColor];
        label_de.backgroundColor = UIColor.whiteColor;
        label_de.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_de];
        
        UILabel *label_3 = [[UILabel	alloc] initWithFrame:CGRectMake(380.0, 0, 70.0, cell.bounds.size.height)];
        label_3.tag = LABEL_TAG;
        label_3.font = [UIFont systemFontOfSize:14.0];
        label_3.text = [self getTaskSource:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
        label_3.textAlignment = NSTextAlignmentCenter;
        label_3.backgroundColor = UIColor.whiteColor;
        label_3.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_3];
        
        UILabel *label_4 = [[UILabel	alloc] initWithFrame:CGRectMake(450.0, 0, 100.0, cell.bounds.size.height)];
        label_4.tag = LABEL_TAG;
        label_4.font = [UIFont systemFontOfSize:14.0];
        label_4.text = [self getTaskResult:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
        
        NSString *taskType = [self getTaskTypeOfResult:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
        
        //if ([taskType isEqualToString:@"1"])
        //    label_4.text = @"Запись";
        
        if ([taskType isEqualToString:@"2"])
            label_4.text = [self getTaskListResult:[copyTaskDetList objectAtIndex:indexPath.row] listId:[self getTaskResult:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]]];
        /*
        if ([taskType isEqualToString:@"3"])
            label_4.text = @"Число";
        
        if ([taskType isEqualToString:@"4"])
            label_4.text = @"Да/Нет";
        
        if ([taskType isEqualToString:@"5"])
            label_4.text = @"Фото";
        */
        label_4.textAlignment = NSTextAlignmentCenter;
        label_4.textColor = [UIColor blackColor];
        label_4.backgroundColor = UIColor.whiteColor;
        label_4.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_4];
        
        UILabel *label_5 = [[UILabel	alloc] initWithFrame:CGRectMake(550.0, 0, 100.0, cell.bounds.size.height)];
        label_5.numberOfLines = 2;
        label_5.tag = LABEL_TAG;
        label_5.font = [UIFont systemFontOfSize:14.0];
        label_5.text = [self getTaskStatus:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
        
        if ([label_5.text isEqualToString:@"Готово"])
            label_5.textColor = [UIColor colorWithRed:34.0/255.0 green:139.0/255.0 blue:34.0/255.0 alpha:1];
        else
            label_5.textColor = [UIColor blackColor];
        
        if (![label_5.text isEqualToString:@"Готово"] && ! [label_5.text isEqualToString:@"Отказ"]) {
            NSDate *date = NSDate.date;
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            
            [formatter setDateFormat:dateFormat_dd_MM_YYYY];
            
            NSDate *endDate = [formatter dateFromString:[self getTaskDateEnd:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]]];
            
            NSCalendar       *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *components        = [gregorianCalendar components:NSCalendarUnitDay
                                                                       fromDate:date
                                                                         toDate:endDate
                                                                        options:0];

            if ([components day] < 7) {
                if ([components day] >= 0)
                    label_5.text = [NSString stringWithFormat:@"%@\nГорит", label_5.text];
                
                if ([components day] < 0)
                {
                    label_5.text = label_5.text = [NSString stringWithFormat:@"%@\nПросрочка", label_5.text];
                    cell.userInteractionEnabled = NO;
                }
                
                label_5.textColor = [UIColor redColor];
            }
        }
        
        label_5.textAlignment = NSTextAlignmentCenter;
        label_5.backgroundColor = UIColor.whiteColor;
        label_5.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_5];
        
        UILabel *label_6 = [[UILabel	alloc] initWithFrame:CGRectMake(650.0, 0, 118.0, cell.bounds.size.height)];
        label_6.tag = LABEL_TAG;
        label_6.font = [UIFont systemFontOfSize:14.0];
        label_6.text = [self getTaskTransDate:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
        label_6.textAlignment = NSTextAlignmentCenter;
        label_6.textColor = [UIColor blackColor];
        label_6.backgroundColor = UIColor.whiteColor;
        label_6.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_6];
        
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    } else {
        NSDictionary	*dictionary = [taskList objectAtIndex:0];
        NSArray			*array		= [dictionary objectForKey:@"TaskName"];
        
        NSDictionary	*dictionaryId = [taskDetList objectAtIndex:0];
        NSArray			*arrayId	  = [dictionaryId objectForKey:@"TaskDetail"];
        
        UILabel *label_2 = [[UILabel	alloc] initWithFrame:CGRectMake(0.0, 0, 280.0, cell.bounds.size.height)];
        label_2.tag = LABEL_TAG;
        label_2.font = [UIFont systemFontOfSize:14.0];
        label_2.text = [NSString stringWithFormat:@"  %@", [array objectAtIndex:indexPath.row]];
        label_2.textAlignment = NSTextAlignmentLeft;
        label_2.textColor = [UIColor blackColor];
        label_2.backgroundColor = UIColor.whiteColor;
        label_2.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_2];
        
        UILabel *label_de = [[UILabel	alloc] initWithFrame:CGRectMake(280.0, 0, 100.0, cell.bounds.size.height)];
        label_de.tag = LABEL_TAG;
        label_de.font = [UIFont systemFontOfSize:14.0];
        label_de.text = [self getTaskDateEnd:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
        label_de.textAlignment = NSTextAlignmentCenter;
        label_de.textColor = [UIColor blackColor];
        label_de.backgroundColor = UIColor.whiteColor;
        label_de.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_de];
        
        UILabel *label_3 = [[UILabel	alloc] initWithFrame:CGRectMake(380.0, 0, 70.0, cell.bounds.size.height)];
        label_3.tag = LABEL_TAG;
        label_3.font = [UIFont systemFontOfSize:14.0];
        label_3.text = [self getTaskSource:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
        label_3.textAlignment = NSTextAlignmentCenter;
        label_3.backgroundColor = UIColor.whiteColor;
        label_3.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_3];
        
        UILabel *label_4 = [[UILabel	alloc] initWithFrame:CGRectMake(450.0, 0, 100.0, cell.bounds.size.height)];
        label_4.tag = LABEL_TAG;
        label_4.font = [UIFont systemFontOfSize:14.0];
        
        label_4.text = [self getTaskResult:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
        NSString *taskType = [self getTaskTypeOfResult:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
        
        if ([taskType isEqualToString:@"2"])
            label_4.text = [self getTaskListResult:[arrayId objectAtIndex:indexPath.row] listId:[self getTaskResult:custAccount taskId:[arrayId objectAtIndex:indexPath.row]]];
        
        label_4.textAlignment = NSTextAlignmentCenter;
        label_4.textColor = [UIColor blackColor];
        label_4.backgroundColor = UIColor.whiteColor;
        label_4.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_4];
        
        UILabel *label_5 = [[UILabel	alloc] initWithFrame:CGRectMake(550.0, 0, 100.0, cell.bounds.size.height)];
        label_5.numberOfLines = 2;
        label_5.tag = LABEL_TAG;
        label_5.font = [UIFont systemFontOfSize:14.0];
        label_5.text = [self getTaskStatus:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
        
        if ([label_5.text isEqualToString:@"Готово"])
            label_5.textColor = [UIColor colorWithRed:34.0/255.0 green:139.0/255.0 blue:34.0/255.0 alpha:1];
        else
            label_5.textColor = [UIColor blackColor];
        
        if (![label_5.text isEqualToString:@"Готово"] && ! [label_5.text isEqualToString:@"Отказ"]) {
            NSDate *date = NSDate.date;
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            
            [formatter setDateFormat:dateFormat_dd_MM_YYYY];
            
            NSDate *endDate = [formatter dateFromString:[self getTaskDateEnd:custAccount taskId:[arrayId objectAtIndex:indexPath.row]]];
            
            NSCalendar       *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *components        = [gregorianCalendar components:NSCalendarUnitDay
                                                                       fromDate:date
                                                                         toDate:endDate
                                                                        options:0];

            if ([components day] < 7) {
                if ([components day] >= 0)
                    label_5.text = [NSString stringWithFormat:@"%@\nГорит", label_5.text];
                
                if ([components day] < 0)
                {
                    label_5.text = label_5.text = [NSString stringWithFormat:@"%@\nПросрочка", label_5.text];
                    cell.userInteractionEnabled = NO;
                }
                
                label_5.textColor = [UIColor redColor];
            }
        }
        
        label_5.textAlignment = NSTextAlignmentCenter;
        label_5.backgroundColor = UIColor.whiteColor;
        label_5.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_5];
        
        UILabel *label_6 = [[UILabel	alloc] initWithFrame:CGRectMake(650.0, 0, 118.0, cell.bounds.size.height)];
        label_6.tag = LABEL_TAG;
        label_6.font = [UIFont systemFontOfSize:14.0];
        label_6.text = [self getTaskTransDate:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
        label_6.textAlignment = NSTextAlignmentCenter;
        label_6.textColor = [UIColor blackColor];
        label_6.backgroundColor = UIColor.whiteColor;
        label_6.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        [cell.contentView addSubview:label_6];
        
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
    
    return cell;
}

-(NSString *)getCustName:(NSString *)custAccount {
    NSString *custName = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        sql = "select Name from CustTable where CustAccount = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    custName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
        sqlite3_close(database);
	
    return custName;
}

-(NSString *)getTaskListResult:(NSString*)taskId listId:(NSString*)listId {
    NSString *listName = @"Не выбрано";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = "select LineDescription from TaskList where TaskId = ? and LineId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
            sqlite3_bind_text(selectstmt, 1, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [listId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
				if (sqlite3_column_text(selectstmt, 0))
                    listName  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
	{
		sqlite3_close(database);
	}
    
    return listName;
}


-(NSString *)getTaskStatus:(NSString *)custAccount taskId:(NSString *)taskId {
    NSString *status = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        sql = "select Status from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    status  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
        sqlite3_close(database);
	
    return status;
}

-(NSString *)getTaskTransDate:(NSString *)custAcc taskId:(NSString *)taskId {
    NSString *transDate = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        sql = "select TransDate from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAcc UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    transDate  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
        sqlite3_close(database);
	
    return transDate;
}

-(NSString *)getTaskTypeOfResult:(NSString *)custAccount taskId:(NSString *)taskId {
    NSString *type = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        sql = "select TypeOfResult from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    type  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
        sqlite3_close(database);
	
    return type;
}

-(NSString *)getTaskDateEnd:(NSString *)custAccount taskId:(NSString *)taskId {
    NSString *dateEnd = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        sql = "select DateEnd from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    dateEnd  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
        sqlite3_close(database);
	
    return dateEnd;
}

-(NSString *)getTaskResult:(NSString *)custAccount taskId:(NSString *)taskId {
    NSString *result = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        sql = "select Result from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    result  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
        sqlite3_close(database);
	
    return result;
}

-(NSString *)getTaskSource:(NSString *)custAccount taskId:(NSString *)taskId {
    NSString *source = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        sql = "select Source from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    source  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
        sqlite3_close(database);
	
    return source;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = UIColor.whiteColor;
}


#pragma mark -
#pragma mark Search Bar

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar {
	if (searching)
		return;
	
	if (ovController == nil)
		ovController = [[OverlayCustTasksViewController alloc] initWithNibName:@"OverlayCustTasksViewController" bundle:NSBundle.mainBundle];
	
	CGFloat width = 768;
	CGFloat height = 65000;
	
	//Parameters x = origion on x-axis, y = origon on y-axis.
	CGRect frame = CGRectMake(0, 0, width, height);
	ovController.view.frame = frame;
	ovController.view.backgroundColor = [UIColor grayColor];
	ovController.view.alpha = 0.5;
	
	ovController.rvController = self;
	
	[myTableView insertSubview:ovController.view aboveSubview:self.parentViewController.view];
	
	searching = YES;
	letUserSelectRow = NO;
	myTableView.scrollEnabled = NO;
	
	//Add the done button.
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                              target:self action:@selector(doneSearching_Clicked:)];
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
	
	[copyTaskList    removeAllObjects];
    [copyTaskDetList removeAllObjects];
	
	if ([searchText length] > 0)
	{
		[ovController.view removeFromSuperview];
		searching = YES;
		letUserSelectRow = YES;
		myTableView.scrollEnabled = YES;
		[self searchTableView];
	}
	else
	{
		CGFloat width = 768;
        CGFloat height = 65000;
        
        CGRect frame = CGRectMake(0, 80, width, height);
        
        ovController.view.frame = frame;
        
        [self.view insertSubview:ovController.view aboveSubview:self.parentViewController.view];
		
		searching = NO;
		letUserSelectRow = NO;
		myTableView.scrollEnabled = NO;
	}
	
	[myTableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
	[self searchTableView];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.text = @"";
}

- (void)searchTableView{
    NSString *searchText               = searchBar.text;
    
	NSMutableArray *searchArray        = [NSMutableArray new];
    NSMutableArray *searchArrayDet     = [NSMutableArray new];
    
	for (NSDictionary *dictionary in taskList)
	{
		NSArray *array = [dictionary objectForKey:@"TaskName"];
		[searchArray addObjectsFromArray:array];
    }
    
    for (NSDictionary *dictDetail in taskDetList)
	{
		NSArray *array = [dictDetail objectForKey:@"TaskDetail"];
		[searchArrayDet addObjectsFromArray:array];
    }
    
	for (NSString *sTemp in searchArray)
	{
        i = i + 1;
        
        NSRange titleResultsRange = [sTemp rangeOfString:searchText options:NSCaseInsensitiveSearch];
		
		if (titleResultsRange.length > 0) {
            [copyTaskList    addObject:sTemp];
            [copyTaskDetList addObject:[searchArrayDet objectAtIndex:i - 1]];
        }
        
	}
	
    i = 0;

    searchArray = nil;

    searchArrayDet = nil;
}

- (void)doneSearching_Clicked:(id)sender {
    searchBar.text = @"";
	[searchBar resignFirstResponder];
	
	letUserSelectRow = YES;
	searching = NO;
	self.navigationItem.rightBarButtonItem = nil;
	myTableView.scrollEnabled = YES;
	
	[ovController.view removeFromSuperview];
    ovController = nil;
    
    self.navigationItem.leftBarButtonItem = nil;
    [myTableView reloadData];
    
    UIBarButtonItem *addCustomerButton = [[UIBarButtonItem alloc] initWithTitle:@"Создать новую" style:UIBarButtonItemStyleDone target:self action:@selector(createTask:)];
    
    self.navigationItem.leftBarButtonItem = addCustomerButton;
    
    if (isViewPushed == NO) {
		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStyleDone target:self action:@selector(cancel_Clicked:)];
        
        barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        
        self.navigationItem.rightBarButtonItem = barButton;
	}
}

- (void)hideSearch{
    [searchBar resignFirstResponder];
	
	[ovController.view removeFromSuperview];
    ovController = nil;
    
    [myTableView reloadData];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self hideSearch];
    
    BOOL openTask = NO;
    
    if (searching) {
        if ([[self getTaskVisit:[copyTaskDetList objectAtIndex:indexPath.row]] isEqualToString:@"0"])
            openTask = YES;
        else
        {
            if ([self custInVisit:custAccount])
                openTask = YES;
            else
                openTask = FALSE;
        }
    } else {
        NSDictionary	*dictionaryId = [taskDetList objectAtIndex:0];
        NSArray			*arrayId	  = [dictionaryId objectForKey:@"TaskDetail"];
        
        if ([[self getTaskVisit:[arrayId objectAtIndex:indexPath.row]] isEqualToString:@"0"])
            openTask = YES;
        else
        {
            if ([self custInVisit:custAccount])
                openTask = YES;
            else
                openTask = FALSE;
        }
    }
    
    if (openTask) {
        TaskTransViewController *fvController = [[TaskTransViewController alloc] initWithNibName: @"TaskTransViewController" bundle: nil];
        
        fvController.isViewPushed = NO;
        fvController.custAccount  = custAccount;
        fvController.custName     = [self getCustName:custAccount];
        
        if (searching) {
            fvController.taskId       = [copyTaskDetList objectAtIndex:indexPath.row];
            fvController.taskName     = [copyTaskList objectAtIndex:indexPath.row];
            fvController.status       = [self getTaskStatus:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
            fvController.typeOfResult = [self getTaskTypeOfResult:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
            fvController.result       = [self getTaskResult:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
            fvController.dateEnd      = [self getTaskDateEnd:custAccount taskId:[copyTaskDetList objectAtIndex:indexPath.row]];
        } else {
            NSDictionary	*dictionaryId = [taskDetList objectAtIndex:0];
            NSArray			*arrayId	  = [dictionaryId objectForKey:@"TaskDetail"];
            
            NSDictionary	*dictionary = [taskList objectAtIndex:0];
            NSArray			*array	    = [dictionary objectForKey:@"TaskName"];
            
            fvController.taskId       = [arrayId objectAtIndex:indexPath.row];
            fvController.taskName     = [array objectAtIndex:indexPath.row];
            fvController.status       = [self getTaskStatus:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
            fvController.typeOfResult = [self getTaskTypeOfResult:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
            fvController.result       = [self getTaskResult:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
            fvController.dateEnd      = [self getTaskDateEnd:custAccount taskId:[arrayId objectAtIndex:indexPath.row]];
            
        }
        
        if (infoNavController == nil)
            infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
        
        infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self.navigationController presentViewController:infoNavController animated:YES completion:nil];

        fvController = nil;
        infoNavController = nil;
    } else {
        [AlertWorkerObjc alertWithTitle:@"Задача" message:@"Задача может выполняться только в режиме посещения"];
    }
}

-(NSString *)getTaskVisit:(NSString *)taskId {
    NSString *visit = @"";
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
		const char *sql = nil;
		
        sql = "select Visit from TaskTable where CustAccount = ? and TaskId = ?";
        
        sqlite3_stmt *selectstmt;
		
		if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK)
		{
		    sqlite3_bind_text(selectstmt, 1, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [taskId UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW)
			{
                if (sqlite3_column_text(selectstmt, 0))
                    visit  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
            }
		}
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
	}
	else
        sqlite3_close(database);
	
    return visit;
}

-(BOOL)custInVisit:(NSString *)custAcc {
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


- (void)finalizeStatements {
	if (database)sqlite3_close(database);
}

- (void)scrollToTop{
    NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [myTableView selectRowAtIndexPath:topIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}


- (void)createTask:(id)sender {
    TaskCreateViewController *fvController = [[TaskCreateViewController alloc] initWithNibName: @"TaskCreateViewController" bundle: nil];
    
    fvController.isViewPushed = NO;
    fvController.custAcc      = custAccount;
    fvController.custNameStr  = [self getCustName:custAccount];
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNavController.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
    
    infoNavController.view.superview.bounds = CGRectMake(0,0,500,300);

    fvController = nil;
    infoNavController = nil;
}

- (void)addTask:(id)sender {
    SetTaskToCustViewController *fvController = [[SetTaskToCustViewController alloc] initWithNibName: @"SetTaskToCustViewController" bundle: nil];
    
    fvController.isViewPushed = NO;
    fvController.custAcc      = custAccount;
    fvController.custNameStr  = [self getCustName:custAccount];
    
    if (infoNavController == nil)
        infoNavController = [[UINavigationController alloc] initWithRootViewController:fvController];
    
    infoNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    infoNavController.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
    
    [self.navigationController presentViewController:infoNavController animated:YES completion:nil];
    
    infoNavController.view.superview.bounds = CGRectMake(0,0,500,300);

    fvController = nil;
    infoNavController = nil;
}

- (void)taskAdded {

    [self selectWithFilters];
    [myTableView reloadData];
}

- (void)refresh{
    [myTableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)showSource:(id)sender {
    [myTableView reloadData];
    
    if (!taskSource) {
        taskSource = [[TaskSource alloc] init];
        taskSource.delegate = self;
        taskSource.fromCust = YES;
        taskSource.custAccount = custAccount;
        
        taskSource.modalPresentationStyle = UIModalPresentationPopover;
        taskSource.popoverPresentationController.barButtonItem = sender;
        
        [self presentViewController:taskSource animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        taskSource = nil;
    }
    sourceBtn = sender;
}

- (void)showSet:(id)sender {
    [myTableView reloadData];
    
    if (!setTask) {
        setTask = [[SetTask alloc] init];
        setTask.delegate = self;
        setTask.fromCust = YES;
        setTask.custAccount = custAccount;
        
        setTask.modalPresentationStyle = UIModalPresentationPopover;
        setTask.popoverPresentationController.barButtonItem = sender;
        
        [self presentViewController:setTask animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        setTask = nil;
    }
    setBtn = sender;
}

- (void)selectSetTask:(NSString *)setValue {
    if (setTask.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        setTask = nil;
    }

    fset = setValue;
    
    if ([setValue isEqualToString:@"Своя"])
        fset = @"0";
    else if ([setValue isEqualToString:@"Назначенная"])
            fset = @"1";

    [self selectWithFilters];
    [myTableView reloadData];
    
    if (fset == nil) {
        [setBtn setTintColor:UIColor.clearColor];
    } else {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [setBtn setTintColor:color];
    }
}

- (void)userDidSelectTaskSources:(NSMutableArray *)taskSources {
    if (taskSource.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        taskSource = nil;
    }
    
    fsource = taskSources.firstObject;

    [self selectWithFilters];
    [myTableView reloadData];
    
    if (fsource == nil) {
        [sourceBtn setTintColor:UIColor.clearColor];
    } else {
        UIColor *color = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        [sourceBtn setTintColor:color];
    }
}

#pragma mark - Button styling methods
- (void)setBarButton:(UIBarButtonItem *)button highlighted:(BOOL)highlighted {
    [(RWBorderedButton *)button.customView setHighlightedState:highlighted];
}


@end


