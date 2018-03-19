//
//  XBLoginViewController.m
//  lanya
//
//  Created by xiangbin on 2017/10/16.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBLoginViewController.h"
#import "XBConnectionViewController.h"

@interface XBLoginViewController ()
/** 用户头像的按钮 */
@property (weak, nonatomic) IBOutlet UIButton *iconBtn;
/** 用户名称 */
@property (weak, nonatomic) IBOutlet UITextField *accountField;
/** 登录按钮 */
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end

@implementation XBLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    // 登录用户的头像显示为圆形
    self.iconBtn.clipsToBounds=YES;
    self.iconBtn.layer.cornerRadius=self.iconBtn.frame.size.height / 2;
    // 设置登录按钮边框为椭圆形
    self.loginBtn.clipsToBounds = YES;
    self.loginBtn.layer.cornerRadius = 5;
    
    // 给账户按钮添加监听
    [self.accountField addTarget:self action:@selector(editChange:) forControlEvents:UIControlEventEditingChanged];
    
    // 判断用户的相关登录状态
    [self checkStates];
    // 如果文本框有值得话，那么登录按钮可用
    [self editChange:self.accountField];
}

// 判断用户的保存状态
- (void)checkStates
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([userDefaults boolForKey:@"isSetted"]) {
        if([userDefaults boolForKey:@"rmb"]) {  // 如果有记住用户名
            self.accountField.text = [userDefaults stringForKey:@"name"];
        }
        if([userDefaults boolForKey:@"autoLogin"]) { // 如果自动登录
            self.accountField.text = [userDefaults stringForKey:@"name"];
            [self performSegueWithIdentifier:@"jump" sender:nil];
        }
    
    } else {
         self.accountField.text = [userDefaults stringForKey:@"name"];
    }
 
}

// 文本框内容改变
- (void)editChange:(UITextField *)textField
{
    // 如果用户输入了名字，那么可以登录
    self.loginBtn.enabled = textField.text.length;
}

// 用户登录
- (IBAction)login:(id)sender {
    // 保存用户的名字
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.accountField.text forKey:@"name"];
}

// 跳转之前，要将用户的名字传递给下一个界面
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // 获得目标控制器
    XBConnectionViewController *vc = segue.destinationViewController;
    // 将用户的名字传递给目标控制器
    vc.userName = self.accountField.text;
}


// 触碰屏幕其他地方，键盘退出
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}
@end
