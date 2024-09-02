//
//  IMessageIterator.h
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Conversation.h"

//由近到远遍历消息
@protocol IConversationIterator
-(Conversation*)next;
@end
