//
//  DocumentType.m
//  MLK
//
//  Created by Alexandr Polienko on 07.11.2025.
//

#import "DocumentType.h"

@interface DocumentType ()

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSInteger docID;

@end

@implementation DocumentType

- (instancetype)initWithName:(NSString *)name docID:(NSInteger)docID {
    self = [super init];
    if (self) {
        self.name = name;
        self.docID = docID;
    }
    return self;
}

@end
