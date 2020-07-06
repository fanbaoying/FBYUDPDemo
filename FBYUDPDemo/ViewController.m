//
//  ViewController.m
//  FBYUDPDemo
//
//  Created by fanbaoying on 2019/3/13.
//  Copyright © 2019年 fby. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define statusHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define navColor [UIColor colorWithRed:250/255.0 green:45/255.0 blue:40/255.0 alpha:1]

@interface ViewController ()<GCDAsyncUdpSocketDelegate>{
    NSTimer* timer;
    BOOL hasSended;
}

@property (strong, nonatomic)GCDAsyncUdpSocket * udpCLientSoket;
@property (strong, nonatomic)UITextView *messageTextView;

@end

#define udpPort 1025
#define udpHost @"255.255.255.255"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor colorWithRed:247/255.0 green:246/255.0 blue:246/255.0 alpha:1];
    self.navigationItem.title = @"UDP";
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _udpCLientSoket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:queue];
    NSError * error = nil;
    [_udpCLientSoket bindToPort:udpPort error:&error];
    [_udpCLientSoket enableBroadcast:true error:nil];
    
    UIButton *starScanBtn = [[UIButton alloc]initWithFrame:CGRectMake(30, statusHeight + 64, (SCREEN_WIDTH - 90) / 2, 40)];
    [starScanBtn addTarget:self action:@selector(starScan) forControlEvents:UIControlEventTouchUpInside];
    starScanBtn.backgroundColor = navColor;
    [starScanBtn setTitle:@"开始扫描" forState:0];
    [self.view addSubview:starScanBtn];
    
    UIButton *cancelScanBtn = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 90) / 2 + 60, statusHeight + 64, (SCREEN_WIDTH - 90) / 2, 40)];
    [cancelScanBtn addTarget:self action:@selector(cancelScan) forControlEvents:UIControlEventTouchUpInside];
    cancelScanBtn.backgroundColor = navColor;
    [cancelScanBtn setTitle:@"停止扫描" forState:0];
    [self.view addSubview:cancelScanBtn];
    
    self.messageTextView = [[UITextView alloc]initWithFrame:CGRectMake(30, statusHeight + 124, SCREEN_WIDTH - 60, SCREEN_HEIGHT - statusHeight - 144)];
    self.messageTextView.backgroundColor = [UIColor whiteColor];
    [self.messageTextView setEditable:NO];
    [self.view addSubview:_messageTextView];
}

- (void)starScan {
    
    [timer invalidate];
    timer = nil;
    
    [_udpCLientSoket beginReceiving:nil];

    NSOperationQueue* op=[NSOperationQueue mainQueue];
    [op addOperationWithBlock:^{
        self->timer =  [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendMsg) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self->timer forMode:NSDefaultRunLoopMode];
        
        NSString* rootdeviceinfo=[[NSUserDefaults standardUserDefaults] valueForKey:@"LastScanRootDevice"];
        //超时
        NSTimer* tmpTimer=[NSTimer scheduledTimerWithTimeInterval:rootdeviceinfo? 2:3 target:self selector:@selector(cancelScan) userInfo:nil repeats:false];
        [[NSRunLoop currentRunLoop] addTimer:tmpTimer forMode:NSDefaultRunLoopMode];
    }];
}
//停止扫描
-(void)cancelScan{
    [self showMessage:@"UDP 停止扫描"];
    [_udpCLientSoket pauseReceiving];
    //取消定时器
    [timer invalidate];
    timer = nil;
}

- (void) sendMsg {
    [self showMessage:@"UDP 开始扫描"];
    NSString *s = @"Are You Espressif IOT Smart Device?";
    NSLog(@"%@", s);
    NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
    [_udpCLientSoket sendData:data toHost:udpHost port:udpPort withTimeout:-1 tag:0];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    [self showMessage:@"UDP发送信息成功"];
    NSLog(@"UDP发送信息成功");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    [self showMessage:@"UDP发送信息失败"];
    NSLog(@"UDP发送信息失败");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    //取得发送端的ip和端口
    NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
    NSString *deviceAddress=[hostAddr componentsSeparatedByString:@":"].lastObject;
    
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"接收到%@的消息:%@",deviceAddress,dataStr);
    [self showMessage:[NSString stringWithFormat:@"接收到%@的消息:%@", deviceAddress, dataStr]];
}

- (void)showMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.messageTextView.text = [self.messageTextView.text stringByAppendingFormat:@"%@\n",message];
        [self.messageTextView scrollRectToVisible:CGRectMake(0, self.messageTextView.contentSize.height -15, self.messageTextView.contentSize.width, 10) animated:YES];
    });
    
}

@end
