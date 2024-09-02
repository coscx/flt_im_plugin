#import "SQLPeerMessageDB.h"
#import "NSString+JSMessagesView.h"

@interface SQLPeerMessageIterator : NSObject<IMessageIterator>

-(SQLPeerMessageIterator*)initWithDB:(FMDatabaseQueue*)db peer:(int64_t)peer secret:(BOOL)secret;

-(SQLPeerMessageIterator*)initWithDB:(FMDatabaseQueue*)db peer:(int64_t)peer position:(int64_t)msgID secret:(BOOL)secret;

@property(nonatomic, strong) FMResultSet *rs;
@end

@implementation SQLPeerMessageIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

-(SQLPeerMessageIterator*)initWithDB:(FMDatabaseQueue*)db peer:(int64_t)peer secret:(BOOL)secret {
    
    self = [super init];
    if (self) {
        [db inDatabase:^(FMDatabase *db) {
            int s = secret ? 1 : 0;
            NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, content FROM peer_message WHERE peer = ? AND secret = ? ORDER BY id DESC";
            self.rs = [db executeQuery:sql, @(peer), @(s)];
        }];
    }
    return self;
}

-(SQLPeerMessageIterator*)initWithDB:(FMDatabaseQueue*)db peer:(int64_t)peer position:(int64_t)msgID secret:(BOOL)secret {
    
    self = [super init];
    __block BOOL secrets = secret;
    if (self) {
        [db inDatabase:^(FMDatabase *db) {
            int s = secrets ? 1 : 0;
            NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, content FROM peer_message WHERE peer = ? AND secret = ? AND id < ? ORDER BY id DESC";
            self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID)];
        }];
    }
    return self;
 
}

-(SQLPeerMessageIterator*)initWithDB:(FMDatabaseQueue*)db peer:(int64_t)peer middle:(int64_t)msgID secret:(BOOL)secret {
    
    self = [super init];
    if (self) {
        [db inDatabase:^(FMDatabase *db) {
            int s = secret ? 1 : 0;
            NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, content FROM peer_message WHERE peer = ? AND secret = ? AND id > ? AND id < ? ORDER BY id DESC";
            self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID-10), @(msgID+10)];
        }];
    }
    return self;
}

//上拉刷新
-(SQLPeerMessageIterator*)initWithDB:(FMDatabaseQueue*)db peer:(int64_t)peer last:(int64_t)msgID secret:(BOOL)secret {
    
    self = [super init];
    if (self) {
        [db inDatabase:^(FMDatabase *db) {
            int s = secret ? 1 : 0;
            NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, content FROM peer_message WHERE peer = ? AND secret = ? AND id>? ORDER BY id";
            self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID)];
        }];
    }
    return self;

}

-(IMessage*)next {
    BOOL r = [self.rs next];
    if (!r) {
        return nil;
    }
    

 
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = [self.rs longLongIntForColumn:@"sender"];
    msg.receiver = [self.rs longLongIntForColumn:@"receiver"];
    msg.timestamp = [self.rs intForColumn:@"timestamp"];
    msg.flags = [self.rs intForColumn:@"flags"];
    msg.secret = [self.rs intForColumn:@"secret"] == 1;
    msg.rawContent = [self.rs stringForColumn:@"content"];
    msg.msgId = [self.rs intForColumn:@"id"];
    return msg;
}

@end



@implementation SQLPeerMessageDB


-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid{
    
    __block BOOL isSuccess = NO;
    [self.db inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
        @try {
            
            int secret = self.secret ? 1 : 0;
            NSString *uuid = msg.uuid ? msg.uuid : nil;
            isSuccess = [db executeUpdate:@"INSERT INTO peer_message (peer, sender, receiver, timestamp, secret, flags, uuid, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                      @(uid), @(msg.sender), @(msg.receiver), @(msg.timestamp), @(secret), @(msg.flags), uuid, msg.rawContent];
          
            int64_t rowID = [db lastInsertRowId];
            msg.msgId = rowID;
            
            if (msg.textContent) {
                NSString *text = [msg.textContent.text tokenizer];
                [db executeUpdate:@"INSERT INTO peer_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
            }
            
           
            
        } @catch (NSException *exception) {
            NSLog(@"error = %@", [exception reason]);
            *rollback = YES;
        } @finally {
            isSuccess = TRUE;
            *rollback = NO;
            
        }
        
    }];
    return  isSuccess;
}

-(BOOL)removeMessage:(int64_t)msgLocalID {
    

    __block BOOL isSuccess = NO;
    [self.db inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
        @try {
            
            [db executeUpdate:@"DELETE FROM peer_message WHERE id=?", @(msgLocalID)];
         
            [db executeUpdate:@"DELETE FROM peer_message_fts WHERE rowid=?", @(msgLocalID)];
           
           
            
        } @catch (NSException *exception) {
            NSLog(@"error = %@", [exception reason]);
            *rollback = YES;
        } @finally {
            isSuccess = TRUE;
            *rollback = NO;
            
        }
        
    }];
    return  isSuccess;
 
}

-(BOOL)removeMessageIndex:(int64_t)msgLocalID {
    
    __block BOOL isSuccess = NO;
    [self.db inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
        @try {

            [db executeUpdate:@"DELETE FROM peer_message_fts WHERE rowid=?", @(msgLocalID)];
                  
        } @catch (NSException *exception) {
            NSLog(@"error = %@", [exception reason]);
            *rollback = YES;
        } @finally {
            isSuccess = TRUE;
            *rollback = NO;
            
        }
        
    }];
    return  isSuccess;
    
  
}

-(BOOL)clearConversation:(int64_t)uid {
    
    int secret = self.secret ? 1 : 0;
    __block BOOL isSuccess = NO;
    [self.db inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
        @try {

            [db executeUpdate:@"DELETE FROM peer_message WHERE peer=? AND secret=?", @(uid), @(secret)];
                  
        } @catch (NSException *exception) {
            NSLog(@"error = %@", [exception reason]);
            *rollback = YES;
        } @finally {
            isSuccess = TRUE;
            *rollback = NO;
            
        }
        
    }];
    return  isSuccess;
}

-(BOOL)clear {
    
    __block BOOL isSuccess = NO;
    [self.db inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
        @try {

            [db executeUpdate:@"DELETE FROM peer_message"];
                  
        } @catch (NSException *exception) {
            NSLog(@"error = %@", [exception reason]);
            *rollback = YES;
        } @finally {
            isSuccess = TRUE;
            *rollback = NO;
            
        }
        
    }];
    return  isSuccess;
}

-(BOOL)updateMessageContent:(int64_t)msgLocalID content:(NSString*)content {
    
    
    __block BOOL isSuccess = NO;
    [self.db inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
        @try {

            [db executeUpdate:@"UPDATE peer_message SET content=? WHERE id=?", content, @(msgLocalID)];
                  
        } @catch (NSException *exception) {
            NSLog(@"error = %@", [exception reason]);
            *rollback = YES;
        } @finally {
            isSuccess = TRUE;
            *rollback = NO;
            
        }
        
    }];
    return  isSuccess;
}

-(NSArray*)search:(NSString*)key {
    
    NSMutableArray *array = [NSMutableArray array];
    [self.db inDatabase:^(FMDatabase *db) {
            
        NSString*  keys = [key stringByReplacingOccurrencesOfString:@"'" withString:@"\'"];
        keys = [keys tokenizer];
        NSString *sql = [NSString stringWithFormat:@"SELECT rowid FROM peer_message_fts WHERE peer_message_fts MATCH '%@'", keys];
        
        FMResultSet *rs = [db executeQuery:sql];
        
        while ([rs next]) {
            int64_t msgID = [rs longLongIntForColumn:@"rowid"];
            IMessage *msg = [self getMessage:msgID];
            if (msg) {
                [array addObject:msg];
            }
        }
        [rs close];
    }];
  
    return array;
}

-(IMessage*)getLastMessage:(int64_t)uid {
    
    __block IMessage *msg = [[IMessage alloc] init];
    [self.db inDatabase:^(FMDatabase *db) {
            
        int s = self.secret ? 1 : 0;
        FMResultSet *rs = [db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, content FROM peer_message WHERE peer = ? AND secret = ? ORDER BY id DESC", @(uid), @(s)];
        if ([rs next]) {
            
            msg.sender = [rs longLongIntForColumn:@"sender"];
            msg.receiver = [rs longLongIntForColumn:@"receiver"];
            msg.timestamp = [rs intForColumn:@"timestamp"];
            msg.flags = [rs intForColumn:@"flags"];
            msg.secret = [rs intForColumn:@"secret"] == 1;
            msg.rawContent = [rs stringForColumn:@"content"];
            msg.msgId = [rs longLongIntForColumn:@"id"];
            
        
        }else{
            msg = nil;
        }
        [rs close];
    }];
    return msg;
}

-(int64_t)getMessageId:(NSString*)uuid {
    
    __block int msgId = 0;
    [self.db inDatabase:^(FMDatabase *db) {
            
        FMResultSet *rs = [db executeQuery:@"SELECT id FROM peer_message WHERE uuid=?", uuid];
        if ([rs next]) {
            msgId = (int)[rs longLongIntForColumn:@"id"];        
        }
        [rs close];
    }];
    return msgId;

}

-(IMessage*)getMessage:(int64_t)msgID {
    
    __block IMessage *msg = [[IMessage alloc] init];
    [self.db inDatabase:^(FMDatabase *db) {
            
        FMResultSet *rs = [db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, content FROM peer_message WHERE id= ?", @(msgID)];
        if ([rs next]) {
    
            msg.sender = [rs longLongIntForColumn:@"sender"];
            msg.receiver = [rs longLongIntForColumn:@"receiver"];
            msg.timestamp = [rs intForColumn:@"timestamp"];
            msg.flags = [rs intForColumn:@"flags"];
            msg.secret = [rs intForColumn:@"secret"] == 1;
            msg.rawContent = [rs stringForColumn:@"content"];
            msg.msgId = [rs intForColumn:@"id"];
           
        }else{
            msg = nil;
        }
        [rs close];
    }];
        
    return msg;

}

-(int)acknowledgeMessage:(int64_t)msgLocalID{
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

-(int)markMessageFailure:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
}

-(int)markMesageListened:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_LISTENED];
}
-(int)markMessageReaded:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_READED];
}
-(int)addFlag:(int64_t)msgLocalID flag:(int)f {
    
    __block BOOL isSuccess = 0;

    [self.db inDatabase:^(FMDatabase *db) {
            
        FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE id=?", @(msgLocalID)];

         if ([rs next]) {
             int flags = [rs intForColumn:@"flags"];
             if ((flags & f) == 0) {
                         flags |= f;
                     [db beginTransaction];

                              @try {

                                  [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];

                              } @catch (NSException *exception) {
                                  NSLog(@"error = %@", [exception reason]);
                                 [db rollback];
                              } @finally {
                                  isSuccess = [db changes];


                              }

                        [db commit];

                     }


         }

         [rs close];
    }];

    return isSuccess;
}


-(BOOL)eraseMessageFailure:(int64_t)msgLocalID {

       __block BOOL isSuccess = NO;

        [self.db inDatabase:^(FMDatabase *db) {

            FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE id=?", @(msgLocalID)];

             if ([rs next]) {
                 int flags = [rs intForColumn:@"flags"];

                        int f = MESSAGE_FLAG_FAILURE;
                        flags &= ~f;

                 [db beginTransaction];

                     @try {

                         [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];

                     } @catch (NSException *exception) {
                         NSLog(@"error = %@", [exception reason]);
                        [db rollback];
                     } @finally {
                         isSuccess = TRUE;


                     }

               [db commit];
             }

             [rs close];
        }];

        return isSuccess;
    
}

-(BOOL)updateFlags:(int64_t)msgLocalID flags:(int)flags {


    __block BOOL isSuccess = NO;
    [self.db inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
        @try {

            [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
                  
        } @catch (NSException *exception) {
            NSLog(@"error = %@", [exception reason]);
            *rollback = YES;
        } @finally {
            isSuccess = TRUE;
            *rollback = NO;
            
        }
        
    }];
    return  isSuccess;
 
}


-(id<IMessageIterator>)newMessageIterator:(int64_t)uid {
    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid secret:self.secret];
}

-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid messageID:(int64_t)lastMsgID {
    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid position:lastMsgID secret:self.secret];
}
-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)uid messageID:(int64_t)messageID {
    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid middle:messageID secret:self.secret];
}

-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)uid messageID:(int64_t)messageID {
    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid last:messageID secret:self.secret];
}


@end


