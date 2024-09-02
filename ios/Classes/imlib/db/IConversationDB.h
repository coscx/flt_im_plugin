//
//  IMessageDB.h
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"
#import "IConversationIterator.h"

#define PAGE_COUNT 20
@protocol IConversitionDB<NSObject>
-(id<IConversationIterator>)getConvIterator:(int64_t)ids;
-(BOOL)addConversation:(Conversation*)conv;
-(BOOL)removeConversation:(Conversation*)conv;
-(Conversation*)getConversation:(long long)cid type:(int)type;
-(BOOL)setNewCount:(long long)rowid count: (int)count;
-(BOOL)setState:(int)rowid state:(int)state;
-(BOOL)resetState:(int)state;
-(IMessage*)getMessage:(int64_t)msgID;
-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address;
-(BOOL)saveMessage:(IMessage*)msg;
-(BOOL)removeMessage:(int)msg;
-(BOOL)markMessageFailure:(int)msg;
-(BOOL)markMesageListened:(int)msg;
-(BOOL)eraseMessageFailure:(int)msg;

@end
