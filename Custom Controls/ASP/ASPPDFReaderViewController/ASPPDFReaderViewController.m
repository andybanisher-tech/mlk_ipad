//
//  ASPPDFReaderViewController.m
//  MLK
//
//  Created by Alexandr Polienko on 11.11.2023.
//

#import "ASPPDFReaderViewController.h"
#import <PDFKit/PDFKit.h>

#import "GeneratedAssetSymbols.h"

@interface ASPPDFReaderViewController ()

@property (nonatomic, copy) NSData *pdfData;
@property (nonatomic, copy) NSString *pdfPath;

@property (nonatomic, strong) PDFView *pdfView;

@end

@implementation ASPPDFReaderViewController

- (instancetype)initWithPdfData:(NSData *)pdfData {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.pdfData = pdfData;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (instancetype)initWithPdfPath:(NSString *)pdfPath {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.pdfPath = pdfPath;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - Button Actions
- (void)setupUI {
    self.view.backgroundColor = UIColor.clearColor;
    
    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ACImageNameGrayBackground]];
    bgImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bgImageView];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.view.bounds];
    [toolbar sizeToFit];
    toolbar.clipsToBounds = YES;
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonTapped:)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
    toolbar.items = @[shareButton, flexSpace, doneButton];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:toolbar];

    UIView *bottomLineView = [[UIView alloc] initWithFrame:toolbar.frame];
    bottomLineView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    bottomLineView.translatesAutoresizingMaskIntoConstraints = NO;
    [toolbar addSubview:bottomLineView];

    self.pdfView = [[PDFView alloc] initWithFrame:self.view.bounds];
    self.pdfView.backgroundColor = UIColor.clearColor;
    self.pdfView.displayDirection = kPDFDisplayDirectionHorizontal;
    [self.pdfView usePageViewController:YES withViewOptions:nil];
    [self.pdfView zoomIn:self];
    self.pdfView.minScaleFactor = 0.9;
    self.pdfView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pdfView];
    
    [NSLayoutConstraint activateConstraints:@[
        //BGImageView
        [bgImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bgImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [bgImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bgImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        //ToolBar
        [toolbar.heightAnchor constraintEqualToConstant:toolbar.bounds.size.height],
        [toolbar.leadingAnchor constraintEqualToAnchor:bgImageView.leadingAnchor],
        [toolbar.topAnchor constraintEqualToAnchor:bgImageView.topAnchor],
        [toolbar.trailingAnchor constraintEqualToAnchor:bgImageView.trailingAnchor],
        
        //BottomLineView
        [bottomLineView.heightAnchor constraintEqualToConstant:0.5],
        [bottomLineView.leadingAnchor constraintEqualToAnchor:bgImageView.leadingAnchor],
        [bottomLineView.trailingAnchor constraintEqualToAnchor:bgImageView.trailingAnchor],
        [bottomLineView.bottomAnchor constraintEqualToAnchor:toolbar.bottomAnchor],
        
        //PDFView
        [self.pdfView.leadingAnchor constraintEqualToAnchor:bgImageView.leadingAnchor],
        [self.pdfView.topAnchor constraintEqualToAnchor:toolbar.bottomAnchor],
        [self.pdfView.trailingAnchor constraintEqualToAnchor:bgImageView.trailingAnchor],
        [self.pdfView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]]
    ];

    [self prepareToDisplayPDF];
}

- (void)prepareToDisplayPDF {
    PDFDocument *document;
    if (self.pdfData) {
        document = [[PDFDocument alloc] initWithData:self.pdfData];
    } else if (self.pdfPath) {
        if ([NSFileManager.defaultManager fileExistsAtPath:self.pdfPath]) {
            document = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:self.pdfPath]];
        }
    }
    
    if (document) {
        [self displayPDF:document];
    } else {
        [AlertWorkerObjc alertWithTitle:@"Ошибка!" message:@"Невозможно открыть PDF" acceptMessage:@"OK" acceptBlock:^{
            [self doneButtonTapped];
        }];
    }
}

- (void)displayPDF:(PDFDocument *)document {
    self.pdfView.document = document;
    self.pdfView.autoScales = YES;
}

#pragma mark - Button Actions
- (void)shareButtonTapped:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.pdfData] applicationActivities:nil];
    activityVC.popoverPresentationController.barButtonItem = sender;
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)doneButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
