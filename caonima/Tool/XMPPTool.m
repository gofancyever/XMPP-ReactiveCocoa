//
//  XMPPTool.m
//  caonima
//
//  Created by apple on 16/4/19.
//  Copyright © 2016年 Gaooof. All rights reserved.
//

#import "XMPPTool.h"
#import "Music.h"
#import "AFNetworking.h"
#import "MJExtension.h"
@interface XMPPTool()<XMPPStreamDelegate,NSFetchedResultsControllerDelegate>{
    /**
     *  登陆结果block
     */
    XMPPLoginBlock _resultBlock;
    //电子名片存储
    XMPPvCardCoreDataStorage *_vCardStorage;
    //头像
    XMPPvCardAvatarModule *_vCardAvatar;
    //自动连接模块
    XMPPReconnect *_reconnect;
    //获取好友列表
    NSFetchedResultsController *_fetchedController;
    
    //聊天
//    XMPPMessageArchiving *_msgArchiving;
}
@property (nonatomic,strong,readonly) XMPPStream *xmppStream;
@end

@implementation XMPPTool

SingletonM(XMPPTool)


#pragma mark - 登陆
- (void)login:(XMPPLoginBlock)resultBlock {
    //开始连接服务器
    [self connectHost];
    //连接成功
    [[[self rac_signalForSelector:@selector(xmppStreamDidConnect:)]
      doNext:^(id x) {
        [self sendPwdToHost];
    }]
     subscribeNext:^(id x) {
        resultBlock(XMPPToolConnectSuccess);
    }];
    
    //登录成功
    [[[self rac_signalForSelector:@selector(xmppStreamDidAuthenticate:)]
      doNext:^(id x) {
        [self sendOnlineToHost];
    }]
     subscribeNext:^(id x) {
         resultBlock(XMPPToolLoginSuccess);
    }];
    
    //连接失败
    [[self rac_signalForSelector:@selector(xmppStreamDidDisconnect:withError:)]
     subscribeNext:^(id x) {
        resultBlock(XMPPToolConnectFailed);
    }];
    
    //授权失败
    [[[self rac_signalForSelector:@selector(xmppStream:didNotAuthenticate:)]
      doNext:^(id x) {
        [_xmppStream disconnect];
    }]
     subscribeNext:^(id x) {
        resultBlock(XMPPToolLoginFailed);
    }];
}


#pragma mark - 获取好友
- (void)loadFriend:(XMPPLoadFriendBlock)friendBlock {
    
    [self loadFriendModule];
    friendBlock(_fetchedController.fetchedObjects);
    [[self rac_signalForSelector:@selector(controllerDidChangeContent:)] subscribeNext:^(id x) {
        friendBlock(_fetchedController.fetchedObjects);
    }];
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{}

#pragma mark - 搜索好友 
- (void)searchFriendText:(NSString *)text result:(XMPPSearchFriendBlock)searchBlock {
    [[self signalForSearchWithText:text] subscribeNext:^(id x) {
        searchBlock(x);
    } error:^(NSError *error) {
        searchBlock(error);
    }];
;
}

#pragma mark - private Method
/**
 *  连接服务器
 */
- (void)connectHost{
    //初始化
    if (!_xmppStream) {
        [self setupXMPPModule];
    }
    //握手
    NSString *user = [UserInfo sharedUserInfo].username;
    XMPPJID *myJID = [XMPPJID jidWithUser:user domain:@"Ever-Never.local" resource:@"iphone" ];
    _xmppStream.myJID = myJID;
    // 设置服务器域名
    _xmppStream.hostName = @"Ever-Never.local";//不仅可以是域名，还可是IP地址
    
    // 设置端口 如果服务器端口是5222，可以省略
    _xmppStream.hostPort = 5222;

    // 连接
    NSError *err = nil;
    if(![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&err]){
        NSLog(@"%@",err);
    }
}
/**
 *  发送密码
 */
- (void)sendPwdToHost {
    NSError *err = nil;
    NSString *pwd = [UserInfo sharedUserInfo].password;
    [_xmppStream authenticateWithPassword:pwd error:&err];
    if (err) {
//        NSLog(@"%@",err);
    }

}
/**
 *  发送在线消息
 */
- (void)sendOnlineToHost {
    XMPPPresence *presence = [XMPPPresence presence];
    [_xmppStream sendElement:presence];
}


- (void)loadFriendModule {
    
    NSManagedObjectContext *context = [XMPPTool sharedXMPPTool].rosterStorge.mainThreadManagedObjectContext;
    
    NSFetchRequest *request=[NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    NSString *jid=[UserInfo sharedUserInfo].JID;
    //过滤
    NSPredicate *pre=[NSPredicate predicateWithFormat:@"streamBareJidStr=%@",jid];
    request.predicate=pre;
    //排序
    NSSortDescriptor *sort=[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    request.sortDescriptors=@[sort];
    
    _fetchedController=[[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    
    _fetchedController.delegate=self;
    
    NSError *error=nil;
    [_fetchedController performFetch:&error];
    if (error) {
        //        NSLog(@"%@",error);
    }

}

/**
 *  加载JSON
 */
- (RACSignal *)signalForSearchWithText:(NSString *)text {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        AFHTTPSessionManager *mgr = [AFHTTPSessionManager manager];
        NSMutableDictionary *parrameter = [NSMutableDictionary dictionary];
        parrameter[@"q"] = text;
        parrameter[@"count"] = @"10";
        [mgr GET:@"https://api.douban.com/v2/music/search" parameters:parrameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSArray *musices = [Music mj_objectArrayWithKeyValuesArray:responseObject[@"musics"]];
            [subscriber sendNext:musices];
            [subscriber sendCompleted];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];
    
}




/**
 *  初始化模块
 */
-(void)setupXMPPModule {
    
    _xmppStream = [[XMPPStream alloc] init];
    //名片
    _vCardStorage=[XMPPvCardCoreDataStorage sharedInstance];
    _vCard=[[XMPPvCardTempModule alloc] initWithvCardStorage:_vCardStorage];
    [_vCard activate:_xmppStream];
    //头像
    _vCardAvatar = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_vCard];
    [_vCardAvatar activate:_xmppStream];
    //自动连接
    _reconnect=[[XMPPReconnect alloc] init];
    [_reconnect activate:_xmppStream];
    
    //花名册模块
    _rosterStorge=[[XMPPRosterCoreDataStorage alloc] init];
    _roster=[[XMPPRoster alloc] initWithRosterStorage:_rosterStorge];
    [_roster activate:_xmppStream];
    
    //聊天模块
//    _msgStorage=[[XMPPMessageArchivingCoreDataStorage alloc] init];
//    _msgArchiving=[[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_msgStorage];
//    [_msgArchiving activate:_xmppStream];
    
    _xmppStream.enableBackgroundingOnSocket=YES;
    
    // 设置代理
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}





@end
