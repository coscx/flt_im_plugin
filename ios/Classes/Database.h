//
//  Database.h
//  contact
//
//  Created by houxh on 2018/10/8.
//  Copyright © 2018年 momo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <fmdb/FMDB.h>
#import "FMDatabaseQueue.h"
@class FMDatabase;
@interface Database : NSObject
+ (FMDatabaseQueue*)openMessageDB:(NSString*)dbPath;

@end
