//
//  XBChatRoomViewController.h
//  lanya
//
//  Created by xiangbin on 2017/10/17.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XBChatRoomViewController;

// 定义代理协议
@protocol XBChatRoomViewControllerDelegate <NSObject>
@optional
- (void)chatRoomViewController:(XBChatRoomViewController*)chatRoomViewController didSendMessage:(NSString *)message;
@end

@interface XBChatRoomViewController : UIViewController
/**  登录用户的名字  */
@property (nonatomic,copy) NSString* userName;
/**  代理  */
@property (nonatomic,weak) id delegate;

// 接收信息
- (void)receiveMessage:(NSString *)message fromUser:(NSString *)name;
@end
