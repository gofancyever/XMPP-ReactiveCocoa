//
//  ViewController.m
//  caonima
//
//  Created by apple on 16/4/19.
//  Copyright © 2016年 Gaooof. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"
#import "TestController.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *login;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //登陆过程
    RACSignal *validUsernameSignal = [self.username.rac_textSignal map:^id(NSString *value) {
        return @([self isUsernameTure:value]);
    }];
    
    RACSignal *validPasswordSignal = [self.password.rac_textSignal map:^id(NSString *value) {
        return @([self isPasswordTure:value]);
    }];
    
    RAC(self.username , backgroundColor) = [validUsernameSignal map:^id(NSNumber *value) {
        return [value boolValue]? [UIColor whiteColor] :[UIColor redColor];
    }];
    RAC(self.password , backgroundColor) = [validPasswordSignal map:^id(NSNumber *value) {
        return [value boolValue]? [UIColor whiteColor] :[UIColor redColor];
    }];
    
    RACSignal *loginActiveSignal = [RACSignal combineLatest:@[validPasswordSignal,validUsernameSignal] reduce:^id(NSNumber *usernameValid,NSNumber *passwordValid){
        return @([usernameValid boolValue] && [passwordValid boolValue]);
        
    }];
    __weak ViewController *myself=self;
    [loginActiveSignal subscribeNext:^(NSNumber *x) {
        myself.login.enabled=[x boolValue];
    }];
    
    [[[self.login rac_signalForControlEvents:UIControlEventTouchUpInside] deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id x) {
         [UserInfo sharedUserInfo].username=self.username.text;
         [UserInfo sharedUserInfo].password=self.password.text;
         [[XMPPTool sharedXMPPTool] login:^(XMPPToolLoginResult result) {
             [myself loginResult:result];
         }];
         
         
     }];
    
}

//处理登陆结果
- (void)loginResult:(XMPPToolLoginResult)result {
    switch (result) {
        case XMPPToolLoginSuccess:{
            NSLog(@"登陆成功");
            dispatch_async(dispatch_get_main_queue(), ^{
                TestController *testVC = [[TestController alloc] init];
                UINavigationController *navVC=[[UINavigationController alloc] initWithRootViewController:testVC];
                [UIApplication sharedApplication].keyWindow.rootViewController = navVC;
            });
        case XMPPToolConnectFailed:
//            NSLog(@"连接失败");
            break;
        case XMPPToolLoginFailed:
            NSLog(@"登陆失败");
            break;
        case XMPPToolConnectSuccess:
            NSLog(@"连接成功");
            break;
        default:
            break;
        }
    }
}

-(BOOL)isUsernameTure:(NSString *)text{
    return text.length>3;
}
-(BOOL)isPasswordTure:(NSString *)text{
    return text.length>2;
}
@end
