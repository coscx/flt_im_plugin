#import "FltImPlugin.h"
#import "IMService.h"
#import "IMHttpAPI.h"
#import "PeerMessageHandler.h"
#import "GroupMessageHandler.h"
#import "CustomerMessageHandler.h"
#import "CustomerMessageDB.h"
#import "CustomerOutbox.h"
#import "GOReachability.h"
#import "ConversationDB.h"
#import "PeerMessageDB.h"
#import "GroupMessageDB.h"
#import "CustomerMessageDB.h"
#import "PeerMessageHandler.h"
#import "GroupMessageHandler.h"
#import "CustomerMessageHandler.h"
#import "SyncKeyHandler.h"
#import "IMessageDB.h"
#import "IConversationDB.h"
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#import "Database.h"
#import <fmdb/FMDB.h>
#import <sqlite3.h>
#import "PeerMessageDB.h"
#import "IMessage.h"
#import "Outbox.h"
#import "GroupOutbox.h"
#import "PeerOutbox.h"
#import "EPeerMessageDB.h"
#import "FileCache.h"
#import "AudioDownloader.h"
#import "UIImage+Resize.h"
#import "NSDate+Format.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <MJExtension/MJExtension.h>

#import "UIImage+Resize.h"
#import "NSDate+Format.h"

#import "SDImageCache.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <AudioToolbox/AudioServices.h>
#import "AVURLAsset+Video.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <SDWebImage/UIImage+MultiFormat.h>
#import "Conversation.h"
// #import "voips/voip/VOIPCommand.h"
// #import "voips/voip/VOIPViewController.h"
// #import "voips/voip/VOIPVideoViewController.h"
// #import "voips/voip/VOIPVoiceViewController.h"

//应用启动时间
static int flt_im_uptime = 0;

@interface FltImPlugin()<PeerMessageObserver,
CustomerMessageObserver,
TCPConnectionObserver,
AudioDownloaderObserver,
OutboxObserver,
FlutterStreamHandler,
SystemMessageObserver,
RTMessageObserver,
GroupMessageObserver>
@property (nonatomic, strong) FlutterEventSink eventSink;

@property(nonatomic) GOReachability *reach;
@property (strong, nonatomic) NSData *deviceToken;
@property(nonatomic) int64_t myUID;
@property(nonatomic) int64_t peerUID;
@property(nonatomic) int64_t appID;
@property (nonatomic) id<IMessageDB> messageDB;
@property (nonatomic) id<IConversitionDB> conversationDB;
@property (nonatomic, assign) NSInteger conversationID;
@property (nonatomic, assign) NSInteger currentUID;
@property (nonatomic) NSMutableDictionary *attachments;
@property(nonatomic) NSMutableArray *channelIDs;
@property (strong , nonatomic) NSMutableArray *conversations;
@end

@implementation FltImPlugin

+(void)load {
    flt_im_uptime = (int)time(NULL);
}

- (instancetype)init {
    if (self = [super init]) {
        self.attachments = [NSMutableDictionary dictionary];
        self.conversations = [NSMutableArray array];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flt_im_plugin"
            binaryMessenger:[registrar messenger]];
    FltImPlugin* instance = [[FltImPlugin alloc] init];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];

    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"flt_im_plugin_event" binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

#pragma mark - FlutterStreamHandler
- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.eventSink = events;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments{
    return nil;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        [self init:call.arguments result:result];
    }
    else if ([@"login" isEqualToString:call.method]) {
        [self login:call.arguments result:result];
    }
    else if ([@"logout" isEqualToString:call.method]) {
        [self logout];
    }
 // else if ([@"voice_call" isEqualToString:call.method]) {
 // [self voice_call:call.arguments result:result];
 // }
 // else if ([@"voice_receive_call" isEqualToString:call.method]) {
 // [self voice_receive_call:call.arguments result:result];
 // }
 // else if ([@"video_call" isEqualToString:call.method]) {
 // [self video_call:call.arguments result:result];
 // }
 // else if ([@"video_receive_call" isEqualToString:call.method]) {
 // [self video_receive_call:call.arguments result:result];
 // }

    else if ([@"createConversion" isEqualToString:call.method]) {
        [self createConversion:call.arguments result:result];
    }
    else if ([@"createGroupConversion" isEqualToString:call.method]) {
        [self createGroupConversion:call.arguments result:result];
    }
    else if ([@"createCustomerConversion" isEqualToString:call.method]) {
        [self createCustomerConversion:call.arguments result:result];
    }
    else if ([@"loadData" isEqualToString:call.method]) {
        [self loadData:call.arguments result: result];
    }
    else if ([@"loadEarlierData" isEqualToString:call.method]) {
        [self loadEarlierData:call.arguments result:result];
    }
    else if ([@"loadLateData" isEqualToString:call.method]) {
        [self loadLateData:call.arguments result:result];
    }
    else if ([@"loadCustomerData" isEqualToString:call.method]) {
        [self loadCustomerData:call.arguments result: result];
    }
    else if ([@"loadCustomerEarlierData" isEqualToString:call.method]) {
        [self loadCustomerEarlierData:call.arguments result:result];
    }
    else if ([@"loadCustomerLateData" isEqualToString:call.method]) {
        [self loadCustomerLateData:call.arguments result:result];
    }
    else if ([@"sendMessage" isEqualToString:call.method]) {
        [self sendMessage:call.arguments result:result];
    }
    else if ([@"sendGroupMessage" isEqualToString:call.method]) {
        [self sendGroupMessage:call.arguments result:result];
    }
    else if ([@"sendFlutterMessage" isEqualToString:call.method]) {
        [self sendFlutterMessage:call.arguments result:result];
    }
    else if ([@"sendFlutterGroupMessage" isEqualToString:call.method]) {
        [self sendFlutterGroupMessage:call.arguments result:result];
    }
    else if ([@"sendFlutterCustomerMessage" isEqualToString:call.method]) {
        [self sendFlutterCustomerMessage:call.arguments result:result];
    }
    else if ([@"getLocalCacheImage" isEqualToString:call.method]) {
        [self getLocalCacheImage:call.arguments result:result];
    }
    else if ([@"getLocalMediaURL" isEqualToString:call.method]) {
        [self getLocalMediaURL:call.arguments result:result];
    }
    else if ([@"getConversations" isEqualToString:call.method]) {
        [self getConversations:call.arguments result:result];
    }
    else if ([@"deleteConversation" isEqualToString:call.method]) {
        [self deleteConversation:call.arguments result:result];
    }
    else if ([@"deletePeerMessage" isEqualToString:call.method]) {
        [self deletePeerMessage:call.arguments result:result];
    }
    else if ([@"clearReadCount" isEqualToString:call.method]) {
        [self clearReadCount:call.arguments result:result];
    }
    else if ([@"clearGroupReadCount" isEqualToString:call.method]) {
        [self clearGroupReadCount:call.arguments result:result];
    }
    else if ([@"clearCustomerReadCount" isEqualToString:call.method]) {
        [self clearCustomerReadCount:call.arguments result:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - api
- (void)deleteConversation:(NSDictionary *)args result:(FlutterResult)result {
    int rowid = [self getIntValueFromArgs:args forKey:@"rowid"];
    Conversation *con = [[ConversationDB instance] getConversation:rowid];
    if(con){
        if(con.type==1){

            if (con) {
                [[ConversationDB instance] removeConversation:con];
                [[PeerMessageDB instance] clearConversation:con.cid];
            }
        }
        if(con.type==2){
            Conversation *con = [[ConversationDB instance] getConversation:rowid];
               if (con) {
                   [[ConversationDB instance] removeConversation:con];
                   [[GroupMessageDB instance] clearConversation:con.cid];
               }
        }
        if(con.type==3){
            int appid = [self getIntValueFromArgs:args forKey:@"appid"];

               if (con) {
                   [[ConversationDB instance] removeConversation:con];
                   [[CustomerMessageDB instance] clearConversation:con.cid appID:appid];
               }
        }
    }

    result([self resultSuccess:@"完成"]);
}

- (void)deletePeerMessage:(NSDictionary *)args result:(FlutterResult)result {
    NSString *uuid = [self getStringValueFromArgs:args forKey:@"id"];
    int64_t id = 0;
    int64_t con_db = [[PeerMessageDB instance] getMessageId:uuid];
    if (con_db) {
        id = con_db;
     } else{

     }

    BOOL  return_result = [[PeerMessageDB instance] removeMessage:id];
    NSString *results  = @"";

        if(return_result){
            results  = @"success";
        }else{
            results  = @"error";
        }

      [self callFlutter:[self resultSuccess:@{
           @"type": @"deletePeerMessageSuccess",
           @"result":results,
           @"id":uuid,
       }]];
}


- (void)clearReadCount:(NSDictionary *)args result:(FlutterResult)result {
    int cid = [self getIntValueFromArgs:args forKey:@"cid"];
    Conversation *con = [[ConversationDB instance] getConversation:cid type:CONVERSATION_PEER];
        if (con) {
            [[ConversationDB instance] setNewCount:con.rowid count:0];
        }

    result([self resultSuccess:@"完成"]);
}
- (void)clearGroupReadCount:(NSDictionary *)args result:(FlutterResult)result {
    int cid = [self getIntValueFromArgs:args forKey:@"cid"];
    Conversation *con = [[ConversationDB instance] getConversation:cid type:CONVERSATION_GROUP];
        if (con) {
            [[ConversationDB instance] setNewCount:con.rowid count:0];
        }

    result([self resultSuccess:@"完成"]);
}
- (void)clearCustomerReadCount:(NSDictionary *)args result:(FlutterResult)result {
    int appid = [self getIntValueFromArgs:args forKey:@"appid"];
    int cid = [self getIntValueFromArgs:args forKey:@"cid"];
    Conversation *con = [[ConversationDB instance] getConversation:cid appid:appid type:CONVERSATION_CUSTOMER_SERVICE];
        if (con) {
            [[ConversationDB instance] setNewCount:con.rowid count:0];
        }

    result([self resultSuccess:@"完成"]);
}
- (void)getConversations:(NSDictionary *)args result:(FlutterResult)result {
    NSMutableArray *convs = [NSMutableArray arrayWithCapacity:30];
    NSMutableArray *convs_new = [NSMutableArray arrayWithCapacity:30];
    convs = [[ConversationDB instance] getConversations:0];

    for(Conversation *con in convs){

                if (con.type == CONVERSATION_PEER) {


                    IMessage *msg = [[PeerMessageDB instance] getLastMessage:con.cid];
                    con.message = msg;
                    [self updateConvNotificationDesc:con];
                    [self updateConversationDetail:con];
                    [convs_new insertObject:con atIndex:0];

                } else if (con.type == CONVERSATION_GROUP) {
                    IMessage *msg = [[GroupMessageDB instance] getLastMessage:con.cid];
                    con.message = msg;
                    [self updateConvNotificationDesc:con];
                    [self updateConversationDetail:con];
                    [convs_new insertObject:con atIndex:0];

                }else if (con.type == CONVERSATION_CUSTOMER_SERVICE) {
                     IMessage *msg = [[CustomerMessageDB instance] getLastMessage:con.cid appID:con.appid];
                     con.message = msg;
                     [self updateConvNotificationDesc:con];
                     [self updateConversationDetail:con];
                     [convs_new insertObject:con atIndex:0];

                 }


    }
//    int count = 0;
//    id<IConversationIterator> iterator;
//    iterator = [[ConversationDB instance] getConvIterator:self.conversationID];
//    Conversation *con = [iterator next];
//    while (con) {
//        if (con.type == CONVERSATION_PEER) {
//
//
//            IMessage *msg = [[PeerMessageDB instance] getLastMessage:con.cid];
//            con.message = msg;
//            [self updateConvNotificationDesc:con];
//            [self updateConversationDetail:con];
//            [convs insertObject:con atIndex:0];
//
//        } else if (con.type == CONVERSATION_GROUP) {
//            IMessage *msg = [[GroupMessageDB instance] getLastMessage:con.cid];
//            con.message = msg;
//            [self updateConvNotificationDesc:con];
//            [self updateConversationDetail:con];
//            [convs insertObject:con atIndex:0];
//
//        }
//
//        con = [iterator next];
//    }
    NSSortDescriptor *timeSD = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];//ascending:YES 代表升序 如果为NO 代表降序
    NSMutableArray *newArray = [[convs sortedArrayUsingDescriptors:@[timeSD]] mutableCopy];
    self.conversations = newArray;
    result([self resultSuccess:[Conversation mj_keyValuesArrayWithObjectArray:self.conversations]]);
}

- (void)getLocalCacheImage:(NSDictionary *)args result:(FlutterResult)result {
    NSString *url = [self getStringValueFromArgs:args forKey:@"url"];

    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:url];
    result([self resultSuccess:[image sd_imageData]]);

}

- (void)getLocalMediaURL:(NSDictionary *)args result:(FlutterResult)result {
    NSString *url = [self getStringValueFromArgs:args forKey:@"url"];
    FileCache *fileCache = [FileCache instance];
    return result([self resultSuccess:[fileCache queryCacheForKey:url]]);
}


- (IMessage *)newOutMessage:(NSDictionary *)args {
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = [self getIntValueFromArgs:args forKey:@"sender"];
    msg.receiver = [self getIntValueFromArgs:args forKey:@"receiver"];
    msg.secret = [self getBoolValueFromArgs:args forKey:@"secret"];
    return msg;
}
- (IMessage *)newCustomerOutMessage:(NSDictionary *)args {
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = [self getIntValueFromArgs:args forKey:@"sender"];
    msg.receiver = [self getIntValueFromArgs:args forKey:@"receiver"];
    msg.senderAppID = [self getIntValueFromArgs:args forKey:@"sender_appid"];
    msg.receiverAppID = [self getIntValueFromArgs:args forKey:@"receiver_appid"];
    return msg;
}
- (void)sendMessage:(NSDictionary *)args result:(FlutterResult)result {
    int type = [self getIntValueFromArgs:args forKey:@"type"];
    NSDictionary *params = args[@"message"];
    IMessage *message = [self newOutMessage:params];

    if (type == MESSAGE_TEXT) {
        MessageTextContent *content = [[MessageTextContent alloc] initWithText:[self getStringValueFromArgs:params forKey:@"rawContent"]];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_IMAGE) {
        FlutterStandardTypedData *imgD = params[@"image"];
        UIImage *image = [UIImage imageWithData:imgD.data];
        UIImage *sizeImage = [image resize:CGSizeMake(256, 256)];
        image = [self resizeImage:image];
        int newWidth = image.size.width;
        int newHeight = image.size.height;

        MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL] width:newWidth height:newHeight];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [[SDImageCache sharedImageCache] storeImage:image forKey:content.imageURL completion:nil];
        NSString *littleUrl =  [content littleImageURL];
        [[SDImageCache sharedImageCache] storeImage:sizeImage forKey:littleUrl completion:nil];
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_VIDEO) {
        NSString *ttpath = [self getStringValueFromArgs:params forKey:@"path"];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:ttpath];
        AVURLAsset * asset = [AVURLAsset assetWithURL:url];
        int size = (int)[[[NSFileManager defaultManager] attributesOfItemAtPath:ttpath error:nil] fileSize];
        NSDictionary *d = [asset metadata];
        UIImage *thumb = [asset thumbnail];
        int width = [[d objectForKey:@"width"] intValue];
        int height = [[d objectForKey:@"height"] intValue];
        int duration = [[d objectForKey:@"duration"] intValue];
        NSString *thumbURL = [self localImageURL];
        NSString *videoURL = [self localVideoURL];

        [[SDImageCache sharedImageCache] storeImage:thumb forKey:thumbURL completion:nil];
        NSString *path = [[FileCache instance] cachePathForKey:videoURL];
        NSURL *mp4URL = [NSURL fileURLWithPath:path];
        [self convertVideoToLowQuailtyWithInputURL:url outputURL:mp4URL handler:^(AVAssetExportSession *es) {
            if (es.status == AVAssetExportSessionStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    MessageVideoContent *content = [[MessageVideoContent alloc] initWithVideoURL:videoURL
                                                                                       thumbnail:thumbURL
                                                                                           width:width
                                                                                          height:height
                                                                                        duration:duration
                                                                                            size:size];

                    message.rawContent = content.raw;
                    message.timestamp = (int)time(NULL);
                    message.isOutgoing = YES;
                    [self saveMessage:message];
                    [self loadSenderInfo:message];
                    [self sendMessage:message secret:message.secret];
                    result([self resultSuccess:[message mj_keyValues]]);
                });
            }
        }];

    } else if (type == MESSAGE_AUDIO) {
        NSString *path = [self getStringValueFromArgs:params forKey:@"path"];
        int second = [self getIntValueFromArgs:params forKey:@"second"];
        MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:[self localAudioURL] duration:second];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        NSData *data = [NSData dataWithContentsOfFile:path];
        FileCache *fileCache = [FileCache instance];
        [fileCache storeFile:data forKey:content.url];
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);

    } else if (type == MESSAGE_LOCATION) {
        double latitude  = [[self getStringValueFromArgs:params forKey:@"latitude"] doubleValue];
        double longitude = [[self getStringValueFromArgs:params forKey:@"longitude"] doubleValue];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
        MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
        message.rawContent = content.raw;
        content = message.locationContent;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendMessage:message secret:message.secret];
        [self createMapSnapshot:message];
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:message];
        }
        result([self resultSuccess:[message mj_keyValues]]);
    } else {
        result([self resultSuccess:@"暂不支持"]);
    }
}
- (void)sendGroupMessage:(NSDictionary *)args result:(FlutterResult)result {
    int type = [self getIntValueFromArgs:args forKey:@"type"];
    NSDictionary *params = args[@"message"];
    IMessage *message = [self newOutMessage:params];

    if (type == MESSAGE_TEXT) {
        MessageTextContent *content = [[MessageTextContent alloc] initWithText:[self getStringValueFromArgs:params forKey:@"rawContent"]];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendGroupMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_IMAGE) {
        FlutterStandardTypedData *imgD = params[@"image"];
        UIImage *image = [UIImage imageWithData:imgD.data];
        UIImage *sizeImage = [image resize:CGSizeMake(256, 256)];
        image = [self resizeImage:image];
        int newWidth = image.size.width;
        int newHeight = image.size.height;

        MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL] width:newWidth height:newHeight];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [[SDImageCache sharedImageCache] storeImage:image forKey:content.imageURL completion:nil];
        NSString *littleUrl =  [content littleImageURL];
        [[SDImageCache sharedImageCache] storeImage:sizeImage forKey:littleUrl completion:nil];
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendGroupMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_VIDEO) {
        NSString *ttpath = [self getStringValueFromArgs:params forKey:@"path"];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:ttpath];
        AVURLAsset * asset = [AVURLAsset assetWithURL:url];
        int size = (int)[[[NSFileManager defaultManager] attributesOfItemAtPath:ttpath error:nil] fileSize];
        NSDictionary *d = [asset metadata];
        UIImage *thumb = [asset thumbnail];
        int width = [[d objectForKey:@"width"] intValue];
        int height = [[d objectForKey:@"height"] intValue];
        int duration = [[d objectForKey:@"duration"] intValue];
        NSString *thumbURL = [self localImageURL];
        NSString *videoURL = [self localVideoURL];

        [[SDImageCache sharedImageCache] storeImage:thumb forKey:thumbURL completion:nil];
        NSString *path = [[FileCache instance] cachePathForKey:videoURL];
        NSURL *mp4URL = [NSURL fileURLWithPath:path];
        [self convertVideoToLowQuailtyWithInputURL:url outputURL:mp4URL handler:^(AVAssetExportSession *es) {
            if (es.status == AVAssetExportSessionStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    MessageVideoContent *content = [[MessageVideoContent alloc] initWithVideoURL:videoURL
                                                                                       thumbnail:thumbURL
                                                                                           width:width
                                                                                          height:height
                                                                                        duration:duration
                                                                                            size:size];

                    message.rawContent = content.raw;
                    message.timestamp = (int)time(NULL);
                    message.isOutgoing = YES;
                    [self saveMessage:message];
                    [self loadSenderInfo:message];
                    [self sendGroupMessage:message secret:message.secret];
                    result([self resultSuccess:[message mj_keyValues]]);
                });
            }
        }];

    } else if (type == MESSAGE_AUDIO) {
        NSString *path = [self getStringValueFromArgs:params forKey:@"path"];
        int second = [self getIntValueFromArgs:params forKey:@"second"];
        MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:[self localAudioURL] duration:second];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        NSData *data = [NSData dataWithContentsOfFile:path];
        FileCache *fileCache = [FileCache instance];
        [fileCache storeFile:data forKey:content.url];
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendGroupMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);

    } else if (type == MESSAGE_LOCATION) {
        double latitude  = [[self getStringValueFromArgs:params forKey:@"latitude"] doubleValue];
        double longitude = [[self getStringValueFromArgs:params forKey:@"longitude"] doubleValue];

        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
        MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
        message.rawContent = content.raw;
        content = message.locationContent;

        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendGroupMessage:message secret:message.secret];
        [self createMapSnapshot:message];
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:message];
        }
        result([self resultSuccess:[message mj_keyValues]]);
    } else {
        result([self resultSuccess:@"暂不支持"]);
    }
}
-(void)sendFlutterMessage:(NSDictionary *)args result:(FlutterResult)result {
    int type = [self getIntValueFromArgs:args forKey:@"type"];
    NSDictionary *params = args[@"message"];
    IMessage *message = [self newOutMessage:params];

    if (type == MESSAGE_TEXT) {
        MessageTextContent *content = [[MessageTextContent alloc] initWithText:[self getStringValueFromArgs:params forKey:@"rawContent"]];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_IMAGE) {
        NSString *path = [self getStringValueFromArgs:params forKey:@"path"];


        MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:path width:0 height:0];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_VIDEO) {
        NSString *videoURL = [self getStringValueFromArgs:params forKey:@"path"];
        NSString *thumbURL = [self getStringValueFromArgs:params forKey:@"thumbPath"];
                    MessageVideoContent *content = [[MessageVideoContent alloc] initWithVideoURL:videoURL
                                                                                       thumbnail:thumbURL
                                                                                           width:0
                                                                                          height:0
                                                                                        duration:0
                                                                                            size:0];

                    message.rawContent = content.raw;
                    message.timestamp = (int)time(NULL);
                    message.isOutgoing = YES;
                    [self saveMessage:message];
                    [self loadSenderInfo:message];
                    [self sendFlutterMessage:message secret:message.secret];
                    result([self resultSuccess:[message mj_keyValues]]);


    } else if (type == MESSAGE_AUDIO) {
        NSString *path = [self getStringValueFromArgs:params forKey:@"path"];
        int second = [self getIntValueFromArgs:params forKey:@"second"];
        MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:path duration:second];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);

    } else if (type == MESSAGE_LOCATION) {
        double latitude  = [[self getStringValueFromArgs:params forKey:@"latitude"] doubleValue];
        double longitude = [[self getStringValueFromArgs:params forKey:@"longitude"] doubleValue];

        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
        MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
        message.rawContent = content.raw;
        content = message.locationContent;

        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterMessage:message secret:message.secret];
        [self createMapSnapshot:message];
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:message];
        }
        result([self resultSuccess:[message mj_keyValues]]);
    } else {
        result([self resultSuccess:@"暂不支持"]);
    }
}
- (void)sendFlutterGroupMessage:(NSDictionary *)args result:(FlutterResult)result {
    int type = [self getIntValueFromArgs:args forKey:@"type"];
    NSDictionary *params = args[@"message"];
    IMessage *message = [self newOutMessage:params];

    if (type == MESSAGE_TEXT) {
        MessageTextContent *content = [[MessageTextContent alloc] initWithText:[self getStringValueFromArgs:params forKey:@"rawContent"]];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterGroupMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_IMAGE) {
        NSString *path = [self getStringValueFromArgs:params forKey:@"path"];


        MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:path width:0 height:0];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterGroupMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_VIDEO) {
        NSString *videoURL = [self getStringValueFromArgs:params forKey:@"path"];
        NSString *thumbURL = [self getStringValueFromArgs:params forKey:@"thumbPath"];
                    MessageVideoContent *content = [[MessageVideoContent alloc] initWithVideoURL:videoURL
                                                                                       thumbnail:thumbURL
                                                                                           width:0
                                                                                          height:0
                                                                                        duration:0
                                                                                            size:0];

                    message.rawContent = content.raw;
                    message.timestamp = (int)time(NULL);
                    message.isOutgoing = YES;
                    [self saveMessage:message];
                    [self loadSenderInfo:message];
                    [self sendFlutterGroupMessage:message secret:message.secret];
                    result([self resultSuccess:[message mj_keyValues]]);


    } else if (type == MESSAGE_AUDIO) {
        NSString *path = [self getStringValueFromArgs:params forKey:@"path"];
        int second = [self getIntValueFromArgs:params forKey:@"second"];
        MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:path duration:second];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterGroupMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);

    } else if (type == MESSAGE_LOCATION) {
        double latitude  = [[self getStringValueFromArgs:params forKey:@"latitude"] doubleValue];
        double longitude = [[self getStringValueFromArgs:params forKey:@"longitude"] doubleValue];

        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
        MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
        message.rawContent = content.raw;
        content = message.locationContent;

        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterGroupMessage:message secret:message.secret];
        [self createMapSnapshot:message];
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:message];
        }
        result([self resultSuccess:[message mj_keyValues]]);
    } else {
        result([self resultSuccess:@"暂不支持"]);
    }
}
-(void)sendFlutterCustomerMessage:(NSDictionary *)args result:(FlutterResult)result {
    int type = [self getIntValueFromArgs:args forKey:@"type"];
    NSDictionary *params = args[@"message"];
    IMessage *message = [self newCustomerOutMessage:params];

    if (type == MESSAGE_TEXT) {
        MessageTextContent *content = [[MessageTextContent alloc] initWithText:[self getStringValueFromArgs:params forKey:@"rawContent"]];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterCustomerMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_IMAGE) {
        NSString *path = [self getStringValueFromArgs:params forKey:@"path"];
        MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:path  width:0 height:0];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterCustomerMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);
    } else if (type == MESSAGE_VIDEO) {
        NSString *videoURL = [self getStringValueFromArgs:params forKey:@"path"];
        NSString *thumbURL = [self getStringValueFromArgs:params forKey:@"thumbPath"];
                    MessageVideoContent *content = [[MessageVideoContent alloc] initWithVideoURL:videoURL
                                                                                       thumbnail:thumbURL
                                                                                           width:0
                                                                                          height:0
                                                                                        duration:0
                                                                                            size:0];

                    message.rawContent = content.raw;
                    message.timestamp = (int)time(NULL);
                    message.isOutgoing = YES;
                    [self saveMessage:message];
                    [self loadSenderInfo:message];
                    [self sendFlutterCustomerMessage:message secret:message.secret];
                    result([self resultSuccess:[message mj_keyValues]]);


    } else if (type == MESSAGE_AUDIO) {
        NSString *path = [self getStringValueFromArgs:params forKey:@"path"];
        int second = [self getIntValueFromArgs:params forKey:@"second"];
        MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:path duration:second];
        message.rawContent = content.raw;
        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterCustomerMessage:message secret:message.secret];
        result([self resultSuccess:[message mj_keyValues]]);

    } else if (type == MESSAGE_LOCATION) {
        double latitude  = [[self getStringValueFromArgs:params forKey:@"latitude"] doubleValue];
        double longitude = [[self getStringValueFromArgs:params forKey:@"longitude"] doubleValue];

        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
        MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
        message.rawContent = content.raw;
        content = message.locationContent;

        message.timestamp = (int)time(NULL);
        message.isOutgoing = YES;
        [self saveMessage:message];
        [self loadSenderInfo:message];
        [self sendFlutterCustomerMessage:message secret:message.secret];
        [self createMapSnapshot:message];
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:message];
        }
        result([self resultSuccess:[message mj_keyValues]]);
    } else {
        result([self resultSuccess:@"暂不支持"]);
    }
}
- (void)loadData:(NSDictionary *)args result:(FlutterResult)result {
    int msgID = [self getIntValueFromArgs:args forKey:@"messageID"];
    NSArray *messages;
    if (msgID > 0) {
        messages = [self loadConversationData:msgID];
    } else {
        messages = [self loadConversationData];
    }
    [self wrapperMessages:messages];
    result([self resultSuccess:[IMessage mj_keyValuesArrayWithObjectArray:messages]]);
}
- (void)loadLateData:(NSDictionary *)args result:(FlutterResult)result {
    int msgID = [self getIntValueFromArgs:args forKey:@"messageID"];
    NSArray *messages = [self loadLateData:msgID];
    [self wrapperMessages:messages];
    result([self resultSuccess:[IMessage mj_keyValuesArrayWithObjectArray:messages]]);
}

- (void)loadEarlierData:(NSDictionary *)args result:(FlutterResult)result {
    int msgID = [self getIntValueFromArgs:args forKey:@"messageID"];
    NSArray *messages = [self loadEarlierData:msgID];
    [self wrapperMessages:messages];
    result([self resultSuccess:[IMessage mj_keyValuesArrayWithObjectArray:messages]]);
}



- (void)loadCustomerData:(NSDictionary *)args result:(FlutterResult)result {
    int msgID = [self getIntValueFromArgs:args forKey:@"messageID"];
    int appId = [self getIntValueFromArgs:args forKey:@"appId"];
    int uid = [self getIntValueFromArgs:args forKey:@"uid"];
    NSArray *messages;
    if (msgID > 0) {
        messages = [self loadCustomerConversationData:appId uid :uid messageID: msgID];
    } else {
        messages = [self loadCustomerConversationData :appId uid :uid];
    }
    [self wrapperMessages:messages];
    result([self resultSuccess:[IMessage mj_keyValuesArrayWithObjectArray:messages]]);
}
- (void)loadCustomerLateData:(NSDictionary *)args result:(FlutterResult)result {
    int msgID = [self getIntValueFromArgs:args forKey:@"messageID"];
    NSArray *messages = [self loadCustomerLateData:msgID];
    [self wrapperMessages:messages];
    result([self resultSuccess:[IMessage mj_keyValuesArrayWithObjectArray:messages]]);
}

- (void)loadCustomerEarlierData:(NSDictionary *)args result:(FlutterResult)result {
    int msgID = [self getIntValueFromArgs:args forKey:@"messageID"];
    NSArray *messages = [self loadCustomerEarlierData:msgID];
    [self wrapperMessages:messages];
    result([self resultSuccess:[IMessage mj_keyValuesArrayWithObjectArray:messages]]);
}


#pragma mark - RTMessageObserver
- (void)onRTMessage:(RTMessage *)rt {
    NSData *data = [rt.content dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    NSDictionary *obj = [dict objectForKey:@"voip"];
    if (!obj) {
        return;
    }
    if (rt.receiver != self.myUID) {
        return;
    }
 //   VOIPCommand *command = [[VOIPCommand alloc] initWithContent:obj];
  //  if ([self.channelIDs containsObject:command.channelID]) {
  //      return;
  //  }

// if (command.cmd == VOIP_COMMAND_DIAL) {
//
// [self.channelIDs addObject:command.channelID];
//
// VOIPVideoViewController *controller = [[VOIPVoiceViewController alloc] init];
// controller.currentUID = self.myUID;
// controller.peerUID = rt.sender;
// controller.peerName = @"聊天";
// controller.token = @"self.token";
// controller.isCaller = NO;
// controller.channelID = command.channelID;
// [[self rootViewControllers] presentViewController:controller animated:YES completion:nil];
//
// } else if (command.cmd == VOIP_COMMAND_DIAL_VIDEO) {
//
//
// [self.channelIDs addObject:command.channelID];
//
// VOIPVideoViewController *controller = [[VOIPVideoViewController alloc] init];
// controller.currentUID = self.myUID;
// controller.peerUID = rt.sender;
// controller.peerName = @"聊天";
// controller.token = @"self.token";
// controller.isCaller = NO;
// controller.channelID = command.channelID;
// [[self rootViewControllers] presentViewController:controller animated:YES completion:nil];
// }
}

// - (void)voice_call:(NSDictionary *)args result:(FlutterResult)result {
// NSString *peer_id = [self getStringValueFromArgs:args forKey:@"peer_id"];
// int64_t peerUID = [peer_id intValue];
// VOIPVoiceViewController *controller = [[VOIPVoiceViewController alloc] init];
// controller.currentUID = self.myUID;
// controller.peerUID = peerUID;
// controller.peerName = @"聊天";
// controller.token = @"self.token";
// controller.isCaller = YES;
//
// [[self rootViewControllers] presentViewController:controller animated:YES completion:nil];
//
// }
// - (void)video_call:(NSDictionary *)args result:(FlutterResult)result {
// NSString *peer_id = [self getStringValueFromArgs:args forKey:@"peer_id"];
// int64_t peerUID = [peer_id intValue];
// VOIPVideoViewController *controller = [[VOIPVideoViewController alloc] init];
// controller.currentUID = self.myUID;
// controller.peerUID = peerUID;
// controller.peerName = @"聊天";
// controller.token = @"self.token";
// controller.isCaller = YES;
//
// [[self rootViewControllers] presentViewController:controller animated:YES completion:nil];
//
// }
// - (void)voice_receive_call:(NSDictionary *)args result:(FlutterResult)result {
// NSString *peer_id = [self getStringValueFromArgs:args forKey:@"peer_id"];
// int64_t peerUID = [peer_id intValue];
// VOIPVoiceViewController *controller = [[VOIPVoiceViewController alloc] init];
// controller.currentUID = self.myUID;
// controller.peerUID = peerUID;
// controller.peerName = @"聊天";
// controller.token = @"self.token";
// controller.isCaller = NO;
//
// [[self rootViewControllers] presentViewController:controller animated:YES completion:nil];
//
// }
// - (void)video_receive_call:(NSDictionary *)args result:(FlutterResult)result {
// NSString *peer_id = [self getStringValueFromArgs:args forKey:@"peer_id"];
// int64_t peerUID = [peer_id intValue];
// VOIPVideoViewController *controller = [[VOIPVideoViewController alloc] init];
// controller.currentUID = self.myUID;
// controller.peerUID = peerUID;
// controller.peerName = @"聊天";
// controller.token = @"self.token";
// controller.isCaller = NO;
//
// [[self rootViewControllers] presentViewController:controller animated:YES completion:nil];
//
// }
//展示视频用
- (UIViewController *)rootViewControllers{
    UIViewController *rootVC = [[UIApplication sharedApplication].delegate window].rootViewController;

    UIViewController *parent = rootVC;
    while((parent = rootVC.presentingViewController) != nil){
        rootVC = parent;
    }

    while ([rootVC isKindOfClass:[UINavigationController class]]) {
        rootVC = [(UINavigationController *)rootVC topViewController];
    }

    return rootVC;
}
- (void)createConversion:(NSDictionary *)args result:(FlutterResult)result {
    NSString *currentUID = [self getStringValueFromArgs:args forKey:@"currentUID"];
    NSString *peerUID = [self getStringValueFromArgs:args forKey:@"peerUID"];
    BOOL secret = [self getBoolValueFromArgs:args forKey:@"secret"];

    self.messageDB = secret ? [EPeerMessageDB instance] : [PeerMessageDB instance];
    self.conversationID = [peerUID integerValue];
    self.currentUID = [currentUID integerValue];
    result([self resultSuccess:@"createConversion success"]);
}
- (void)createGroupConversion:(NSDictionary *)args result:(FlutterResult)result {
    NSString *currentUID = [self getStringValueFromArgs:args forKey:@"currentUID"];
    NSString *groupUID = [self getStringValueFromArgs:args forKey:@"groupUID"];
    //BOOL secret = [self getBoolValueFromArgs:args forKey:@"secret"];

    self.messageDB = [GroupMessageDB instance];
    self.conversationID = [groupUID integerValue];
    self.currentUID = [currentUID integerValue];
    self.conversationID= [groupUID integerValue];
    result([self resultSuccess:@"createGroupConversion success"]);
}
- (void)createCustomerConversion:(NSDictionary *)args result:(FlutterResult)result {
    NSString *currentUID = [self getStringValueFromArgs:args forKey:@"currentUID"];
    NSString *peerUID = [self getStringValueFromArgs:args forKey:@"peerUID"];
    self.messageDB = [CustomerMessageDB instance];
    self.conversationID = [peerUID integerValue];
    self.currentUID = [currentUID integerValue];
    result([self resultSuccess:@"createConversion success"]);
}
- (void)logout {
    [[IMService instance] stop];
}

- (void)init:(NSDictionary *)args result:(FlutterResult)result {
    NSString *host = [self getStringValueFromArgs:args forKey:@"host"]; // @"imnode2.gobelieve.io"
    NSString *apiURL = [self getStringValueFromArgs:args forKey:@"apiURL"]; // @"http://api.gobelieve.io";
    [IMHttpAPI instance].apiURL = apiURL;
    [IMService instance].host = host;

    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [IMService instance].deviceID = deviceID;
    [IMService instance].peerMessageHandler = [PeerMessageHandler instance];
    [IMService instance].groupMessageHandler = [GroupMessageHandler instance];
    [IMService instance].customerMessageHandler = [CustomerMessageHandler instance];
    [self startRechabilityNotifier];
    [IMService instance].reachable = [self.reach isReachable];
    dispatch_queue_t queue = dispatch_queue_create("com.beetle.im", DISPATCH_QUEUE_SERIAL);
    [IMService instance].queue = queue;
    [self refreshHost:host apiHost:[NSURL URLWithString:apiURL].host];
    result([self resultSuccess:@"init success"]);
}

- (void)login:(NSDictionary *)args result:(FlutterResult)result {
    //调用app自身的服务器获取连接im服务必须的access token
    NSString *uid = [self getStringValueFromArgs:args forKey:@"uid"];

    long long l_uid = [uid longLongValue];
    NSString *appid = [self getStringValueFromArgs:args forKey:@"appid"];
    long long l_appid = [appid longLongValue];
    NSString *token = nil;
    if (args[@"token"] && ![args[@"token"] isKindOfClass:[NSNull class]]) {
        token = [self getStringValueFromArgs:args forKey:@"token"];
    } else {
        token = [self login: l_uid];
    }

    if (token.length == 0) {
        result([self resultError:@"login fail" code:1]);
        return ;
    }
    NSLog(@"token:%@", token);
    self.myUID = [uid longLongValue];
    self.appID = [appid longLongValue];
    NSString *path = [self getDocumentPath];
    NSString *dbPath = [NSString stringWithFormat:@"%@/gobelieve_%lld.db", path, l_uid];
    FMDatabaseQueue *db = [Database openMessageDB:dbPath];
    [ConversationDB instance].db = db;
    [PeerMessageDB instance].db = db;
    [GroupMessageDB instance].db = db;
    [CustomerMessageDB instance].db = db;

    [PeerMessageHandler instance].uid = l_uid;
    [GroupMessageHandler instance].uid = l_uid;
    [CustomerMessageHandler instance].uid = l_uid;
    [CustomerMessageHandler instance].appid = l_appid;
    [IMHttpAPI instance].accessToken = token;
    [IMService instance].token = token;


    path = [self getDocumentPath];
    dbPath = [NSString stringWithFormat:@"%@/%lld", path, l_uid];
    [self mkdir:dbPath];

    NSString *fileName = [NSString stringWithFormat:@"%@/synckey", dbPath];
    SyncKeyHandler *handler = [[SyncKeyHandler alloc] initWithFileName:fileName];
    [IMService instance].syncKeyHandler = handler;

    [IMService instance].syncKey = [handler syncKey];
    NSLog(@"sync key:%lld", [handler syncKey]);

    [[IMService instance] clearSuperGroupSyncKey];
    NSDictionary *groups = [handler superGroupSyncKeys];
    for (NSNumber *k in groups) {
        NSNumber *v = [groups objectForKey:k];
        NSLog(@"group id:%@ sync key:%@", k, v);
        [[IMService instance] addSuperGroupSyncKey:[v longLongValue] gid:[k longLongValue]];
    }

    [[IMService instance] start];

    if (self.deviceToken.length > 0) {
        [IMHttpAPI bindDeviceToken:[self getDeviceTokenStr]
                           success:^{
                               NSLog(@"bind device token success");
                           }
                          fail:^{
                              NSLog(@"bind device token fail");
                          }];
    }

    [[PeerOutbox instance] addBoxObserver:self];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addPeerMessageObserver:self];
    [[AudioDownloader instance] addDownloaderObserver:self];

    [[IMService instance] addGroupMessageObserver:self];
    [[IMService instance] addSystemMessageObserver:self];
    [[IMService instance] addRTMessageObserver:self];
    [[IMService instance] addCustomerMessageObserver:self];
    result([self resultSuccess:@"login success"]);
}


#pragma mark - AppDelegate
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString* newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"device token is: %@:%@", deviceToken, newToken);
    self.deviceToken = deviceToken;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[IMService instance] enterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[IMService instance] enterForeground];

    if ([IMService instance].host.length) {
        [self refreshHost:[IMService instance].host
                  apiHost:[NSURL URLWithString:[IMHttpAPI instance].apiURL].host];
    }
}

#pragma mark - tools
-(void)startRechabilityNotifier {
    self.reach = [GOReachability reachabilityForInternetConnection];
    self.reach.reachableBlock = ^(GOReachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"internet reachable");
            [[IMService instance] onReachabilityChange:YES];
        });
    };

    self.reach.unreachableBlock = ^(GOReachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"internet unreachable");
            [[IMService instance] onReachabilityChange:NO];
        });
    };

    [self.reach startNotifier];
}

-(void)refreshHost:(NSString *)host apiHost:(NSString *)apiHost {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSLog(@"refresh host ip...");

        for (int i = 0; i < 10; i++) {
            NSString *_host = host; //@"imnode2.gobelieve.io";
            NSString *ip = [self resolveIP:host];

            NSString *_apiHost = apiHost; // @"api.gobelieve.io";
            NSString *apiIP = [self resolveIP:apiHost];


            NSLog(@"host:%@ ip:%@", _host, ip);
            NSLog(@"api host:%@ ip:%@", _apiHost, apiIP);

            if (ip.length == 0 || apiIP.length == 0) {
                continue;
            } else {
                break;
            }
        }
    });
}

-(NSString*)IP2String:(struct in_addr)addr {
    char buf[64] = {0};
    const char *p = inet_ntop(AF_INET, &addr, buf, 64);
    if (p) {
        return [NSString stringWithUTF8String:p];
    }
    return nil;

}

-(NSString*)resolveIP:(NSString*)host {
    struct addrinfo hints;
    struct addrinfo *result, *rp;
    int s;

    char buf[32];
    snprintf(buf, 32, "%d", 0);

    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = 0;

    s = getaddrinfo([host UTF8String], buf, &hints, &result);
    if (s != 0) {
        NSLog(@"get addr info error:%s", gai_strerror(s));
        return nil;
    }
    NSString *ip = nil;
    rp = result;
    if (rp != NULL) {
        struct sockaddr_in *addr = (struct sockaddr_in*)rp->ai_addr;
        ip = [self IP2String:addr->sin_addr];
    }
    freeaddrinfo(result);
    return ip;
}

#pragma mark - private
-(NSString*)login:(long long)uid {
    //调用app自身的服务器获取连接im服务必须的access token
    NSString *hosts =[IMHttpAPI instance].apiURL;
    NSString *url = [hosts stringByAppendingString:@"/v1/login/GetAuth"];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60];


    [urlRequest setHTTPMethod:@"POST"];

    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];

    [urlRequest setAllHTTPHeaderFields:headers];



#if TARGET_IPHONE_SIMULATOR
    NSString *deviceID = @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61";
    NSLog(@"device id:%@", @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61");
#else
    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSLog(@"device id:%@", [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
#endif


    NSMutableDictionary *obj = [NSMutableDictionary dictionary];
    [obj setObject:[NSNumber numberWithLongLong:uid] forKey:@"uid"];
    [obj setObject:[NSString stringWithFormat:@"测试用户%lld", uid] forKey:@"user_name"];
    [obj setObject:[NSNumber numberWithInt:PLATFORM_IOS] forKey:@"platform_id"];
    [obj setObject:deviceID forKey:@"device_id"];

    NSData *postBody = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];

    [urlRequest setHTTPBody:postBody];

    NSURLResponse *response = nil;

    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if (error != nil) {
        NSLog(@"error:%@", error);
        return nil;
    }
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)response;
    if (httpResp.statusCode != 200) {
        return nil;
    }
    NSDictionary *e = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
     return [[e objectForKey:@"data"] objectForKey:@"token"];
}

-(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(BOOL)mkdir:(NSString*)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        NSError *err;
        BOOL r = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];

        if (!r) {
            NSLog(@"mkdir err:%@", err);
        }
       return r;
    }

    return YES;
}

- (NSString *)getDeviceTokenStr {
    NSString* newToken = [self.deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    return newToken;
}

- (NSDictionary *)_buildResult:(int)code message:(NSString *)message data:(id)data {
    if (data) {
        return @{
            @"code": @(code),
            @"message": message,
            @"data": data
        };
    } else {
        return @{
            @"code": @(code),
            @"message": message,
        };
    }
}

- (NSDictionary *)resultSuccess:(id)data {
    return [self _buildResult:0 message:@"成功" data:data];
}

- (NSDictionary *)resultError:(NSString *)error code:(int)code{
    return [self _buildResult:code message:error data:nil];
}

- (int)getIntValueFromArgs:(NSDictionary *)args forKey:(NSString *)forKey {
    if (args[forKey] && ![args[forKey] isKindOfClass:[NSNull class]]) {
        return [[self getStringValueFromArgs:args forKey:forKey] intValue];
    }
    return 0;
}

- (NSString *)getStringValueFromArgs:(NSDictionary *)args forKey:(NSString *)forKey {
    if (![args[forKey] isKindOfClass:[NSNull class]]) {
        return [NSString stringWithString:args[forKey]];
    } else {
        return nil;
    }
}

- (BOOL)getBoolValueFromArgs:(NSDictionary *)args forKey:(NSString *)forKey {
    if (args[forKey] && ![args[forKey] isKindOfClass:[NSNull class]]) {
       return [[self getStringValueFromArgs:args forKey:forKey] boolValue];
    }
    return NO;
}

- (void)callFlutter:(id)params {
    if (self.eventSink) {
        self.eventSink(params);
    }
}
#pragma mark - AudioDownloaderObserver
- (void)onAudioDownloadSuccess:(IMessage *)msg {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onAudioDownloadSuccess",
        @"result": [msg mj_keyValues]
    }]];
}

- (void)onAudioDownloadFail:(IMessage *)msg {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onAudioDownloadFail",
        @"result": [msg mj_keyValues]
    }]];
}


#pragma mark - PeerMessageObserver
- (void)onPeerMessage:(IMMessage *)im {
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.secret = NO;
    m.msgId = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isOutgoing = (im.sender == self.currentUID);
    if (im.sender == self.currentUID) {
            m.flags = m.flags | MESSAGE_FLAG_ACK;
        }
    [self loadSenderInfo:m];
    [self downloadMessageContent:m];
    [self updateNotificationDesc:m];
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onPeerMessage",
        @"result": [m mj_keyValues]
    }]];

    int64_t cid;
    if (self.currentUID == m.sender) {
        cid = m.receiver;
    } else {
        cid = m.sender;
    }

    [self onNewMessage:m cid:cid is_send:0];
}

- (void)onPeerSecretMessage:(IMMessage *)im {
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.secret = YES;
    m.msgId = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isOutgoing = (im.sender == self.currentUID);
    if (im.sender == self.currentUID) {
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    }
    [self updateNotificationDesc:m];
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onPeerSecretMessage",
        @"result": [m mj_keyValues]
    }]];

    int64_t cid;
    if (self.currentUID == m.sender) {
        cid = m.receiver;
    } else {
        cid = m.sender;
    }

    [self onNewMessage:m cid:cid is_send:0];
}

-(void)onNewMessage:(IMessage*)msg cid:(int64_t)cid is_send:(int)is_send{

 if(is_send){
  Conversation *con = [[ConversationDB instance] getConversation:cid type:CONVERSATION_PEER];
     if (con != nil) {

     } else {
         Conversation *con = [[Conversation alloc] init];
         con.type = CONVERSATION_PEER;
         con.cid = cid;
         con.message = msg;
         [[ConversationDB instance] addConversation:con];

     }
 }else{
  Conversation *con = [[ConversationDB instance] getConversation:cid type:CONVERSATION_PEER];
     if (con != nil) {
          [[ConversationDB instance] setNewCount:con.rowid count:con.newMsgCount +1];
     } else {
         Conversation *con = [[Conversation alloc] init];
         con.type = CONVERSATION_PEER;
         con.cid = cid;
         con.message = msg;
         [[ConversationDB instance] addConversation:con];

     }
 }

    [self callFlutter:[self resultSuccess:@{
        @"type": @"onNewMessage"
    }]];
}

-(void)onNewGroupMessage:(IMessage*)msg cid:(int64_t)cid is_send:(int)is_send{
  if(is_send){
    Conversation *con = [[ConversationDB instance] getConversation:cid type:CONVERSATION_PEER];
       if (con != nil) {

       } else {
           Conversation *con = [[Conversation alloc] init];
           con.type = CONVERSATION_GROUP;
           con.cid = cid;
           con.message = msg;
           [[ConversationDB instance] addConversation:con];

       }
   }else{
    Conversation *con = [[ConversationDB instance] getConversation:cid type:CONVERSATION_PEER];
       if (con != nil) {
            [[ConversationDB instance] setNewCount:con.rowid count:con.newMsgCount +1];
       } else {
           Conversation *con = [[Conversation alloc] init];
           con.type = CONVERSATION_GROUP;
           con.cid = cid;
           con.message = msg;
           [[ConversationDB instance] addConversation:con];

       }
   }

    [self callFlutter:[self resultSuccess:@{
        @"type": @"onNewGroupMessage"
    }]];
}

-(void)onNewCustomerMessage:(IMessage*)msg cid:(int64_t)cid appid:(int64_t)appid is_send:(int)is_send{
    if(is_send){
        Conversation *con = [[ConversationDB instance] getConversation:msg.receiver  appid:msg.receiverAppID type:CONVERSATION_CUSTOMER_SERVICE];


        if (con != nil) {

        } else {
            Conversation *con = [[Conversation alloc] init];
            con.type = CONVERSATION_CUSTOMER_SERVICE;
            con.appid = msg.receiverAppID;
            con.cid = msg.receiver;
            con.message = msg;
            [[ConversationDB instance] addConversation:con];

        }
    }else{
        Conversation *con = [[ConversationDB instance] getConversation:cid  appid:appid type:CONVERSATION_CUSTOMER_SERVICE];


        if (con != nil) {

            [[ConversationDB instance] setNewCount:con.rowid count:con.newMsgCount +1];

        } else {
            Conversation *con = [[Conversation alloc] init];
            con.type = CONVERSATION_CUSTOMER_SERVICE;
            con.appid = appid;
            con.cid = cid;
            con.message = msg;
            [[ConversationDB instance] addConversation:con];

        }
    }

    [self callFlutter:[self resultSuccess:@{
        @"type": @"onNewCustomerMessage"
    }]];
}

- (void)onPeerMessageACK:(IMMessage *)im error:(int)error {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onPeerMessageACK",
        @"error": @(error),
        @"result": [im mj_keyValues]
    }]];
}

- (void)onPeerMessageFailure:(IMMessage *)msg {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onPeerMessageFailure",
        @"result": [msg mj_keyValues]
    }]];
}
-(void)onGroupMessage:(IMMessage *)im {
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.secret = NO;
    m.msgId = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isOutgoing = (im.sender == self.currentUID);
    if (im.sender == self.currentUID) {
            m.flags = m.flags | MESSAGE_FLAG_ACK;
        }
    [self loadSenderInfo:m];
    [self downloadMessageContent:m];
    [self updateNotificationDesc:m];
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onGroupMessage",
        @"result": [m mj_keyValues]
    }]];

    int64_t cid;
    // if (self.currentUID == m.sender) {
    cid = m.receiver;
    // } else {
     //   cid = m.sender;
    //}


    [self onNewGroupMessage:m cid:m.receiver is_send:0];
}



#pragma mark - CustomerMessageObserver
- (void)onCustomerMessage:(CustomerMessage *)im {
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.senderAppID =im.senderAppID;
    m.receiverAppID=im.receiverAppID;
    m.secret = NO;
    m.msgId = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isOutgoing = (im.sender == self.currentUID);
    if (im.sender == self.currentUID) {
            m.flags = m.flags | MESSAGE_FLAG_ACK;
        }
    [self loadSenderInfo:m];
    [self downloadMessageContent:m];
    [self updateNotificationDesc:m];
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onCustomerMessage",
        @"result": [m mj_keyValues]
    }]];

    int64_t cid,appid;
    if (self.myUID == m.sender && self.appID == m.senderAppID) {
        cid = m.receiver;
        appid= m.receiverAppID;
    } else {
        cid = m.sender;
        appid= m.senderAppID;
    }

    [self onNewCustomerMessage:m cid:cid appid:appid is_send:0];
}
- (void)onCustomerMessageACK:(CustomerMessage *)im{
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onCustomerMessageACK",
        @"result": [im mj_keyValues]
    }]];
}

- (void)onCustomerMessageFailure:(CustomerMessage *)msg {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onCustomerMessageFailure",
        @"result": [msg mj_keyValues]
    }]];
}
#pragma mark - TCPConnectionObserver
// 同IM服务器连接的状态变更通知
- (void)onConnectState:(int)state {
//    STATE_CONNECTED
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onConnectState",
        @"result": @(state)
    }]];
}

#pragma mark - OutboxObserver
-(void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onAudioUploadSuccess",
        @"URL": url,
        @"result": [msg mj_keyValues]
    }]];
}

-(void)onAudioUploadFail:(IMessage*)msg {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onAudioUploadFail",
        @"result": [msg mj_keyValues]
    }]];
}

-(void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onImageUploadSuccess",
        @"URL": url,
        @"result": [msg mj_keyValues]
    }]];
}

-(void)onImageUploadFail:(IMessage*)msg {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onImageUploadFail",
        @"result": [msg mj_keyValues]
    }]];
}

-(void)onVideoUploadSuccess:(IMessage*)msg URL:(NSString*)url thumbnailURL:(NSString*)thumbURL {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onVideoUploadSuccess",
        @"URL": url,
        @"thumbnailURL": thumbURL,
        @"result": [msg mj_keyValues]
    }]];
}

-(void)onVideoUploadFail:(IMessage*)msg {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onVideoUploadFail",
        @"result": [msg mj_keyValues]
    }]];
}

#pragma mark - SystemMessageObserver
- (void)onSystemMessage:(NSString *)sm {
    NSUInteger index = [self.conversations indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Conversation *conv = obj;
        return conv.type == CONVERSATION_SYSTEM;
    }];
    if (index == NSNotFound) {
        Conversation *conv = [[Conversation alloc] init];
        //todo maybe 从系统消息体中获取时间
        conv.timestamp = (int)time(NULL);
        //todo 解析系统消息格式
        conv.detail = sm;
        conv.name = @"新朋友";
        conv.type = CONVERSATION_SYSTEM;
        conv.cid = 0;
        [self.conversations insertObject:conv atIndex:0];
    } else {
        Conversation *conv = [self.conversations objectAtIndex:index];
        conv.detail = sm;
        conv.timestamp = (int)time(NULL);
        if (index != 0) {
            //置顶
            [self.conversations removeObjectAtIndex:index];
            [self.conversations insertObject:conv atIndex:0];
        }
    }

    [self callFlutter:[self resultSuccess:@{
        @"type": @"onSystemMessage",
        @"result": sm,
    }]];
}




#pragma mark - GroupMessageObserver
-(void)onGroupMessages:(NSArray*)msgs {
    for (int i = 0; i < [msgs count]; i++) {
        IMMessage  *msg = [msgs objectAtIndex:i];

          if (msg.isGroupNotification) {

            } else {
              [self onGroupMessage:msg];
            }
    }


}
-(void)onGroupMessageACK:(IMMessage*)msg error:(int)error {
    [self callFlutter:[self resultSuccess:@{
        @"type": @"onGroupMessageACK",
        @"error": @(error),
        @"result": [msg mj_keyValues]
    }]];

}
-(void)onGroupMessageFailure:(IMMessage*)msg {
  [self callFlutter:[self resultSuccess:@{
        @"type": @"onGroupMessageFailure",
        @"result": [msg mj_keyValues]
    }]];
}


#pragma mark - peer
//navigator from search
- (NSArray*)loadConversationData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    int count = 0;
    id<IMessageIterator> iterator;

    IMessage *msg = [self.messageDB getMessage:messageID];
    if (!msg) {
        return nil;
    }
    [messages addObject:msg];

    iterator = [self.messageDB newBackwardMessageIterator:self.conversationID  messageID:messageID];
    msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages addObject:msg];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }

        msg = [iterator next];
    }

    count = 0;
    iterator = [self.messageDB newForwardMessageIterator:self.conversationID messageID:messageID];
    msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    return messages;
}

- (NSArray*)loadConversationData {

    NSMutableArray *messages = [NSMutableArray array];

    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    int pageSize;
    id<IMessageIterator> iterator;

    iterator = [self.messageDB newMessageIterator: self.conversationID];
    pageSize = PAGE_COUNT;


    IMessage *msg = [iterator next];
    while (msg) {
        //重复的消息
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            msg = [iterator next];
            continue;
        }

        if (msg.uuid.length > 0){
            [uuidSet addObject:msg.uuid];
        }

        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= pageSize) {
                break;
            }
        }

        msg = [iterator next];
    }
    return messages;
}

- (NSArray*)loadEarlierData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    id<IMessageIterator> iterator = [self.messageDB newForwardMessageIterator:self.conversationID messageID:messageID];

    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];

        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    NSLog(@"load earlier messages:%d", count);
    return messages;
}

//加载后面的聊天记录
-(NSArray*)loadLateData:(int)messageID {
    id<IMessageIterator> iterator = [self.messageDB newBackwardMessageIterator:self.conversationID messageID:messageID];
    NSMutableArray *newMessages = [NSMutableArray array];
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];

        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [newMessages addObject:msg];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }

    NSLog(@"load late messages:%d", count);
    return newMessages;
}

#pragma mark - Customer
//navigator from search
- (NSArray*)loadCustomerConversationData: (int64_t)appId uid:(int64_t)uid messageID:(int64_t)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    int count = 0;
    id<IMessageIterator> iterator;
    CustomerMessageDB *db = (CustomerMessageDB *)self.messageDB;
    IMessage *msg = [db getMessage:messageID];
    if (!msg) {
        return nil;
    }
    [messages addObject:msg];

    iterator = [db newBackwardMessageIterator:uid appID:appId messageID:messageID];
    msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages addObject:msg];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }

        msg = [iterator next];
    }

    count = 0;
    iterator = [self.messageDB newForwardMessageIterator:self.conversationID messageID:messageID];
    msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    return messages;
}

- (NSArray*)loadCustomerConversationData: (int64_t)appId uid:(int64_t)uid {

    NSMutableArray *messages = [NSMutableArray array];

    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    int pageSize;
    id<IMessageIterator> iterator;
    SQLCustomerMessageDB *db = (SQLCustomerMessageDB*)self.messageDB;
    iterator = [db newMessageIterator: uid appID:appId];
    pageSize = PAGE_COUNT;


    IMessage *msg = [iterator next];
    while (msg) {
        //重复的消息
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            msg = [iterator next];
            continue;
        }

        if (msg.uuid.length > 0){
            [uuidSet addObject:msg.uuid];
        }

        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= pageSize) {
                break;
            }
        }

        msg = [iterator next];
    }
    return messages;
}
- (NSArray*)loadCustomerEarlierData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    id<IMessageIterator> iterator = [self.messageDB newForwardMessageIterator:self.conversationID messageID:messageID];

    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];

        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    NSLog(@"load earlier messages:%d", count);
    return messages;
}

//加载后面的聊天记录
-(NSArray*)loadCustomerLateData:(int)messageID {
    id<IMessageIterator> iterator = [self.messageDB newBackwardMessageIterator:self.conversationID messageID:messageID];
    NSMutableArray *newMessages = [NSMutableArray array];
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];

        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [newMessages addObject:msg];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }

    NSLog(@"load late messages:%d", count);
    return newMessages;
}



- (void)sendMessage:(IMessage *)message secret:(BOOL)secret{
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        if (secret) {
            [[PeerOutbox instance] uploadSecretAudio:message];
        } else {
            [[PeerOutbox instance] uploadAudio:message];
        }
        [self onNewMessage:message cid:message.receiver  is_send:1];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        if (secret) {
            [[PeerOutbox instance] uploadSecretImage:message];
        } else {
            [[PeerOutbox instance] uploadImage:message];
        }
        [self onNewMessage:message cid:message.receiver is_send:1];
    } else if (message.type == MESSAGE_VIDEO) {
        message.uploading = YES;
        if (secret) {
            [[PeerOutbox instance] uploadSecretVideo:message];
        } else {
            [[PeerOutbox instance] uploadVideo:message];
        }
        [self onNewMessage:message cid:message.receiver is_send:1];
    } else {
        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgId;
        im.isText = YES;
        im.content = message.rawContent;

        BOOL r = YES;
        if (secret) {
            r = [self encrypt:im];
        }
        if (r) {
            [[IMService instance] sendPeerMessageAsync:im];
        }
        [self onNewMessage:message cid:message.receiver is_send:1];
    }
}
- (void)sendGroupMessage:(IMessage *)message secret:(BOOL)secret{
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        if (secret) {
            [[GroupOutbox instance] uploadSecretAudio:message];
        } else {
            [[GroupOutbox instance] uploadAudio:message];
        }
        [self onNewMessage:message cid:message.receiver is_send:1];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        if (secret) {
            [[GroupOutbox instance] uploadSecretImage:message];
        } else {
            [[GroupOutbox instance] uploadImage:message];
        }
        [self onNewMessage:message cid:message.receiver is_send:1];
    } else if (message.type == MESSAGE_VIDEO) {
        message.uploading = YES;
        if (secret) {
            [[GroupOutbox instance] uploadSecretVideo:message];
        } else {
            [[GroupOutbox instance] uploadVideo:message];
        }
        [self onNewMessage:message cid:message.receiver is_send:1];
    } else {
        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgId;
        im.isText = YES;
        im.content = message.rawContent;

        BOOL r = YES;
        if (secret) {
            r = [self encrypt:im];
        }
        if (r) {
            [[IMService instance] sendGroupMessageAsync:im];
        }
        [self onNewGroupMessage:message cid:message.receiver is_send:1];
    }
}
- (void)sendFlutterMessage:(IMessage *)message secret:(BOOL)secret{

        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgId;
        im.isText = YES;
        im.content = message.rawContent;


        BOOL r = YES;
        if (secret) {
            r = [self encrypt:im];
        }
        if (r) {
            [[IMService instance] sendPeerMessageAsync:im];
        }
        [self onNewMessage:message cid:message.receiver is_send:1];

}
- (void)sendFlutterGroupMessage:(IMessage *)message secret:(BOOL)secret{

        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgId;
        im.isText = YES;
        im.content = message.rawContent;


        BOOL r = YES;
        if (secret) {
            r = [self encrypt:im];
        }
        if (r) {
            [[IMService instance] sendGroupMessageAsync:im];
        }
        [self onNewGroupMessage:message cid:message.receiver is_send:1];

}
- (void)sendFlutterCustomerMessage:(IMessage *)message secret:(BOOL)secret{

        CustomerMessage *im = [[CustomerMessage alloc] init];
        im.senderAppID = message.senderAppID;
        im.sender = message.sender;
        im.receiverAppID = message.receiverAppID;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgId;
        im.content = message.rawContent;
        [[IMService instance] sendCustomerMessageAsync:im];


        [self onNewCustomerMessage:(IMessage*)im cid:im.sender appid:im.senderAppID is_send:1];

}

- (BOOL)saveMessage:(IMessage*)msg {
    return [self.messageDB saveMessage:msg];
}

- (BOOL)removeMessage:(IMessage*)msg {
    return [self.messageDB removeMessage:msg.msgId];
}

- (BOOL)markMessageFailure:(IMessage*)msg {
    return [self.messageDB markMessageFailure:msg.msgId];
}

- (BOOL)markMesageListened:(IMessage*)msg {
    return [self.messageDB markMesageListened:msg.msgId];
}

- (BOOL)eraseMessageFailure:(IMessage*)msg {
    return [self.messageDB eraseMessageFailure:msg.msgId];
}

- (BOOL)encrypt:(IMMessage*)msg {
    return NO;
}

-(UIImage*)resizeImage:(UIImage*)image {
    return [image resize];
}

-(NSString*)guid {
    CFUUIDRef    uuidObj = CFUUIDCreate(nil);
    NSString    *uuidString = (__bridge NSString *)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return uuidString;
}

-(NSString*)localImageURL {
    return [NSString stringWithFormat:@"http://localhost/images/%@.png", [self guid]];
}

-(NSString*)localAudioURL {
    return [NSString stringWithFormat:@"http://localhost/audios/%@.m4a", [self guid]];
}

-(NSString*)localVideoURL {
    return [NSString stringWithFormat:@"http://localhost/videos/%@.mp4", [self guid]];
}


- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL handler:(void (^)(AVAssetExportSession*))handler {
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        handler(exportSession);
    }];
}


#pragma mark - data
- (void)downloadMessageContent:(IMessage*)msg {
    FileCache *cache = [FileCache instance];
    AudioDownloader *downloader = [AudioDownloader instance];
    if (msg.type == MESSAGE_AUDIO) {
        MessageAttachmentContent *attachment = [self.attachments objectForKey:[NSNumber numberWithInt:(int)msg.msgId]];

        if (attachment.url.length > 0) {
            MessageAudioContent *content = [msg.audioContent cloneWithURL:attachment.url];
            msg.rawContent = content.raw;
        }

        MessageAudioContent *content = msg.audioContent;

        NSString *path = [cache queryCacheForKey:content.url];
        NSLog(@"url:%@, %@", content.url, path);
        if (!path && ![downloader isDownloading:msg]) {
            [downloader downloadAudio:msg];
        }
        msg.downloading = [downloader isDownloading:msg];
    } else if (msg.type == MESSAGE_LOCATION) {
        MessageLocationContent *content = msg.locationContent;
        NSString *url = content.snapshotURL;
        if(![[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url] &&
           ![[SDImageCache sharedImageCache] diskImageDataExistsWithKey:url]){
            [self createMapSnapshot:msg];
        }
       
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:msg];
        }
    } else if (msg.type == MESSAGE_IMAGE) {
        NSLog(@"image url:%@", msg.imageContent.imageURL);
        if (msg.secret) {
            MessageImageContent *content = msg.imageContent;
            BOOL exists = [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:content.imageURL];
            BOOL downloading = [downloader isDownloading:msg];
            if (!exists && !downloading) {
                [downloader downloadImage:msg];
                msg.downloading = [downloader isDownloading:msg];
            }
        }
    } else if (msg.type == MESSAGE_VIDEO) {
        if (msg.secret) {
            MessageVideoContent *content = msg.videoContent;
            BOOL exists = [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:content.thumbnailURL];
            BOOL downloading = [downloader isDownloading:msg];
            if (!exists && !downloading) {
                [downloader downloadVideoThumbnail:msg];
                msg.downloading = [downloader isDownloading:msg];
            }
        }
    }
}

- (void)downloadMessageContent:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self downloadMessageContent:msg];
    }
}

- (void)updateNotificationDesc:(IMessage*)message {
    if (message.type == MESSAGE_GROUP_NOTIFICATION) {
        MessageGroupNotificationContent *notification = message.groupNotificationContent;
        int type = notification.notificationType;
        if (type == NOTIFICATION_GROUP_CREATED) {
            if (self.currentUID == notification.master) {
                NSString *desc = [NSString stringWithFormat:@"您创建了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
            } else {
                NSString *desc = [NSString stringWithFormat:@"您加入了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
            }
        } else if (type == NOTIFICATION_GROUP_DISBANDED) {
            notification.notificationDesc = @"群组已解散";
        } else if (type == NOTIFICATION_GROUP_MEMBER_ADDED) {
            IUser *u = [self getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
                [self asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@加入群", u.name];
                    notification.notificationDesc = desc;
                }];
            }
        } else if (type == NOTIFICATION_GROUP_MEMBER_LEAVED) {
            IUser *u = [self getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
                [self asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@离开群", u.name];
                    notification.notificationDesc = desc;
                }];
            }
        } else if (type == NOTIFICATION_GROUP_NAME_UPDATED) {
            NSString *desc = [NSString stringWithFormat:@"群组更名为%@", notification.groupName];
            notification.notificationDesc = desc;
        } else if (type == NOTIFICATION_GROUP_NOTICE_UPDATED) {
            NSString *desc = [NSString stringWithFormat:@"群公告:%@", notification.notice];
            notification.notificationDesc = desc;
        }
    } else if (message.type == MESSAGE_GROUP_VOIP) {
        MessageGroupVOIPContent *content = (MessageGroupVOIPContent*)message.groupVOIPContent;
        if (content.finished) {
            content.notificationDesc = @"语音通话已经结束";
        } else {
            IUser *u = [self getUser:content.initiator];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", name];
                content.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", name];
                content.notificationDesc = desc;
                [self asyncGetUser:content.initiator cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", u.name];
                    content.notificationDesc = desc;
                }];
            }
        }
    } else if (message.type == MESSAGE_REVOKE) {
        MessageRevoke *content = message.revokeContent;
        if (message.isOutgoing) {
            content.notificationDesc = @"你撤回了一条消息";
        } else {
            IUser *u = [self getUser:message.sender];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"\"%@\"撤回了一条消息", name];
                content.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"\"%@\"撤回了一条消息", name];
                content.notificationDesc = desc;
                [self asyncGetUser:message.sender cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"\"%@\"撤回了一条消息", u.name];
                    content.notificationDesc = desc;
                }];
            }
        }
    } else if (message.type == MESSAGE_ACK) {
        MessageACK *ack = message.ackContent;
        if (ack.error == MSG_ACK_NOT_YOUR_FRIEND) {
            ack.notificationDesc = @"你还不是他（她）朋友";
        } else if (ack.error == MSG_ACK_IN_YOUR_BLACKLIST) {
            ack.notificationDesc = @"消息已发出，但被对方拒收了。";
        } else if (ack.error == MSG_ACK_NOT_MY_FRIEND) {
            ack.notificationDesc = @"对方已不是你的朋友";
        }
    }
}

- (void)updateNotificationDesc:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self updateNotificationDesc:msg];
    }
}

-(void)checkMessageFailureFlag:(IMessage*)msg {
    if (msg.isOutgoing) {
        if (msg.timestamp < flt_im_uptime) {
            if (!msg.isACK) {
                //上次运行的时候，程序异常崩溃
                [self markMessageFailure:msg];
                msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
            }
        }
    }
}

-(void)checkMessageFailureFlag:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self checkMessageFailureFlag:msg];
    }
}

- (void)loadSenderInfo:(IMessage*)msg {
    msg.senderInfo = [self getUser:msg.sender];
    if (msg.senderInfo.name.length == 0) {
        [self asyncGetUser:msg.sender cb:^(IUser *u) {
            msg.senderInfo = u;
        }];
    }
}
- (void)loadSenderInfo:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self loadSenderInfo:msg];
    }
}

-(void)checkAtName:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self checkAtName:msg];
    }
}

-(void)checkAtName:(IMessage*)msg {

}

- (void)createMapSnapshot:(IMessage*)msg {
    MessageLocationContent *content = msg.locationContent;
    CLLocationCoordinate2D location = content.location;
    NSString *url = content.snapshotURL;

    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.scale = [[UIScreen mainScreen] scale];
    options.showsPointsOfInterest = YES;
    options.showsBuildings = YES;
    options.region = MKCoordinateRegionMakeWithDistance(location, 360, 200);
    options.mapType = MKMapTypeStandard;
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];

    msg.downloading = YES;
    [snapshotter startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *e) {
        if (e) {
            NSLog(@"error:%@", e);
        }
        else {
            NSLog(@"map snapshot success");
            [[SDImageCache sharedImageCache] storeImage:snapshot.image forKey:url completion:nil];
        }
        msg.downloading = NO;
    }];
}

-(void)reverseGeocodeLocation:(IMessage*)msg {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    MessageLocationContent *content = msg.locationContent;
    CLLocationCoordinate2D location = content.location;
    msg.geocoding = YES;
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *array, NSError *error) {
        if (!error && array.count > 0) {
           
        }
        msg.geocoding = NO;
    }];
}

- (void)wrapperMessages:(NSArray *)messages {
    int count = (int)messages.count;
    [self downloadMessageContent:messages count:count];
    [self updateNotificationDesc:messages count:count];
    [self checkMessageFailureFlag:messages count:count];
    [self loadSenderInfo:messages count:count];
    [self checkMessageFailureFlag:messages count:count];
    [self checkAtName:messages count:count];
}

#pragma mark - TODO
// 从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid {
   IUser *u = [[IUser alloc] init];
   u.uid = uid;
   u.name = @"";
   u.avatarURL = @"http://api.gobelieve.io/images/e837c4c84f706a7988d43d62d190e2a1.png";
   u.identifier = [NSString stringWithFormat:@"uid:%lld", uid];
   return u;
}

//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        IUser *u = [[IUser alloc] init];
        u.uid = uid;
        u.name = [NSString stringWithFormat:@"name:%lld", uid];
        u.avatarURL = @"http://api.gobelieve.io/images/e837c4c84f706a7988d43d62d190e2a1.png";
        u.identifier = [NSString stringWithFormat:@"uid:%lld", uid];
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(u);
        });
    });
}

-(void)updateConversationName:(Conversation*)conversation {
    if (conversation.type == CONVERSATION_PEER) {
        IUser *u = [self getUser:conversation.cid];
        if (u.name.length > 0) {
            conversation.name = u.name;
            conversation.avatarURL = u.avatarURL;
        } else {
            conversation.name = u.identifier;
            conversation.avatarURL = u.avatarURL;
            [self asyncGetUser:conversation.cid cb:^(IUser *u) {
                conversation.name = u.name;
                conversation.avatarURL = u.avatarURL;
            }];
        }
    } else if (conversation.type == CONVERSATION_GROUP) {
//        IGroup *g = [self.groupDelegate getGroup:conversation.cid];
//        if (g.name.length > 0) {
//            conversation.name = g.name;
//            conversation.avatarURL = g.avatarURL;
//        } else {
//            conversation.name = g.identifier;
//            conversation.avatarURL = g.avatarURL;
//
//            [self asyncGetGroup:conversation.cid cb:^(IGroup *g) {
//                conversation.name = g.name;
//                conversation.avatarURL = g.avatarURL;
//            }];
//        }
    }
}

- (void)updateConversationDetail:(Conversation*)conv {
    conv.timestamp = conv.message.timestamp;
    if (conv.message.type == MESSAGE_IMAGE) {
        conv.detail = @"一张图片";
    }else if(conv.message.type == MESSAGE_TEXT){
        MessageTextContent *content = conv.message.textContent;
        conv.detail = content.text;
    }else if(conv.message.type == MESSAGE_LOCATION){
        conv.detail = @"一个地理位置";
    }else if (conv.message.type == MESSAGE_AUDIO){
        conv.detail = @"一个音频";
    } else if (conv.message.type == MESSAGE_GROUP_NOTIFICATION) {
        [self updateConvNotificationDesc:conv];
    }
}

- (void)updateConvNotificationDesc:(Conversation*)conv {
    IMessage *message = conv.message;
    if (message.type == MESSAGE_GROUP_NOTIFICATION) {
        MessageGroupNotificationContent *notification = (MessageGroupNotificationContent*)message.notificationContent;
        int type = notification.notificationType;
        if (type == NOTIFICATION_GROUP_CREATED) {
            if (self.currentUID == notification.master) {
                NSString *desc = [NSString stringWithFormat:@"您创建了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
                conv.detail = notification.notificationDesc;
            } else {
                NSString *desc = [NSString stringWithFormat:@"您加入了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
                conv.detail = notification.notificationDesc;
            }
        } else if (type == NOTIFICATION_GROUP_DISBANDED) {
            notification.notificationDesc = @"群组已解散";
            conv.detail = notification.notificationDesc;
        } else if (type == NOTIFICATION_GROUP_MEMBER_ADDED) {
            IUser *u = [self getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
                conv.detail = notification.notificationDesc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
                conv.detail = notification.notificationDesc;
                [self asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@加入群", u.name];
                    notification.notificationDesc = desc;
                    //会话的最新消息未改变
                    if (conv.message == message) {
                        conv.detail = notification.notificationDesc;
                    }
                }];
            }
        } else if (type == NOTIFICATION_GROUP_MEMBER_LEAVED) {
            IUser *u = [self getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
                conv.detail = notification.notificationDesc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
                conv.detail = notification.notificationDesc;
                [self asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@离开群", u.name];
                    notification.notificationDesc = desc;
                    //会话的最新消息未改变
                    if (conv.message == message) {
                        conv.detail = notification.notificationDesc;
                    }
                }];
            }
        } else if (type == NOTIFICATION_GROUP_NAME_UPDATED) {
            NSString *desc = [NSString stringWithFormat:@"群组更名为%@", notification.groupName];
            notification.notificationDesc = desc;
            conv.detail = notification.notificationDesc;
        }
    }
}
@end

