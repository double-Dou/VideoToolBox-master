//
//  ViewController.m
//  音视频采集(系统方法)
//
//  Created by 赵旭鹏 on 2017/6/27.
//  Copyright © 2017年 赵旭鹏. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVCaptureManager.h"
#import "GPUImageCaptureManger.h"

@interface ViewController ()
@property (nonatomic, strong) AVCaptureManager * captureManager;
@property (nonatomic, strong) GPUImageCaptureManger * GPUcaptureManager;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (nonatomic, assign) BOOL isSystemCapture;
@property (nonatomic, assign) BOOL isGPUCapture;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.captureManager = [[AVCaptureManager alloc]initAVCaptureManagerWithViewController:self];
    self.captureManager.isCapturing = YES;
    self.isGPUCapture = NO;
    self.isSystemCapture = YES;
    
}
//切换美颜
- (IBAction)changeBeauity:(UIButton *)sender {
    if (sender.selected) {
        [self.GPUcaptureManager.backView removeFromSuperview];
        self.GPUcaptureManager = nil;
        self.captureManager = [[AVCaptureManager alloc]initAVCaptureManagerWithViewController:self];
        self.captureManager.isCapturing = YES;
        self.isSystemCapture = YES;
        self.isGPUCapture = NO;
        
    }else
    {
        [self.captureManager destoryCaptureSession];
        self.captureManager = nil;
        self.GPUcaptureManager = [[GPUImageCaptureManger alloc]initGPUImageCaptureManagerWithViewController:self];
        self.isSystemCapture = NO;
        self.isGPUCapture = YES;
    }
    self.cameraButton.selected = NO;
    sender.selected = !sender.selected;
}
//关闭开启采集
- (IBAction)getDataClick:(UIButton *)sender {
    if (self.isSystemCapture) {
        if (!sender.selected) {
            [self.captureManager destoryCaptureSession];
            self.captureManager = nil;
            self.cameraButton.selected = NO;
            
        }else
        {
            self.captureManager = [[AVCaptureManager alloc]initAVCaptureManagerWithViewController:self];
            self.captureManager.isCapturing = YES;
        }
    }
    if (self.isGPUCapture) {
        if (!sender.selected) {
            [self.GPUcaptureManager.videoCamera stopCameraCapture];
            [self.GPUcaptureManager.backView removeFromSuperview];
            self.GPUcaptureManager = nil;
            self.cameraButton.selected = NO;
        }else
        {
            self.GPUcaptureManager = [[GPUImageCaptureManger alloc]initGPUImageCaptureManagerWithViewController:self];
        }
    }
    sender.selected = !sender.selected;
}
//切换摄像头
- (IBAction)changeCameraClick:(UIButton *)sender {
    if (self.isSystemCapture) {
        if (self.captureManager) {
            [self.captureManager changeCamera];
        }else
        {
            return;
        }
    }
    if (self.isGPUCapture) {
        if (self.GPUcaptureManager) {
            [self.GPUcaptureManager changeCamera];
        }else
        {
            return;
        }
    }
    sender.selected = !sender.selected;
}

//点击屏幕聚焦
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    //设置点击屏幕聚焦
    [self.captureManager setfocusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:point];
}

@end
