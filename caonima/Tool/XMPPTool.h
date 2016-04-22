//
//  XMPPTool.h
//  caonima
//
//  Created by apple on 16/4/19.
//  Copyright © 2016年 Gaooof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "(ARC,MRC)Singleton.h"
#import "XMPPFramework.h"
#import "ReactiveCocoa.h"
typedef NS_ENUM(NSInteger,XMPPToolLoginResult) {
    
    XMPPToolLoginSuccess , //登陆成功
    XMPPToolLoginFailed , //登陆失败
    XMPPToolConnectSuccess, //连接成功
    XMPPToolConnectFailed //连接失败
};


typedef void (^XMPPLoginBlock)(XMPPToolLoginResult type);
typedef void (^XMPPLoadFriendBlock)(NSArray *friends);
typedef void (^XMPPSearchFriendBlock)(id friends);

@interface XMPPTool : NSObject

SingletonH(XMPPTool)

/**
 *  登陆
 */
- (void)login:(XMPPLoginBlock)resultBlock;
/**
 *  加载好友
 */
- (void)loadFriend:(XMPPLoadFriendBlock)friendBlock;
/**
 *  搜索好友
 */
- (void)searchFriendText:(NSString *)text result:(XMPPSearchFriendBlock)searchBlock;
/**
 *  名片存储
 */
@property (nonatomic,strong,readonly)XMPPRosterCoreDataStorage *rosterStorge;
//名片
@property (nonatomic,strong,readonly) XMPPvCardTempModule *vCard;
@property (nonatomic,strong,readonly) XMPPRoster *roster;
@end
