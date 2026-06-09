//
//  GlobalSettingsView.m
//  MLK
//
//  Created by Rustem Galyamov on 15.09.11.
//  Copyright (c) 2011 Aimen Ltd. All rights reserved.
//

#import "GlobalSettingsView.h"
#import "RWBorderedButton.h"

#import "GeneratedAssetSymbols.h"

NSString *const kAdminPass = @"2020";

@implementation GlobalSettingsView{
    UIButton *_btnLock;
}

@synthesize isViewPushed;
@synthesize udidLabel;
@synthesize tfUsername, tfUserpass, tfEmple;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //NavBar Setup
    self.navigationItem.title = @"Информация";
    [ASPFunctions setupNavigationController:self.navigationController backgroundColor:[UIColor colorNamed:ACColorNameGrayNavBarBackground] titleColor:UIColor.whiteColor tintColor:UIColor.whiteColor];

    _btnLock = [UIButton new];
    [_btnLock setImage:[UIImage imageNamed:ACImageNameLock] forState:UIControlStateNormal];
    [_btnLock addTarget:self action:@selector(btnLockTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:_btnLock];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    if (!isViewPushed) {
        RWBorderedButton *closeButton = [RWBorderedButton buttonWithFrame:CGRectMake(0,0,80,30) title:@"Закрыть"];
        [closeButton addTarget:self
                        action:@selector(cancel_Clicked:)
              forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];

        self.navigationItem.rightBarButtonItem = barButton;
        
    }
    
    self.btnServerAddress.enabled = NO;
    self.btnServerAddress.titleLabel.numberOfLines = 2;
    self.btnServerAddress.titleLabel.textAlignment = NSTextAlignmentLeft;

    udidLabel.text = [NSString stringWithFormat:@"Версия %@ (%@)", [[NSBundle.mainBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[NSBundle.mainBundle infoDictionary] objectForKey:@"CFBundleVersion"]];//[[UIDevice currentDevice] uniqueIdentifier];
    
    tfUsername.text = LocalAuthWorker.userName;
    tfUserpass.text = LocalAuthWorker.userPass;
    [self.btnServerAddress setTitle:APIWorker.sharedInstance.srvAddressInputURL.absoluteString forState:UIControlStateNormal];
    tfEmple.text = LocalAuthWorker.emple;
}

- (IBAction)userFieldDoneEditing:(id)sender {
    [PersistenceWorker save:tfUsername.text key:@"userName"];
}

- (IBAction)passFieldDoneEditing:(id)sender {
    [PersistenceWorker save:tfUserpass.text key:@"userPass"];
}

- (IBAction)btnServerAddressTapped:(UIButton *)sender {
    NSMutableArray *buttons = APIWorker.sharedInstance.serverAddresses.mutableCopy;
    [buttons addObject:@"Отмена"];
    
    [AlertWorkerObjc actionSheetWithTitle:@"Выберите сервер" message:nil sourceView:sender buttons:buttons tapBlock:^(UIAlertAction * _Nonnull action, NSInteger index) {
        if (index < buttons.count - 1) {
            [PersistenceWorker save:action.title key:@"serverAddress"];
            [APIWorker.sharedInstance updateServerAddresses];
            
            [self.btnServerAddress setTitle:action.title forState:UIControlStateNormal];
        }
    }];
}

-(IBAction)empleFieldDoneEditing:(id)sender {
    [PersistenceWorker save:tfEmple.text key:@"emple"];
}

- (void)btnLockTapped:(id)sender {
    if (!self.btnServerAddress.enabled) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Введите пароль" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Пароль";
        }];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ок" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if ([alertVC.textFields.firstObject.text isEqualToString:kAdminPass]) {
                self.btnServerAddress.enabled = YES;
                [self->_btnLock setImage:[UIImage imageNamed:ACImageNameUnlock] forState:UIControlStateNormal];
            } else {
                [AlertWorkerObjc alertWithTitle:@"Неверный пароль!"];
            }
        }];
        [alertVC addAction:okAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:cancelAction];
        
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
