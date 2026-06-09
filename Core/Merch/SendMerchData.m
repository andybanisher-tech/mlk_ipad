//
//  SendMerchData.m
//  MLK
//
//  Created by Rustem Galyamov on 28.06.12.
//  Copyright (c) 2012 Aimen Ltd. All rights reserved.
//

#import "SendMerchData.h"
#import "XMLWriter.h"
#import "PutGroupPropertiesValueRequest.h"
#import "PutTTPropertiesValueRequest.h"
#import "PutCommentsRequest.h"
#import "PutPhotosRequest.h" 
#import "Base64Class.h"

static sqlite3 *database = nil;

@implementation SendMerchData

@synthesize custAccount;

- (void)sendGroupPropertiesValue {
    [SVProgressHUD showProgress:0.0 status:@"Синхронизация\nПожалуйста, подождите..."];
    
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select GroupId, BrandId, PropertyId, Value, Image, ElementListId from PropertiesValue where Date = ? and CustAccount = ? and (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
            {
                NSData   *imgData       = nil;
                NSString *groupId       = @"null";
                NSString *brandId       = @"null";
                NSString *propertyId    = @"null";
                NSString *value         = @"null";
                NSString *image         = @"null";
                NSString *imageSize     = @"null";
                NSString *elementListId = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    groupId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    brandId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    propertyId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    value  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_blob(selectstmt, 4))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 4) length:sqlite3_column_bytes(selectstmt, 4)];
                
                    imageSize = [NSString stringWithFormat:@"%lu", (unsigned long)[imgData length]];
                
                    image = [Base64Class encode:imgData];
                }
                
                if (sqlite3_column_text(selectstmt, 5))
                    elementListId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:Period"];
                [xmlWriter writeCharacters:strDate];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GroupID"];
                [xmlWriter writeCharacters:groupId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:BrandID"];
                [xmlWriter writeCharacters:brandId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyID"];
                [xmlWriter writeCharacters:propertyId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValue"];
                [xmlWriter writeCharacters:value];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValueID"];
                [xmlWriter writeCharacters:elementListId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Image"];
                [xmlWriter writeCharacters:image];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Size"];
                [xmlWriter writeCharacters:imageSize];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    }
	else
	{
		sqlite3_close(database);
	}
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];

    putGroupPropertiesValue = [PutGroupPropertiesValueRequest new];
    putGroupPropertiesValue.custAccount = custAccount;
    [putGroupPropertiesValue sendMsg:xml];
}

- (void)sendTTPropertiesValue {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CreatedDateTime, PropertyId, Value, Image, ttId, ElementListId from TTPropertiesValue where Date = ? and CustAccount = ? and (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
            {
                NSData   *imgData       = nil;
                NSString *date          = @"null";
                NSString *propertyId    = @"null";
                NSString *value         = @"null";
                NSString *image         = @"null";
                NSString *ttid          = @"null";
                NSString *imageSize     = @"null";
                NSString *elementListId = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    propertyId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    value  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_blob(selectstmt, 3))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 3) length:sqlite3_column_bytes(selectstmt, 3)];
                    
                    imageSize = [NSString stringWithFormat:@"%lu", (unsigned long)[imgData length]];
                    
                    image = [Base64Class encode:imgData];
                }
                
                if (sqlite3_column_text(selectstmt, 4))
                    ttid  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                if (sqlite3_column_text(selectstmt, 5))
                    elementListId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 5)];

                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:Period"];
                [xmlWriter writeCharacters:date];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:TTID"];
                [xmlWriter writeCharacters:ttid];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyID"];
                [xmlWriter writeCharacters:propertyId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValue"];
                [xmlWriter writeCharacters:value];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:PropertyValueID"];
                [xmlWriter writeCharacters:elementListId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Image"];
                [xmlWriter writeCharacters:image];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Size"];
                [xmlWriter writeCharacters:imageSize];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    }
	else
	{
		sqlite3_close(database);
	}
    // get the resulting XML string
    
    NSString* xml = [xmlWriter toString];
    //[activityAlert setNeedsDisplay];
	//[_activity stopAnimating];
    
    putTTPropertiesValue = [PutTTPropertiesValueRequest new];
    putTTPropertiesValue.custAccount = custAccount;
    [putTTPropertiesValue sendMsg:xml];
    
    [self sendComments];

    //[activityAlert release];

}

- (void)sendComments {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select CustAccount, Date, CommentType, Description, UserId from CustComment where Date = ? and CustAccount = ? and (SendStatus = 'Error' or SendStatus = 'New') and CommentType == 'merch'";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
            {
                NSString *date  = @"null";
                NSString *type  = @"null";
                NSString *value = @"null";
                NSString *user  = @"null";        
                
                if (sqlite3_column_text(selectstmt, 1))
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_text(selectstmt, 2))
                    type  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 2)];
                
                if (sqlite3_column_text(selectstmt, 3))
                    value  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 3)];
                
                if (sqlite3_column_text(selectstmt, 4))
                    user  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 4)];
                
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CommentDate"];
                [xmlWriter writeCharacters:date];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:EmployeeID"];
                [xmlWriter writeCharacters:user];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CommentType"];
                [xmlWriter writeCharacters:type];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Value"];
                [xmlWriter writeCharacters:value];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:ForDelete"];
                [xmlWriter writeCharacters:@"0"];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:CommentId"];
                [xmlWriter writeCharacters:@""];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    }
	else
	{
		sqlite3_close(database);
	}
    // get the resulting XML string
    
    //[activityAlert setNeedsDisplay];
	//[_activity stopAnimating];
    
    //putComments = [PutComments new];
    //putComments.activityAlert = activityAlert;
    //[putComments sendMsg:xml];
    
    [self sendGroupPhotos];

    //[activityAlert release];
}

- (void)sendGroupPhotos {
    NSDateFormatter *dateFormatter  = [[NSDateFormatter alloc] init];
    NSDate          *date           = NSDate.date;
    
    [dateFormatter setDateFormat:dateFormat_dd_MM_YYYY];
    
    NSString *strDate = [dateFormatter stringFromDate:date];
    
    XMLWriter* xmlWriter = [[XMLWriter alloc] init];
    
    if (sqlite3_open(SQLWorker.dbPath.UTF8String, &database) == SQLITE_OK) {
        sqlite3_stmt *selectstmt;
        
        const char *sql = "select Date, GroupId, Image from GroupImage where Date = ? and CustAccount = ? and (SendStatus = 'Error' or SendStatus = 'New')";
        
        if (sqlite3_prepare_v2(database, sql, -1, &selectstmt, NULL) == SQLITE_OK) 
		{
			sqlite3_bind_text(selectstmt, 1, [strDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(selectstmt, 2, [custAccount UTF8String], -1, SQLITE_TRANSIENT);
            
            while (sqlite3_step(selectstmt) == SQLITE_ROW) 
            {
                NSData   *imgData       = nil;
                NSString *date          = @"null";
                NSString *groupId       = @"null";
                NSString *image         = @"null";
                
                if (sqlite3_column_text(selectstmt, 0))
                    date  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 0)];
                
                if (sqlite3_column_text(selectstmt, 1))
                    groupId  = [NSString stringWithUTF8String:(char *)sqlite3_column_text(selectstmt, 1)];
                
                if (sqlite3_column_blob(selectstmt, 2))
                {
                    imgData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectstmt, 2) length:sqlite3_column_bytes(selectstmt, 2)];
                    
                    image = [Base64Class encode:imgData];
                }
                
                [xmlWriter writeStartElement:@"sam:Value"];
                
                [xmlWriter writeStartElement:@"sam:CustomerID"];
                [xmlWriter writeCharacters:custAccount];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:GroupID"];
                [xmlWriter writeCharacters:groupId];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Period"];
                [xmlWriter writeCharacters:date];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeStartElement:@"sam:Image"];
                [xmlWriter writeCharacters:image];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
            }
        }
        sqlite3_finalize(selectstmt);
        sqlite3_close(database);
    }
	else
	{
		sqlite3_close(database);
	}
    
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    
    //[activityAlert setNeedsDisplay];
	//[_activity stopAnimating];
    
    putGroupPhotos = [PutPhotosRequest new];
    putGroupPhotos.custAccount = custAccount;
    [putGroupPhotos sendMsg:xml];
    //[activityAlert release];
}

@end
