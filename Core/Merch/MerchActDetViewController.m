//
//  MerchActDetViewController.m
//  MLK
//
//  Created by Rustem Galyamov on 15.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MerchActDetViewController.h"
#import "MerchActionViewController.h"
#import "ActionFileRequest.h"
#import "PrepareSales.h"

#import "ASPPDFReaderViewController.h"

@implementation MerchActDetViewController

@synthesize isViewPushed, actionBtn, getFile, addSalesLine;
@synthesize brand, setId, name, price, availQty, type, amountSum, amountQty, setDescr, actionId, brandId;
@synthesize brandTxt, setIdTxt, nameTxt, priceTxt, availQtyTxt, typeTxt, amountSumTxt, amountQtyTxt, setDescrTxt, salesQtyTxt;
@synthesize custAccount;
@synthesize delegate;
@synthesize labelQty, labelSum;
@synthesize fromMerch;

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
    // Do any additional setup after loading the view from its nib.
    if (isViewPushed == NO) {
		
		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStyleDone target:self action:@selector(cancel_Clicked:)];
        
        barButton.tintColor = [UIColor colorWithRed:100.0/255.0 green:149.0/255.0 blue:237.0/255.0 alpha:1.0];
        
        self.navigationItem.rightBarButtonItem = barButton;
	}
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
    self.title = name;
    
    brandTxt.text     = brand;
    setIdTxt.text     = setId;
    nameTxt.text      = name;
    priceTxt.text     = price;
    availQtyTxt.text  = availQty;
    
    if ([type isEqualToString:@"1"]) {
        typeTxt.text = @"Акция на запуск";
    } else if ([type isEqualToString:@"2"]) {
        typeTxt.text = @"Акция на сумму/кол-во";
    } else if ([type isEqualToString:@"3"]) {
        typeTxt.text = @"Комбинированная акция";
    }

    amountSumTxt.text = amountSum;
    amountQtyTxt.text = amountQty;
    setDescrTxt.text  = setDescr;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf", actionId]];
    
    BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:filePath];
    
    if (fileExists == YES) {
        actionBtn.highlighted = NO;
        actionBtn.enabled = YES;
    } else {
        actionBtn.highlighted = YES;
        actionBtn.enabled = NO;
    }
    
    salesQtyTxt.enabled  = !fromMerch;
    addSalesLine.enabled = !fromMerch;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([type isEqualToString:@"1"]) {
        if ([amountQtyTxt.text doubleValue] > 0) {
            amountQtyTxt.hidden = NO;
            labelQty.hidden     = NO;
            amountSumTxt.hidden = YES;
            labelSum.hidden     = YES;
        }
        else 
        {
            amountQtyTxt.hidden = YES;
            labelQty.hidden     = YES;
            amountSumTxt.hidden = YES;
            labelSum.hidden     = YES;
        }
    } else if ([type isEqualToString:@"2"]) {
        if ([amountQtyTxt.text doubleValue] > 0) {
            amountQtyTxt.hidden = NO;
            labelQty.hidden     = NO;
        }
        else 
        {
            amountQtyTxt.hidden = YES;
            labelQty.hidden     = YES;
        }
        
        if ([amountSumTxt.text doubleValue] > 0) {
            amountSumTxt.hidden = NO;
            labelSum.hidden     = NO;
        }
        else 
        {
            amountSumTxt.hidden = YES;
            labelSum.hidden     = YES;
        }
    } else if ([type isEqualToString:@"3"]) {
        if ([amountQtyTxt.text doubleValue] > 0) {
            amountQtyTxt.hidden = NO;
            labelQty.hidden     = NO;
        }
        else 
        {
            amountQtyTxt.hidden = YES;
            labelQty.hidden     = YES;
        }
        
        if ([amountSumTxt.text doubleValue] > 0) {
            amountSumTxt.hidden = NO;
            labelSum.hidden     = NO;
        }
        else 
        {
            amountSumTxt.hidden = YES;
            labelSum.hidden     = YES;
        }
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)cancel_Clicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    actionId = nil;
}

- (void)openAction {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = searchPaths.firstObject;
    NSString *pdfPath = [documentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf", actionId]];
    ASPPDFReaderViewController *pdfReaderVC = [[ASPPDFReaderViewController alloc] initWithPdfPath:pdfPath];
    [self presentViewController:pdfReaderVC animated:YES completion:nil];
}

-(IBAction)getActionFile {
    actionFileRequest = [ActionFileRequest new];
    actionFileRequest.actionId = actionId;
    [actionFileRequest fileReq];
    
    //[actionFileRequest release];
    //actionFileRequest = nil;
    
    [self createTimer];
}

-(NSTimer*)createTimer {    
    return [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(updateBtn) userInfo:nil repeats:YES];
}

- (void)updateBtn {
    if (actionId != nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
        NSString *documentsDirectory = [paths objectAtIndex:0];
    
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf", actionId]];
    
        BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:filePath];
    
        if (fileExists == YES) {
            actionBtn.highlighted = NO;
            actionBtn.enabled = YES;
        } else {
            actionBtn.highlighted = YES;
            actionBtn.enabled = NO;
        }
    }
}
    

- (IBAction)prepareSalesLine {
    if (([salesQtyTxt.text doubleValue]>0) & [type isEqualToString:@"3"]) {
        if ([salesQtyTxt.text doubleValue] <= [availQty doubleValue]) {
            PrepareSales    *prepareSales = [PrepareSales new];
        
            prepareSales.actionType     = type;
            prepareSales.actionId       = actionId;
            prepareSales.brandForItems  = brandId;
        
            [prepareSales createTmpSalesLine:custAccount itemId:setId qty:salesQtyTxt.text price:price lineAmount:[NSString stringWithFormat:@"%0.2lf", ([salesQtyTxt.text doubleValue]*[price doubleValue])]];
        
            prepareSales.actionType     = @"2";
            prepareSales.actionId       = actionId;
            prepareSales.brandForItems  = brandId;
        
            [prepareSales createTmpSalesLine:custAccount itemId:@"null" qty:[NSString stringWithFormat:@"%0.2lf", ([salesQtyTxt.text doubleValue]*[amountQtyTxt.text doubleValue])] price:@"0.00" lineAmount:[NSString stringWithFormat:@"%0.2lf", ([salesQtyTxt.text doubleValue]*[amountSumTxt.text doubleValue])]];

            [AlertWorkerObjc alertWithTitle:@"Информация" message:@"Акция добавлена в заказ"];
            
            [self closeView:YES];
        
            [self dismissViewControllerAnimated:NO completion:nil];
        
            actionId = nil;
        }
        else 
        {
            [AlertWorkerObjc alertWithTitle:@"Ошибка" message:@"Вы пытаетесь заказать больше, чем доступно"];

            salesQtyTxt.text = availQtyTxt.text;
        }
    } else if (([salesQtyTxt.text doubleValue]>0) & [type isEqualToString:@"2"]) {
        PrepareSales    *prepareSales = [PrepareSales new];
            
        prepareSales.actionType     = type;
        prepareSales.actionId       = actionId;
        prepareSales.brandForItems  = brandId;
            
        [prepareSales createTmpSalesLine:custAccount itemId:@"null" qty:[NSString stringWithFormat:@"%0.2lf", ([salesQtyTxt.text doubleValue]*[amountQtyTxt.text doubleValue])] price:@"0.00" lineAmount:[NSString stringWithFormat:@"%0.2lf", ([salesQtyTxt.text doubleValue]*[amountSumTxt.text doubleValue])]];

        [AlertWorkerObjc alertWithTitle:@"Информация" message:@"Акция добавлена в заказ"];
        
        [self closeView:YES];
            
        [self dismissViewControllerAnimated:NO completion:nil];
            
        actionId = nil;
        
    } else if ([salesQtyTxt.text doubleValue]>0) {
        if ([salesQtyTxt.text doubleValue] <= [availQty doubleValue]) {
            PrepareSales    *prepareSales = [PrepareSales new];
    
            prepareSales.actionType     = type;
            prepareSales.actionId       = actionId;
            prepareSales.brandForItems  = brandId;
        
            [prepareSales createTmpSalesLine:custAccount itemId:setId qty:salesQtyTxt.text price:price lineAmount:[NSString stringWithFormat:@"%0.2lf", ([salesQtyTxt.text doubleValue]*[price doubleValue])]];

            [AlertWorkerObjc alertWithTitle:@"Информация" message:@"Акция добавлена в заказ"];

            [self closeView:YES];
        
            [self dismissViewControllerAnimated:NO completion:nil];
        
            actionId = nil;
        } else {
            [AlertWorkerObjc alertWithTitle:@"Ошибка" message:@"Вы пытаетесь заказать больше, чем доступно"];

            salesQtyTxt.text = availQtyTxt.text;
        }
    } else {
        [AlertWorkerObjc alertWithTitle:@"Ошибка" message:@"Необходимо указать кол-во для заказа!"];
    }
}

- (void)closeView:(BOOL)closeAll {
    [self.delegate closeView:closeAll];
}

@end
