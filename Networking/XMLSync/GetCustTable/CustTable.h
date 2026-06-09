//
//  CustTable.h
//  AiCRM
//
//  Created by Rustem Galyamov on 05.11.10.
//  Copyright 2010 Aimen Ltd. All rights reserved.
//

#import "UIKit/UIKit.h"

@interface CustTable: NSObject {
    
	NSString *CustAccount;	
	NSString *Name;
    NSString *Address;
    NSString *LegalName;
    NSString *Phone;
    NSString *Email;
    NSString *LocationDescription;
    NSString *Note;
    NSString *GPSPoint;
    NSString *FactAddress;
    NSString *INN;
    NSString *KPP;
    NSString *CustType;
    NSString *City;
    NSString *State;
    NSString *CustKey;
    NSString *TTID;
    NSString *TTName;
    NSString *LastVisitDate;
    NSString *tenProp;
    NSString *PDZAmount;
    NSString *BankName;
    NSString *BankAccount;
    NSString *Property6;
    NSString *Property6Name;
}

@property (nonatomic, retain) NSString *CustAccount;
@property (nonatomic, retain) NSString *Name;
@property (nonatomic, retain) NSString *Address;
@property (nonatomic, retain) NSString *LegalName;
@property (nonatomic, retain) NSString *Phone;
@property (nonatomic, retain) NSString *Email;
@property (nonatomic, retain) NSString *LocationDescription;
@property (nonatomic, retain) NSString *Note;
@property (nonatomic, retain) NSString *GPSPoint;
@property (nonatomic, retain) NSString *FactAddress;
@property (nonatomic, retain) NSString *INN;
@property (nonatomic, retain) NSString *KPP;
@property (nonatomic, retain) NSString *CustType;
@property (nonatomic, retain) NSString *City;
@property (nonatomic, retain) NSString *State;
@property (nonatomic, retain) NSString *CustKey;
@property (nonatomic, retain) NSString *TTID;
@property (nonatomic, retain) NSString *TTName;
@property (nonatomic, retain) NSString *LastVisitDate;
@property (nonatomic, retain) NSString *tenProp;
@property (nonatomic, retain) NSString *PDZAmount;
@property (nonatomic, retain) NSString *BankName;
@property (nonatomic, retain) NSString *BankAccount;
@property (nonatomic, retain) NSString *Property6;
@property (nonatomic, retain) NSString *Property6Name;
@property (nonatomic, copy) NSString *cosmAddressesJSON;

@end

