//
//  AddFriendController.m
//  caonima
//
//  Created by apple on 16/4/20.
//  Copyright © 2016年 Gaooof. All rights reserved.
//

#import "AddFriendController.h"
#import "ReactiveCocoa.h"
#import "Music.h"
@interface AddFriendController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,weak) UITextField *search;
@property (nonatomic,strong) NSArray *musices;
@end

@implementation AddFriendController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupSearch];
    [self setupTableView];
    
    
       
    @weakify(self)
    
    [[[self.search.rac_textSignal
    doNext:^(NSString *x) {
        @strongify(self)
        if (x.length>2) {
            self.search.backgroundColor=[UIColor whiteColor];
        }else{
            self.search.backgroundColor = [UIColor yellowColor];
        }
    }]
       throttle:1]
        subscribeNext:^(NSString *x) {
            [[XMPPTool sharedXMPPTool] searchFriendText:x result:^(id friends) {
                @strongify(self)
                NSLog(@"%@",[NSThread currentThread]);
                self.musices = friends;
                [self.tableView reloadData];
            }];

    } error:^(NSError *error) {
        NSLog(@"%@",error);
    }];
}

/**
 *  异步加载图片
 */
-(RACSignal *)signalForImage:(NSString *)imageUrl {
    RACScheduler *scheduler = [RACScheduler
                               schedulerWithPriority:RACSchedulerPriorityBackground];
    
    return [[RACSignal createSignal:^RACDisposable *(id subscriber) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        UIImage *image = [UIImage imageWithData:data];
        [subscriber sendNext:image];
        [subscriber sendCompleted];
        return nil;
    }]
    subscribeOn:scheduler];
}

- (BOOL)isValid:(NSString*)value {
    return value.length > 3;
}
- (void)setupSearch {
    UITextField *search = [[UITextField alloc] init];
    search.frame=CGRectMake(20, 100, 200, 44);
    [self.view addSubview:search];
    self.search=search;

}
- (void)setupTableView {
    self.tableView = [[UITableView alloc] init];
    self.tableView.frame = CGRectMake(0, 200, 320, 300);
    self.tableView.backgroundColor = [UIColor purpleColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.musices.count;
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
    
    Music *music = self.musices[indexPath.row];
    [[[[self signalForImage:music.image]
     takeUntil:cell.rac_prepareForReuseSignal]
    deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(UIImage *x) {
        cell.imageView.image = x;
    }];
    cell.textLabel.text = music.title;
    
    return cell;
}




@end
