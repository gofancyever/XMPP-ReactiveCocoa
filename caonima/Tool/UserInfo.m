//
//  UserInfo.m
//  caonima
//
//  Created by apple on 16/4/19.
//  Copyright © 2016年 Gaooof. All rights reserved.
//

#import "UserInfo.h"

static NSString *domain = @"ever-never.local";

@implementation UserInfo
SingletonM(UserInfo)

-(NSString *)JID{
    
    return [NSString stringWithFormat:@"%@@%@",self.username,domain];
}

@end
