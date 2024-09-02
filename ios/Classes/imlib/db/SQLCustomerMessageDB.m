#import "SQLCustomerMessageDB.h"

@interface SQLCustomerMessageIterator : NSObject<IMessageIterator>

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabaseQueue*)db store:(int64_t)store;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabaseQueue*)db store:(int64_t)store position:(int64_t)msgID;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabaseQueue*)db uid:(int64_t)uid appID:(int64_t)appID;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabaseQueue*)db uid:(int64_t)uid appID:(int64_t)appID position:(int64_t)msgID;

@property(nonatomic) FMResultSet *rs;
@end

@implementation SQLCustomerMessageIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabaseQueue*)db store:(int64_t)store {
    self = [super init];
    if (self) {
        [db inDatabase:^(FMDatabase *db) {
            NSString *sql = @"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE store_id = ? ORDER BY id DESC";
            self.rs = [db executeQuery:sql, @(store)];
        }];
    }
    return self;
    
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabaseQueue*)db store:(int64_t)store position:(int64_t)msgID {
    self = [super init];
    if (self) {
        [db inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE store_id = ? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(store), @(msgID)];
        }];
    }
    return self;
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabaseQueue*)db uid:(int64_t)uid appID:(int64_t)appID {
    self = [super init];
    if (self) {
        [db inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE peer_appid = ? AND peer = ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(appID), @(uid)];
        }];
    }
    return self;
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabaseQueue*)db uid:(int64_t)uid appID:(int64_t)appID position:(int64_t)msgID {
    self = [super init];
    if (self) {
        [db inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE peer_appid = ? AND peer = ? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(appID), @(uid),  @(msgID)];
    }];
}
return self;
}


-(IMessage*)next {
    BOOL r = [self.rs next];
    if (r) {
        return [self readMessage:self.rs];
    }
    return nil;
}

-(IMessage*)readMessage:(FMResultSet*)rs {
    IMessage *msg = [[IMessage alloc] init];
    msg.senderAppID = [rs longLongIntForColumn:@"sender_appid"];
    msg.sender = [rs longLongIntForColumn:@"sender"];
    msg.receiverAppID = [rs longLongIntForColumn:@"receiver_appid"];
    msg.receiver = [rs longLongIntForColumn:@"receiver"];
    msg.timestamp = [rs intForColumn:@"timestamp"];
    msg.flags = [rs intForColumn:@"flags"];
    msg.rawContent = [rs stringForColumn:@"content"];
    msg.msgId = [rs longLongIntForColumn:@"id"];
    return msg;
}

@end


@implementation SQLCustomerMessageDB
+(SQLCustomerMessageDB*)instance {
    static SQLCustomerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[SQLCustomerMessageDB alloc] init];
        }
    });
    return m;
}

-(IMessage*)readMessage:(FMResultSet*)rs {
    IMessage *msg = [[IMessage alloc] init];
    msg.senderAppID = [rs longLongIntForColumn:@"sender_appid"];
    msg.sender = [rs longLongIntForColumn:@"sender"];
    msg.receiverAppID = [rs longLongIntForColumn:@"receiver_appid"];
    msg.receiver = [rs longLongIntForColumn:@"receiver"];
    msg.timestamp = [rs intForColumn:@"timestamp"];
    msg.flags = [rs intForColumn:@"flags"];
    msg.rawContent = [rs stringForColumn:@"content"];
    msg.msgId = [rs longLongIntForColumn:@"id"];
    return msg;
}

-(IMessage*)getLastMessage:(int64_t)uid appID:(int64_t)appID {
    __block IMessage *msg = [[IMessage alloc] init];
    [self.db inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE peer= ? AND peer_appid=? ORDER BY id DESC", @(uid), @(appID)];
        if ([rs next]) {
            msg= [self readMessage:rs];
        }
        [rs close];
    }];
    return msg;
}

-(IMessage*)getLastMessage:(int64_t)storeID {
    __block IMessage *msg = [[IMessage alloc] init];
    [self.db inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [db executeQuery:@"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE store_id= ? ORDER BY id DESC", @(storeID)];
    if ([rs next]) {
        msg= [self readMessage:rs];
    }
        [rs close];
    }];
    return msg;
}

-(IMessage*)getMessage:(int64_t)msgID {
    __block IMessage *msg = [[IMessage alloc] init];
    [self.db inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [db executeQuery:@"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE id= ?", @(msgID)];
    if ([rs next]) {
        msg= [self readMessage:rs];
    }
        [rs close];
    }];
    return msg;
}

-(int64_t)getMessageId:(NSString*)uuid {
    __block int64_t msgId = 0;
    [self.db inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id FROM customer_message WHERE uuid= ?", uuid];
        if ([rs next]) {
            msgId = (int)[rs longLongIntForColumn:@"id"];
        }
        [rs close];
    }];
    return msgId;
}
-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)peer appid:(int64_t)peerAppId {
    IMessage *cm = (IMessage*)msg;
    NSString *uuid = cm.uuid ? cm.uuid : nil;
    NSString *sql = @"INSERT INTO customer_message (peer_appid, peer, store_id, sender_appid, sender, receiver_appid, receiver,\
        timestamp, flags, uuid, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {
        BOOL r = [db executeUpdate:sql, @(peerAppId), @(peer), @(cm.content.storeId),
                  @(cm.senderAppID), @(cm.sender), @(cm.receiverAppID),
                  @(cm.receiver), @(cm.timestamp), @(cm.flags), uuid, cm.rawContent];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            msgId= NO;
        }
        msg.msgId = [db lastInsertRowId];
    }];

    return msgId;
}

-(BOOL)removeMessage:(int64_t)msgLocalID {
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {
        BOOL r = [db executeUpdate:@"DELETE FROM customer_message WHERE id=?", @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            msgId= NO;
            return;
        }

        r = [db executeUpdate:@"DELETE FROM customer_message_fts WHERE rowid=?", @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            msgId= NO;
            return;;
        }
    }];

    return msgId;
}

-(BOOL)removeMessageIndex:(int64_t)msgLocalID {
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message_fts WHERE rowid=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        msgId=  NO;
    }
    }];

    return msgId;
}

-(BOOL)clearConversation:(int64_t)uid appID:(int64_t)appID {
    __block bool msgId = YES;
   [self.db inDatabase:^(FMDatabase *db) {
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message WHERE peer=? AND peer_appid=?", @(uid), @(appID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        msgId=  NO;
    }
   }];

   return msgId;
}

-(BOOL)clearConversation:(int64_t)store {
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message WHERE store=?", @(store)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        msgId=  NO;
    }
    }];

    return msgId;
}

-(BOOL)updateMessageContent:(int64_t)msgLocalID content:(NSString*)content {
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {

        BOOL r = [db executeUpdate:@"UPDATE group_message SET content=? WHERE id=?", content, @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            msgId=  NO;
        }

        msgId= [db changes] == 1;
    }];

    return msgId;
}

-(BOOL)clear {
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message"];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        msgId= NO;
    }
    }];

    return msgId;
}

-(BOOL)acknowledgeMessage:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

-(BOOL)markMessageFailure:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_LISTENED];
}

-(BOOL)markMessageReaded:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_READED];
}

-(BOOL)addFlag:(int64_t)msgLocalID flag:(int)f {
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM customer_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        msgId= NO;
        return;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;


        BOOL r = [db executeUpdate:@"UPDATE customer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            msgId= NO;
        }
    }

    [rs close];
    }];

    return msgId;
}


-(BOOL)eraseMessageFailure:(int64_t)msgLocalID {
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM customer_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        msgId= NO;
        return;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];

        int f = MESSAGE_FLAG_FAILURE;
        flags &= ~f;

        BOOL r = [db executeUpdate:@"UPDATE customer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            msgId=  NO;
        }
    }

    [rs close];
    }];

    return msgId;

}


-(BOOL)updateFlags:(int64_t)msgLocalID flags:(int)flags {
    __block bool msgId = YES;
    [self.db inDatabase:^(FMDatabase *db) {

    BOOL r = [db executeUpdate:@"UPDATE customer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        msgId= NO;
    }
    }];

    return msgId;
}


-(id<IMessageIterator>)newMessageIterator:(int64_t)store {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db store:store];
}

-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)store last:(int64_t)lastMsgID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db store:store position:lastMsgID];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db uid:uid appID:appID];
}

-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid appID:(int64_t)appID last:(int64_t)lastMsgID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db uid:uid appID:appID position:lastMsgID];
}

-(id<IMessageIterator>)newBackForwardMessageIterator:(int64_t)uid appID:(int64_t)appID last:(int64_t)lastMsgID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db uid:uid appID:appID position:lastMsgID];
}


-(BOOL)saveMessage:(IMessage*)msg {
    IMessage *cm = (IMessage*)msg;
    return [self insertMessage:msg uid:cm.receiver appid:cm.receiverAppID];
}

- (id<IMessageIterator>)newBackwardMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID {
    return nil;
}


- (id<IMessageIterator>)newMiddleMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID {
    return nil;
}

- (id<IMessageIterator>)newForwardMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID {
    return nil;
}




@end


