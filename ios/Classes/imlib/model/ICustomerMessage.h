//
//  ICustomerMessage.h
//  gobelieve
//
//  Created by houxh on 2018/5/26.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"

@interface ICustomerMessage : IMessage
@property(nonatomic) int64_t senderAppID;
@property(nonatomic) int64_t receiverAppID;
//@property(nonatomic) int64_t storeID;
//@property(nonatomic) int64_t sellerID;
//@property(nonatomic) BOOL  isSupport;
@end
