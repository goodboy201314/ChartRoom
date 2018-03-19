//
//  XBMessageCell.m
//  lanya
//
//  Created by xiangbin on 2017/10/18.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBMessageCell.h"
#import "XBMessage.h"
#import <CoreImage/CoreImage.h>
#define MAS_SHORTHAND
#define MAS_SHORTHAND_GLOBALS
#import "Masonry.h"

@interface XBMessageCell()
@property (weak, nonatomic) IBOutlet UIButton *iconBtn;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *contentBtn;

@end

@implementation XBMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // 登录用户的头像显示为圆形
    self.iconBtn.clipsToBounds=YES;
    self.iconBtn.layer.cornerRadius=self.iconBtn.frame.size.height / 2;
    // 发送的信息可以多行显示
    self.contentBtn.titleLabel.numberOfLines = 0;
}

- (void)setMessage:(XBMessage *)message
{
    _message = message;
    // 1.设置名字
    self.nameLabel.text = message.name;
    // 2.设置内容
    [self.contentBtn setTitle:message.content forState:UIControlStateNormal];
    // 3.设置用户的头像
    [self.iconBtn setBackgroundImage:[self createIconWithNane:message.name] forState:UIControlStateNormal];
    
    // 4.计算cell的高度
    // 强制更新
    [self layoutIfNeeded];
    [self.contentBtn updateConstraints:^(MASConstraintMaker *make) {
        CGFloat textHeight = self.contentBtn.titleLabel.bounds.size.height;
        make.height.equalTo(textHeight + 40);
    }];
    
    // 强制布局,计算当前cell的⾼度
    [self layoutIfNeeded];
    CGFloat btnMaxY = CGRectGetMaxY(self.contentBtn.frame);
    CGFloat labelMaxY = CGRectGetMaxY(self.nameLabel.frame);
    self.message.cellHeight = (btnMaxY > labelMaxY ? btnMaxY : labelMaxY) + 10;
    
}

// 创建用户的头像
- (UIImage *)createIconWithNane:(NSString *)name
{
    // 1.创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.恢复默认
    [filter setDefaults];
    
    // 3.给过滤器添加数据(正则表达式/账号和密码)
    NSString *dataString = name;
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    
    // 5.显示二维码
    return  [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:40];
}

/**
 *  根据CIImage生成指定大小的UIImage
 *
 *  @param image CIImage
 *  @param size  图片宽度
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

@end
