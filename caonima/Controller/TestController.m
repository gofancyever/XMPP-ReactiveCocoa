//
//  TestController.m
//  caonima
//
//  Created by apple on 16/4/19.
//  Copyright © 2016年 Gaooof. All rights reserved.
//

#import "TestController.h"
#import "AddFriendController.h"
#import "ReactiveCocoa.h"
@interface TestController ()
@property (nonatomic,copy) NSArray *friends;
@end

@implementation TestController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加" style:UIBarButtonItemStylePlain target:self action:@selector(addFriend)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    
    
    [[XMPPTool sharedXMPPTool] loadFriend:^(NSArray *friends) {
        NSLog(@"%ld",friends.count);
        self.friends=friends;
        [self.tableView reloadData];
    }];

    
    
}
- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)addFriend {
    AddFriendController *addFriend=[[AddFriendController alloc] init];
    [self.navigationController pushViewController:addFriend animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.friends.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //可重用标示符
    static NSString *ID=@"Cell";
    //让表哥从缓冲区查找可重用
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:ID];
    
    //如果没有找到可重用标示符
    if (cell==nil) {
        //实例化cell
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    XMPPUserCoreDataStorageObject *friend = self.friends[indexPath.row];
    cell.textLabel.text = friend.displayName;
    return cell;
}




@end
