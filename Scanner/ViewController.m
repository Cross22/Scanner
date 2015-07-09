//
//  ViewController.m
//  Scanner
//
//  Created by Grubert, Marco on 7/8/15.
//  Copyright (c) 2015 Grubert, Marco. All rights reserved.
//

#import "ViewController.h"
@import AVFoundation;

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong)   AVCaptureSession *captureSession;
@property (nonatomic, strong)   AVCaptureVideoPreviewLayer* previewlayer;
@property (nonatomic, strong)   NSMutableString* text;
@property (nonatomic, assign)   unsigned total;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.text= [NSMutableString new];
    
    self.textView.text= self.text;
    [self startPreview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) rotatePreview: (AVCaptureVideoOrientation) orientation
{
    self.previewlayer.connection.videoOrientation= orientation;
    self.previewlayer.bounds= self.preview.layer.bounds;
}

- (void)viewDidLayoutSubviews {
    [self rotatePreview:(AVCaptureVideoOrientation) [UIApplication sharedApplication].statusBarOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self rotatePreview:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (void)startPreview {
    self.captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice                                                                            error:&error];
    AVCaptureMetadataOutput *metaOutput = [[AVCaptureMetadataOutput alloc] init];
    if (videoInput && metaOutput) {
        [self.captureSession addInput:videoInput];
        [self.captureSession addOutput:metaOutput];
        self.previewlayer= [AVCaptureVideoPreviewLayer
                                                   layerWithSession:self.captureSession];
        self.previewlayer.frame= self.preview.frame;
        [self.preview.layer addSublayer:self.previewlayer];

        metaOutput.metadataObjectTypes= @[
                                          AVMetadataObjectTypeUPCECode,
                                          AVMetadataObjectTypeCode39Code,
                                          AVMetadataObjectTypeCode39Mod43Code,
                                          AVMetadataObjectTypeEAN13Code,
                                          AVMetadataObjectTypeEAN8Code,
                                          AVMetadataObjectTypeCode93Code,
                                          AVMetadataObjectTypeCode128Code,
                                          AVMetadataObjectTypePDF417Code,
                                          AVMetadataObjectTypeQRCode,
                                          AVMetadataObjectTypeAztecCode,
                                          AVMetadataObjectTypeInterleaved2of5Code,
                                          AVMetadataObjectTypeITF14Code,
                                          AVMetadataObjectTypeDataMatrixCode
                                          ];
        [metaOutput setMetadataObjectsDelegate:self
                                         queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    }
    else {
        NSLog(@"%@", [error description]);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // slow start up- put on background thread
        [self.captureSession startRunning];
    });
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    AVMetadataMachineReadableCodeObject* obj= [metadataObjects lastObject];
    NSString* str= obj.stringValue;
    if (!str)
        return; // happens when capture is paused
    const char* cstr=[str cStringUsingEncoding:NSUTF8StringEncoding];
    int sum=0;
    for (int index=0; index<str.length; ++index) {
        sum= cstr[index];
    }
    static int lastSum=-1;
    if (sum==lastSum) {
//        return; // nothing changed
    }
    lastSum= sum;
    _total += sum % 10 ;
    // Pause capturing for a second
    connection.enabled= NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        connection.enabled= YES;
    });
    [self.text appendString:[NSString stringWithFormat:@"$ %d.00\n", sum%10]];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text= self.text;
        self.textView.textAlignment= NSTextAlignmentRight;
        self.totalView.text=[NSString stringWithFormat:@"$ %d.00\n", self.total];
    });
}

@end
