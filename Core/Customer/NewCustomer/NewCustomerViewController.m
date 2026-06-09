//
//  NewCustomerViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 29.11.2021.
//

#import "NewCustomerViewController.h"
#import "NewCustomerDataPickerViewController.h"
#import "NewCustomerContactViewController.h"

#import "AppDelegate.h"
#import "PutNewCustomerRequest.h"
#import "XMLWriter.h"

#import "GeneratedAssetSymbols.h"

typedef NS_ENUM(NSUInteger, DataPickerMode) {
    DataPickerModeClientType = 0,
    DataPickerModePartnerKind = 1,
    DataPickerModeWorksWith = 2
};

static NSString *const kTwoRegionPropertyID = @"00028";

@interface NewCustomerViewController () <UITextFieldDelegate, NewCustomerDataPickerViewControllerDelegate, NewCustomerContactViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UIScrollView *mainScrollView;

@property (nonatomic, weak) IBOutlet UILabel *lblClientType;
@property (nonatomic, weak) IBOutlet UILabel *lblPartnerKind;
@property (nonatomic, weak) IBOutlet UILabel *lblWorksWith;

@property (nonatomic, weak) IBOutlet UITextField *txtNameField;
@property (nonatomic, weak) IBOutlet UITextField *txtAddressField;
@property (nonatomic, weak) IBOutlet UITextField *txtINNField;

@property (nonatomic, weak) IBOutlet UILabel *lblCoordinates;
@property (nonatomic, weak) IBOutlet UIButton *btnAddCoordinates;

@property (nonatomic, weak) IBOutlet UILabel *lblContactName;
@property (nonatomic, weak) IBOutlet UILabel *lblContactRole;
@property (nonatomic, weak) IBOutlet UIButton *btnAddContact;

@property (nonatomic, weak) IBOutlet UITextField *txtCommentField;

@property (nonatomic, strong) NSMutableDictionary *customerData;
@property (nonatomic, strong) NSMutableArray *clientTypesArray;
@property (nonatomic, strong) NSArray *partnerKindsArray;
@property (nonatomic, strong) NSMutableArray *worksWithArray;

@end

static sqlite3 *database = nil;

@implementation NewCustomerViewController {
    DataPickerMode _dataPickerMode;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self turnOnKeyboardTracking:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    [self turnOnKeyboardTracking:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self prepareData];
}

#pragma mark - UI
- (void)setupNavBar {
    //NavBar Setup
    self.navigationItem.title = @"Клиент";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:UIColor.whiteColor tintColor:[UIColor colorNamed:ACColorNameMLKLightBlue]];
    
    UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self  action:@selector(btnCancelTapped)];
    self.navigationItem.leftBarButtonItem = btnCancel;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self  action:@selector(doneButtonTapped)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIView *statusBarUnderlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, -ASPFunctions.statusBarHeight, self.navigationController.navigationBar.frame.size.width, ASPFunctions.statusBarHeight)];
    statusBarUnderlayView.backgroundColor = [UIColor blackColor];
    [self.navigationController.navigationBar addSubview:statusBarUnderlayView];
}

- (void)prepareData{
    self.customerData = [NSMutableDictionary new];
    self.customerData[@"UID"] = NSUUID.UUID.UUIDString;
    
    [self getClientTypes];
    self.partnerKindsArray = @[@{@"name" : @"Юр. лицо", @"id" : @"юр"}, @{@"name" : @"Физ. лицо", @"id" : @"физ"}];
    [self getWorksWithArray];
}

#pragma mark - Button Actions
- (void)btnCancelTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonTapped {
    [self.view endEditing:YES];
    
    if ([self isCustomerValid]) {
        [self sendNewCustomer];
    }
}

- (IBAction)btnClientTypeTapped:(id)sender {
    _dataPickerMode = DataPickerModeClientType;
    [self pushToDataPickerVC:self.clientTypesArray selectedObject:self.customerData[@"clientType"] title:@"Тип клиента"];
}

- (IBAction)btnPartnerKindTapped:(id)sender {
    _dataPickerMode = DataPickerModePartnerKind;
    [self pushToDataPickerVC:self.partnerKindsArray selectedObject:self.customerData[@"partnerKind"] title:@"Вид контрагента"];
}

- (IBAction)btnWorksWithTapped:(id)sender {
    _dataPickerMode = DataPickerModeWorksWith;
    [self pushToDataPickerVC:self.worksWithArray selectedObject:self.customerData[@"worksWith"] title:@"Работает с Юр. лицом"];
}

- (IBAction)btnAddCoordinatesTapped:(id)sender {
    if (!self.customerData[@"coordinates"]) {
        [self getCoordinates];
    } else {
        self.customerData[@"coordinates"] = nil;
        self.lblCoordinates.text = @"Координаты";
        [ASPFunctions setButtonTitleWithoutAnimation:self.btnAddCoordinates title:@"Добавить координаты"  state:UIControlStateNormal];
    }
}

- (IBAction)btnAddContactTapped:(id)sender {
    if (!self.customerData[@"contact"]) {
        NewCustomerContactViewController *newCustomerContactVC = [[UIStoryboard storyboardWithName:@"NewCustomer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(NewCustomerContactViewController.class)];
        newCustomerContactVC.delegate = self;
        
        [self.navigationController pushViewController:newCustomerContactVC animated:YES];
    } else {
        self.customerData[@"contact"] = nil;
        self.lblContactName.text = @"ФИО";
        self.lblContactRole.text = @"Должность";
        [ASPFunctions setButtonTitleWithoutAnimation:self.btnAddContact title:@"Добавить контакт" state:UIControlStateNormal];
    }
}

#pragma mark - Data
- (void)getClientTypes {
    self.clientTypesArray = [NSMutableArray new];
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select PropertyValueName, PropertyValueID from TwoRegion where PropertyID == ? order by PropertyValueName";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(selectstmt, 1, [kTwoRegionPropertyID UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *object = [NSMutableDictionary new];
                NSString *name = @"";
                NSString *value = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                object[@"name"] = name;
                object[@"id"] = value;
                [self.clientTypesArray addObject:object];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
}

- (void)getWorksWithArray{
    self.worksWithArray = [NSMutableArray new];
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        const char *sql = "select Name, FirmId from FirmTable";
        
        sqlite3_stmt *selectstmt;
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) {
            while (sqlite3_step(selectstmt) == SQLITE_ROW) {
                NSMutableDictionary *object = [NSMutableDictionary new];
                NSString *name = @"";
                NSString *value = @"";
                
                if (sqlite3_column_text(selectstmt, 0))
                    name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                object[@"name"] = name;
                object[@"id"] = value;
                [self.worksWithArray addObject:object];
            }
        }
        sqlite3_finalize(selectstmt);
    }
    sqlite3_close(database);
}

- (void)getCoordinates {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!CLLocationManager.locationServicesEnabled || AppDelegate.sharedLocationManager.authorizationStatus == kCLAuthorizationStatusDenied) {
            dispatch_async(dispatch_get_main_queue(),^() {
                [AlertWorkerObjc alertWithTitle:@"Служба геолокации отключена" message:@"Включите службу через настройки устройства."];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(),^() {
                AppDelegate *appDelegateIPad = (AppDelegate *)UIApplication.sharedApplication.delegate;
                CLLocationCoordinate2D coordinate = appDelegateIPad.currentLocation.coordinate;
                self.customerData[@"coordinates"] = [NSString stringWithFormat:@"%f,%f", coordinate.longitude, coordinate.latitude];
                
                self.lblCoordinates.text = self.customerData[@"coordinates"];
                [ASPFunctions setButtonTitleWithoutAnimation:self.btnAddCoordinates title:@"Очистить" state:UIControlStateNormal];
            });
        }
    });
}

- (void)sendNewCustomer {
    NSDate *date = NSDate.date;
    NSDateFormatter *dateFormatter = NSDateFormatter.new;
    dateFormatter.dateFormat = @"dd.MM.yyyy HH:mm";
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    XMLWriter *xmlWriter = [XMLWriter new];
    
    [xmlWriter writeStartElement:@"sam:Value"];
    
    [xmlWriter writeStartElement:@"sam:Date"];
    [xmlWriter writeCharacters:dateString];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Name"];
    [xmlWriter writeCharacters:self.customerData[@"name"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:FactAddress"];
    [xmlWriter writeCharacters:self.customerData[@"address"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Phone"];
    [xmlWriter writeCharacters:self.customerData[@"contact"][@"phone"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Email"];
    [xmlWriter writeCharacters:self.customerData[@"contact"][@"mail"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Contact"];
    [xmlWriter writeCharacters:self.customerData[@"contact"][@"name"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Location"];
    [xmlWriter writeCharacters:self.customerData[@"coordinates"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Uid"];
    [xmlWriter writeCharacters:self.customerData[@"UID"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:SixProp"];
    [xmlWriter writeCharacters:self.customerData[@"clientType"][@"id"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Type"];
    [xmlWriter writeCharacters:self.customerData[@"partnerKind"][@"id"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:FirmCode"];
    [xmlWriter writeCharacters:self.customerData[@"worksWith"][@"id"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:INN"];
    [xmlWriter writeCharacters:self.customerData[@"inn"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:RoleCode"];
    [xmlWriter writeCharacters:self.customerData[@"contact"][@"role"][@"code"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"sam:Note"];
    [xmlWriter writeCharacters:self.customerData[@"comment"]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    // get the resulting XML string
    NSString *xml = [xmlWriter toString];
    
    [SVProgressHUD showWithStatus:@"Отправка..." ];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                             selector:@selector(didSendNewCustomerNotification:)
                                                 name:@"SendNewCustomerNotification"
                                               object:nil];
    
    PutNewCustomerRequest *sendNewCustomer = [PutNewCustomerRequest new];
    sendNewCustomer.custAccount = self.customerData[@"UID"];
    [sendNewCustomer sendCustomer:xml];
}

- (void)didSendNewCustomerNotification:(NSNotification *)notification {
    [SVProgressHUD dismiss];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"SendNewCustomerNotification" object:nil];
    
    NSString *sendStatus = (NSString *)notification.object;
    if ([sendStatus isEqual:@"Sended"]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [AlertWorkerObjc alertWithTitle:@"Новый клиент успешно отправлен."];
        }];
    } else {
        [AlertWorkerObjc alertWithTitle:@"Не удалось отправить нового клиента. Пожалуйста, проверьте корректность введённых данных и повторите попытку."];
    }
}

#pragma mark - NewCustomerDataPickerViewControllerDelegate
- (void)userDidPickCustomerData:(NSDictionary *)data {
    if (_dataPickerMode == DataPickerModeClientType) {
        self.customerData[@"clientType"] = data;
        self.lblClientType.text = data[@"name"];
    } else if (_dataPickerMode == DataPickerModePartnerKind) {
        self.customerData[@"partnerKind"] = data;
        self.lblPartnerKind.text = data[@"name"];
    } else if (_dataPickerMode == DataPickerModeWorksWith) {
        self.customerData[@"worksWith"] = data;
        self.lblWorksWith.text = data[@"name"];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - NewCustomerContactViewControllerDelegate
- (void)userDidAddContact:(NSDictionary *)contact {
    self.customerData[@"contact"] = contact;
    self.lblContactName.text = contact[@"name"];
    self.lblContactRole.text = contact[@"role"][@"name"];
    [ASPFunctions setButtonTitleWithoutAnimation:self.btnAddContact title:@"Удалить" state:UIControlStateNormal];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Helpers
- (void)pushToDataPickerVC:(NSArray *)dataSource selectedObject:(NSDictionary *)selectedObject title:(NSString *)title {
    NewCustomerDataPickerViewController *dataPickerVC = [[UIStoryboard storyboardWithName:@"NewCustomer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(NewCustomerDataPickerViewController.class)];
    dataPickerVC.title = title;
    dataPickerVC.delegate = self;
    dataPickerVC.dataSource = dataSource;
    dataPickerVC.selectedObject = selectedObject;
    
    [self.navigationController pushViewController:dataPickerVC animated:YES];
}

- (BOOL)isCustomerValid {
    NSString *errorMessage = @"";
    
    if (!self.customerData[@"clientType"]) {
        errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- Тип клиента"];
    }
    
    if (!self.customerData[@"partnerKind"]) {
        errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- Вид контрагента"];
    }
    
    if ([self.customerData[@"name"] length] < 2) {
        errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- Наименование"];
    }
    
    if ([self.customerData[@"address"] length] < 2) {
        errorMessage = [NSString stringWithFormat:@"%@%@", errorMessage, @"\n- Адрес"];
    }
    
    if (errorMessage.length > 0) {
        [AlertWorkerObjc alertWithTitle:@"Следующие поля должны быть заполнены:" message:errorMessage];
    }
    
    return errorMessage.length < 1;
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.txtNameField) {
        self.customerData[@"name"] = textField.text;
    }
    
    if (textField == self.txtAddressField) {
        self.customerData[@"address"] = textField.text;
    }
    
    if (textField == self.txtINNField) {
        self.customerData[@"inn"] = textField.text;
    }
    
    if (textField == self.txtCommentField) {
        self.customerData[@"comment"] = textField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Keyboard & Textfield Mngmnt
- (void)turnOnKeyboardTracking:(BOOL)isOn {
    if (isOn) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    } else {
        [NSNotificationCenter.defaultCenter removeObserver:self];
    }
}

#pragma mark - Keyboard Methods
//1st Step
- (void)keyboardWillShow:(NSNotification *)notification {
    [self animateKeyboardWithDuration:[[[notification userInfo] objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue] frame:[[[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue] options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue]<<16];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self animateKeyboardWithDuration:[[[notification userInfo] objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue] frame:CGRectZero options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue]<<16];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    [self animateKeyboardWithDuration:[[[notification userInfo] objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue] frame:[[[notification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue] options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue]<<16];
}

//2nd Step
- (void)animateKeyboardWithDuration:(CGFloat)duration frame:(CGRect)keyboardFrame options:(UIViewAnimationOptions)animOptions {
    [UIView animateWithDuration:duration delay:0 options:(animOptions | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        
        CGFloat keyboardHeight = keyboardFrame.size.height;
        
        UIWindow *window = ASPFunctions.mainKeyWindow;
        keyboardHeight -= window.safeAreaInsets.bottom;
        
        [self updateScrollInsets:keyboardHeight < 0.0 ? 0.0 : keyboardHeight];
    }completion:nil];
}

- (void)updateScrollInsets:(CGFloat)keyboardHeight {
    self.mainScrollView.contentInset = UIEdgeInsetsMake(self.mainScrollView.contentInset.top, self.mainScrollView.contentInset.left, keyboardHeight, self.mainScrollView.contentInset.right);
    self.mainScrollView.scrollIndicatorInsets = self.mainScrollView.contentInset;
}

@end
