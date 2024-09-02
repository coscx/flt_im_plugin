//
//  ConversationDB.h
//  flt_im_plugin
//
//  Created by wan on 2021/1/23.
//

#import "SQLConversionsDB.h"
#import "IConversationDB.h"

@interface ConversationDB : SQLConversionsDB<IConversitionDB>
+(ConversationDB*)instance;
@end
