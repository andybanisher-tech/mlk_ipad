//
//  CustListItem.m
//  MLK
//

#import "CustListItem.h"

@implementation CustListItem

- (BOOL)isEqual:(id)object {
    if (self == object) { return YES; }
    if (![object isKindOfClass:CustListItem.class]) { return NO; }
    return [self.uid isEqualToString:((CustListItem *)object).uid];
}

- (NSUInteger)hash {
    return self.uid.hash;
}

- (id)copyWithZone:(NSZone *)zone {
    CustListItem *copy = [CustListItem new];
    copy.uid = self.uid;
    copy.custAccount = self.custAccount;
    copy.name = self.name;
    copy.address = self.address;
    copy.sendStatus = self.sendStatus;
    copy.pdz = self.pdz;
    return copy;
}

@end
