//
//  XBChatRoomViewController.m
//  lanya
//
//  Created by xiangbin on 2017/10/17.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBChatRoomViewController.h"
#import "XBSettingViewController.h"
#import "XBMessage.h"
#import "XBMessageCell.h"

@interface XBChatRoomViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UITextField *textField;

/**  设置控制，用来控制开关的状态*/
@property (nonatomic,strong) XBSettingViewController* settingVC;
/**  所有数据的数组  */
@property (nonatomic,strong) NSMutableArray* messages;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;


@end

@implementation XBChatRoomViewController
- (NSMutableArray *)messages
{
    if(!_messages) {
        _messages = [NSMutableArray array];
    }
    return _messages;
}

#pragma mark - UITableView的相关数据源方法和代理方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

// 1.
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

// 2.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 获取模型数据
    XBMessage *message = self.messages[indexPath.row];
    // 创建cell
    XBMessageCell *cell = nil;
    if(message.type == XBMessageTypeMe) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"me"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"other"];
    }
    cell.message = message;
    return cell;
}

// 3.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XBMessage *message = self.messages[indexPath.row];
    return message.cellHeight;
}

//// 滚动时候，退出键盘
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    
//}
// 点击cell的时候退出编辑
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
}

#pragma mark - 发送信息
// 发送信息
- (IBAction)send:(id)sender {
    // 如果没有内容，那么不发送
    if([self.textField.text isEqualToString:@""]) return;
    [self sendMessage:self.textField.text];
    self.textField.text = @"";
}

// 发送信息
- (void)sendMessage:(NSString *)message
{
    // 显示在当前的页面上
    // 创建模型，并添加到模型数组
    XBMessage *msg = [XBMessage messageWithName:self.userName Content:message andType:XBMessageTypeMe];
    [self.messages addObject:msg];
    
    // 刷新表格
    [self.tableView reloadData];
    [self performSelector:@selector(scrollToFooter) withObject:nil afterDelay:.0];
    
    dispatch_async(dispatch_queue_create("com.xingbin.lanya.chatroom.queue", NULL), ^{
        // 通知代理
        if([self.delegate respondsToSelector:@selector(chatRoomViewController:didSendMessage:)]) {
            [self.delegate chatRoomViewController:self didSendMessage:message];
        }
    });

}

#pragma mark - 接收信息

// 接收到信息
- (void)receiveMessage:(NSString *)message fromUser:(NSString *)name
{
    // 显示在当前的页面上
    // 创建模型，并添加到模型数组
    XBMessage *msg = [XBMessage messageWithName:name Content:message andType:XBMessageTypeOther];
    [self.messages addObject:msg];
    
    // 刷新表格
    [self.tableView reloadData];
    [self performSelector:@selector(scrollToFooter) withObject:nil afterDelay:.0];
}

- (void)scrollToFooter {
    //    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:self.messages.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [self.tableView scrollRectToVisible:
     self.tableView.tableFooterView.frame animated:YES
     ];
}

#pragma mark - 界面加载以及跳转至设置界面
- (void)viewDidLoad {
    [super viewDidLoad];
    // 设置标题
    self.title = [NSString stringWithFormat:@"蓝牙聊天室 - %@",self.userName];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 10, 10)];

//    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
//    NSLog(@"%@",[NSValue valueWithCGRect: self.tableView.frame]);
    
    // 设置光标激励左端有一点距离，否则他难看
    // 创建⼀个没有⾼度的view
    UIView *leftView = [[UIView alloc] init];
    leftView.frame = CGRectMake(0, 0, 5, 0);
    self.textField.leftView = leftView;
    // 以下⼀定要设置， 否则没有效果
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    
    // 监听键盘的弹出和退下
    // 监听任何对象发出的键盘即将弹出的通知， 接收到的时候调⽤keyboardWillShow： ⽅法
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    // 监听任何对象发出的键盘即将弹出的通知， 接收到的时候调⽤keyboardWillHide： ⽅法
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

// 接收到键盘即将弹出的通知调⽤该⽅法
- (void)keyboardWillShow:(NSNotification *)note
{
    // userInfo[UIKeyboardFrameEndUserInfoKey]取出的是⼀个id类型的对象， 不可以直接“.属性”
    CGRect frame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGFloat constant = frame.size.height;
    self.bottomConstraint.constant = constant;
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

// 接收到键盘即将退出的通知调⽤该⽅法
- (void)keyboardWillHide:(NSNotification *)note
{
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    self.bottomConstraint.constant = 0;
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.settingVC = segue.destinationViewController;
    self.settingVC.userName = self.userName;
}



@end
