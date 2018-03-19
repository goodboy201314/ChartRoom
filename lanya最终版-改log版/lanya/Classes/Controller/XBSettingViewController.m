//
//  XBSettingViewController.m
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBSettingViewController.h"
#import "XBSettingIconCell.h"
#import "XBSettingRmbCell.h"
#import "XBSettingAutoLoginCell.h"
#import "XBSettingQuitCell.h"
#import "AppDelegate.h"

@interface XBSettingViewController ()

@end

@implementation XBSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 第一个分组和顶部有默认35的距离，太丑，把它干掉
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.sectionFooterHeight-35, 0, 0, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
// 多少组  2组
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

// 每组多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0) return 1;
    else return 3;
}

// 每行显示什么内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if(indexPath.section==0) {  //第一组
        return [tableView dequeueReusableCellWithIdentifier:@"iconCell"];
    } else {  // 第二组
        if(indexPath.row ==0) {  // 记住用户名
            return [self createRmbCellWithTableView:tableView];
        } else if(indexPath.row==1) { // 自动登录
            return [self createAutoLoginCellWithTableView:tableView];
        } else {  // 退出
            return [self createQuitCellWithTableView:tableView];
        }
    }
    
}

// 行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section==0) return 140;
    else return 60;
}

#pragma mark - 记住用户名Cell相关
// 创建记住用户名的cell
- (XBSettingRmbCell *)createRmbCellWithTableView:(UITableView *)tableView
{
    // 1.创建cell
    XBSettingRmbCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rmbCell"];
    
    // 2.赋值
     NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
     cell.rmbBlock = ^(BOOL isOn){
       
        if(isOn == YES) {  // 如果记住名字
            [userDefaults setBool:YES forKey:@"rmb"];
            [userDefaults setObject:self.userName forKey:@"name"];
        } else {  // 如果不记住名字，那么不可以自动登录
            [userDefaults setBool:NO forKey:@"rmb"];
            [userDefaults setBool:NO forKey:@"autoLogin"];
            // 设置自动登录为no
            UISwitch *autoLoginSwitch = (UISwitch *)[self.view viewWithTag:300];
            [autoLoginSwitch setOn:NO animated:YES];
        }
        [userDefaults setBool:YES forKey:@"isSetted"];
    };
    
    if([userDefaults boolForKey:@"isSetted"]) {  // 如果用户设置了
        BOOL b = [userDefaults boolForKey:@"rmb"];
        cell.rmbSwitch.on = b;
    }
    
    // 3.返回
    return cell;
}

#pragma mark - 自动登录Cell相关
// 创建自动登录的cell
- (XBSettingAutoLoginCell *)createAutoLoginCellWithTableView:(UITableView *)tableView
{
    // 1.创建cell
    XBSettingAutoLoginCell *cell = [tableView dequeueReusableCellWithIdentifier:@"autoLoginCell"];
    
    // 2.赋值
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    cell.autoLoginBlock =  ^(BOOL isOn){
        
        if(isOn ==YES) {  // 如果自动登录，那么记住用户的名字
            [userDefaults setBool:YES forKey:@"autoLogin"];
            [userDefaults setBool:YES forKey:@"rmb"];
            [userDefaults setObject:self.userName forKey:@"name"];
            // 设置记住用户名称为yes
            UISwitch *rmbSwitch = (UISwitch *)[self.view viewWithTag:200];
            [rmbSwitch setOn:YES animated:YES];
        } else {
            [userDefaults setBool:NO forKey:@"autoLogin"];
        }
        [userDefaults setBool:YES forKey:@"isSetted"];
    };
    
    if([userDefaults boolForKey:@"isSetted"]) {  // 如果用户设置了
        BOOL b = [userDefaults boolForKey:@"autoLogin"];
        cell.autoLoginSwitch.on = b;
    } else cell.autoLoginSwitch.on = NO;

    // 3.返回
    return cell;
}


#pragma mark - 退出程序Cell相关
// 创建退出程序的cell
- (XBSettingQuitCell *)createQuitCellWithTableView:(UITableView *)tableView
{
    // 1.创建cell
    XBSettingQuitCell *cell = [tableView dequeueReusableCellWithIdentifier:@"quitCell"];
    
    // 2.设置点击按钮的block
    cell.quitBlock = ^(){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"确定要退出么?" preferredStyle:UIAlertControllerStyleActionSheet];
        
        // 确定按钮
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            // 退出程序
            [self exitApplication];
        }]];
        // 取消按钮
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        // 显示
        [self presentViewController:alert animated:YES completion:nil];
    };
    
    // 3.返回cell
    return cell;
}

// 退出程序
- (void)exitApplication{
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIWindow *window = app.window;
    
    [UIView animateWithDuration:1.0f animations:^{
        window.alpha = 0;
        window.frame = CGRectMake(0, window.bounds.size.width, 0, 0);
    } completion:^(BOOL finished) {
        exit(0);
    }];
}


@end
