//
//  NewCustomerContactViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 29.11.2021.
//

#import "NewCustomerContactViewController.h"
#import "NewCustomerDataPickerViewController.h"

#import "SHSPhoneLibrary.h"

#import "PartnersRequest.h"

static const NSInteger kPhoneNumberLength = 18;

@interface NewCustomerContactViewController () <UITextFieldDelegate, NewCustomerDataPickerViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UITextField *txtNameField;
@property (nonatomic, weak) IBOutlet UILabel *lblContactRole;
@property (nonatomic, weak) IBOutlet SHSPhoneTextField *txtPhoneField;
@property (nonatomic, weak) IBOutlet UIButton *checkPhoneButton;
@property (nonatomic, weak) IBOutlet UITextField *txtMailField;

@property (nonatomic, assign) BOOL isLoadingPartners;

@end

@implementation NewCustomerContactViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavBar];
    [self prepareData];
    
    //Observers
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(partnersReceived:) name:@"partnersReceived" object:nil];
}

#pragma mark - UI
- (void)setupNavBar {
    self.navigationItem.title = @"Контакт";
    
    if (self.navigationController.viewControllers.count == 1) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self  action:@selector(cancelButtonTapped)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self  action:@selector(doneButtonTapped)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)prepareData {
    [self.txtPhoneField.formatter setDefaultOutputPattern:@"+7 (###) ###-##-##"];
    
    if (!self.contactData) {
        self.contactData = [NSMutableDictionary new];
    } else {
        self.txtNameField.text = self.contactData[@"name"];
        self.lblContactRole.text = self.contactData[@"role"][@"name"];
        
        NSString *phone = self.contactData[@"phone"];
        if (phone.length == 11) {
            phone = [phone stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        [self.txtPhoneField setFormattedText:phone];
        
        self.txtMailField.text = self.contactData[@"mail"];
    }
    
    __weak typeof(self) weakSelf = self;
    self.txtPhoneField.textDidChangeBlock = ^(UITextField *textField) {
        weakSelf.checkPhoneButton.enabled = !weakSelf.isLoadingPartners && textField.text.length == kPhoneNumberLength;
    };
    
    self.checkPhoneButton.configurationUpdateHandler = ^(UIButton *button) {
        UIButtonConfiguration *config = button.configuration;
        
        if (weakSelf.isLoadingPartners) {
            button.userInteractionEnabled = NO;
            config.title = @"Проверяем...";
            config.showsActivityIndicator = YES;
        } else {
            button.userInteractionEnabled = YES;
            config.title = @"Проверить телефон";
            config.showsActivityIndicator = NO;
        }
        
        button.configuration = config;
    };
}

#pragma mark - Button Actions
- (void)cancelButtonTapped {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonTapped {
    [self.view endEditing:YES];
    
    if ([self.delegate respondsToSelector:@selector(userDidAddContact:)]) {
        [self.delegate userDidAddContact:self.contactData];
    }
}

- (IBAction)btnContactRoleTapped:(id)sender {
    NewCustomerDataPickerViewController *dataPickerVC = [[UIStoryboard storyboardWithName:@"NewCustomer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(NewCustomerDataPickerViewController.class)];
    dataPickerVC.title = @"Должность";
    dataPickerVC.delegate = self;
    dataPickerVC.dataSource = [PersistenceWorker load:@"contactRolesArray"];
    dataPickerVC.selectedObject = self.contactData[@"role"];
    
    [self.navigationController pushViewController:dataPickerVC animated:YES];
}

- (IBAction)checkPhoneButtonTapped:(UIButton *)sender {
    self.isLoadingPartners = YES;
    
    [sender setNeedsUpdateConfiguration];
    
    NSString *phone = [self.txtPhoneField.phoneNumber stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"8"];
    
    PartnersRequest *request = [PartnersRequest new];
    [request getPartners:phone];
}

#pragma mark - Notifications
- (void)partnersReceived:(NSNotification *)notification {
    if ([notification.object isKindOfClass:NSArray.class]) {
        NSArray *partners = notification.object;
        
        NSMutableArray *buttons = [NSMutableArray new];
        for (NSDictionary *partner in partners) {
            [buttons addObject:partner[@"name"]];
        }
        
        if (buttons.count > 0) {
            [AlertWorkerObjc actionSheetWithTitle:@"Найдены контрагенты" message:nil sourceView:self.checkPhoneButton buttons:buttons isLastButtonCancel:NO permittedArrowDirections:UIPopoverArrowDirectionRight tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
                
            }];
        }
    }
    
    self.isLoadingPartners = NO;
    [self.checkPhoneButton setNeedsUpdateConfiguration];
}

#pragma mark - NewCustomerDataPickerViewControllerDelegate
- (void)userDidPickCustomerData:(NSDictionary *)data {
    self.contactData[@"role"] = data;
    self.lblContactRole.text = data[@"name"];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.txtNameField) {
        self.contactData[@"name"] = textField.text;
    }
    
    if (textField == self.txtPhoneField && [self.txtPhoneField.phoneNumber hasPrefix:@"7"]) {
        self.contactData[@"phone"] = [self.txtPhoneField.phoneNumber stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"8"];
    }
    
    if (textField == self.txtMailField && [textField.text stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0) {
        if ([ASPFunctions isEmailValid:textField.text]) {
            self.contactData[@"mail"] = textField.text;
        } else {
            [AlertWorkerObjc alertWithTitle:@"Некорректный email"];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
