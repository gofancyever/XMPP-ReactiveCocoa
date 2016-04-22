//
//  UserInfo.h
//  caonima
//
//  Created by apple on 16/4/19.
//  Copyright © 2016年 Gaooof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "(ARC,MRC)Singleton.h"
@interface UserInfo : NSObject
 SingletonH(UserInfo)
@property (nonatomic,copy) NSString *JID;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;
@property (nonatomic,copy) NSArray *userFriend;
@end
