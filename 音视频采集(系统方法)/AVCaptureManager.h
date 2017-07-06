//
//  AVCaptureManager.h
//  音视频采集(系统方法)
//
//  Created by 赵旭鹏 on 2017/6/27.
//  Copyright © 2017年 赵旭鹏. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface AVCaptureManager : NSObject
//是否处理采集数据
@property(nonatomic, assign)BOOL isCapturing;
@property(nonatomic, strong)UIView *backView;
//对音视频采集管理类进行初始化
-(instancetype)initAVCaptureManagerWithViewController:(UIViewController *)viewController;
//销毁会话
-(void)destoryCaptureSession;
//切换摄像头
-(void)changeCamera;
//设置点击屏幕聚焦
-(void)setfocusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point;
@end
