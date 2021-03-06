//
//  SOPayViewController.m
//  PureSms
//
//  Created by YC X on 2018/8/6.
//  Copyright © 2018年 YC X. All rights reserved.
//

#import "SOPayViewController.h"
#import <StoreKit/StoreKit.h>
#import "SVProgressHUD.h"

#define BUNDLEID [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]
#define MERCHANT_PURESMS @"merchant.welightworld.puresms2"
#define MERCHANT_PURESMSPRO @"merchant.welightworld.puresmspro1"
#define PURESMS @"com.welightworld.puresms"
#define PURESMSPRO @"com.welightworld.puresmspro"
#define APPID @"1372766943"
#define APPIDPRO @"1387094960"

#define HEIGHT_DEVICE UIScreen.mainScreen.bounds.size.height

@interface SOPayViewController ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *VIPImageView;
@property (weak, nonatomic) IBOutlet UILabel *vipLabel;
@property (weak, nonatomic) IBOutlet UIButton *okBtn;
@property (weak, nonatomic) IBOutlet UIButton *freeBtn;
@property (weak, nonatomic) IBOutlet UILabel *noteLabel;
@property (weak, nonatomic) IBOutlet UIButton *gotoProBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation SOPayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadVipView];
    if (isShow) {
        self.noteLabel.hidden = NO;
        self.gotoProBtn.hidden = NO;
    }
    if ([BUNDLEID isEqualToString:PURESMSPRO]) {
        self.noteLabel.hidden = YES;
        self.gotoProBtn.hidden = YES;
        self.titleLabel.text = @"1元开通会员即可永久免费使用全部功能";
    }
    // 4.设置支付服务
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

/**
 显示转圈进度提示框
 */
- (void)showProgressViewWithTitle:(NSString *) title withIsMessageView:(BOOL) isMessageView
{
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    [SVProgressHUD setBackgroundColor:[UIColor lightGrayColor]];
    if (isMessageView) {
        [SVProgressHUD showImage:nil status:title];
        [SVProgressHUD setOffsetFromCenter:UIOffsetMake(0, HEIGHT_DEVICE/3)];
        [SVProgressHUD dismissWithDelay:3.0f];
    }
    else {
        [SVProgressHUD setOffsetFromCenter:UIOffsetMake(0, 0)];
        if (title.length) {
            [SVProgressHUD showWithStatus:title];
        }
        else {
            [SVProgressHUD show];
        }
    }
}

- (IBAction)gotoProBtn:(UIButton *)sender {
    
    NSString *urlStr = [NSString stringWithFormat:@"https://itunes.apple.com/cn/app/id%@", APPIDPRO];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr] options:nil completionHandler:^(BOOL success) {
    }];
}

- (IBAction)touchUpInsideBtn:(UIButton *)sender {
    
    if (sender.tag) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"VIP"]) {
            [self showProgressViewWithTitle:@"未发现您已购买过该徽章，请点击确认购买" withIsMessageView:YES];
            return;
        }
        else {
            [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
            [self showProgressViewWithTitle:@"恢复购买成功" withIsMessageView:YES];
            self.VIPImageView.hidden = NO;
            self.vipLabel.hidden = NO;
            return;
        }
    }
    if (!sender.tag) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"VIP"]) {
            [self showProgressViewWithTitle:@"您已购买过该徽章，请点击恢复购买" withIsMessageView:YES];
            return;
        }
    }
    
    NSArray* transactions = [SKPaymentQueue defaultQueue].transactions;
    if (transactions.count > 0) {
        //检测是否有未完成的交易
        SKPaymentTransaction* transaction = [transactions firstObject];
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            return;
        }
    }
    
    // 5.点击按钮的时候判断app是否允许apple支付
    //如果app允许applepay
    if ([SKPaymentQueue canMakePayments]) {
        NSLog(@"允许支付");
        // 6.请求苹果后台商品
        [self getRequestAppleProduct];
        [self showProgressViewWithTitle:@"" withIsMessageView:NO];
    }
    else {
        NSLog(@"不能支付");
    }
}

// 显示VIP
- (void)loadVipView
{
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"VIP1"]) {
//        [self.okBtn setTitle:@"恢复购买" forState:UIControlStateNormal];
//        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"VIP1"];
//        return;
//    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"VIP"]) {
        self.VIPImageView.hidden = NO;
        self.vipLabel.hidden = NO;
        //        self.vipLabel.text = [NSString stringWithFormat:@"VIP %ld", (long)tempInt];
//        self.okBtn.enabled = NO;
//        self.okBtn.backgroundColor = [UIColor lightGrayColor];
//        self.freeBtn.enabled = NO;
//        self.freeBtn.backgroundColor = [UIColor lightGrayColor];
    }
}

//请求苹果商品
- (void)getRequestAppleProduct
{
    // 7.这里的merchant.welightworld.puresms就对应着苹果后台的商品ID,他们是通过这个ID进行联系的。
    
    NSString *merchantStr = MERCHANT_PURESMS;
    if ([BUNDLEID isEqualToString:PURESMSPRO]) {
        merchantStr = MERCHANT_PURESMSPRO;
    }
    
    NSArray *product = [[NSArray alloc] initWithObjects:merchantStr,nil];
    
    NSSet *nsset = [NSSet setWithArray:product];
    
    // 8.初始化请求
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    request.delegate = self;
    
    // 9.开始请求
    [request start];
}

// 10.接收到产品的返回信息,然后用返回的商品信息进行发起购买请求
- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *product = response.products;
    NSLog(@"product == %d", product.count);
    //如果服务器没有产品
    if([product count] == 0){
        NSLog(@"请在苹果后台添加商品。");
        return;
    }
    
    SKProduct *requestProduct = nil;
    for (SKProduct *pro in product) {
        
        NSLog(@"商品返回信息1：%@", [pro description]);
        NSLog(@"商品返回信息2：%@", [pro localizedTitle]);
        NSLog(@"商品返回信息3：%@", [pro localizedDescription]);
        NSLog(@"商品返回信息4：%@", [pro price]);
        NSLog(@"商品返回信息5：%@", [pro productIdentifier]);
        
        // 11.如果后台消费条目的ID与我这里需要请求的一样（用于确保订单的正确性）
        if([pro.productIdentifier isEqualToString:MERCHANT_PURESMS] || [pro.productIdentifier isEqualToString:MERCHANT_PURESMSPRO]){
            requestProduct = pro;
        }
    }
    
    // 12.发送购买请求
    SKPayment *payment = [SKPayment paymentWithProduct:requestProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"请求失败-error:%@", error);
    [SVProgressHUD dismiss];
    [self showProgressViewWithTitle:[NSString stringWithFormat:@"%@", error.localizedDescription] withIsMessageView:YES];
}

//反馈请求的产品信息结束后
- (void)requestDidFinish:(SKRequest *)request{
    NSLog(@"信息反馈结束");
}

// 13.监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction{
    for(SKPaymentTransaction *tran in transaction){
        NSLog(@"transactionState == %@", tran.payment.applicationUsername);
        [SVProgressHUD dismiss];
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"交易完成");
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"VIP"];
                [self loadVipView];
//                [self completeTransaction:tran];
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"已经购买过商品");
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"VIP"];
                [self loadVipView];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"交易失败");
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            default:
                break;
        }
    }
}

// 14.交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户方法我们的虚拟物品了。
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [SVProgressHUD dismiss];
    NSLog(@"queue == %@", queue);
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"restoreCompletedTransactionsFailedWithError == %@, %@", error, queue);
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    NSString * str=[[NSString alloc]initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
    
    NSString *environment=[self environmentForReceipt:str];
    NSLog(@"----- 完成交易调用的方法completeTransaction 1--------%@",environment);
    
    
    // 验证凭据，获取到苹果返回的交易凭据
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    /**
     20      BASE64 常用的编码方案，通常用于数据传输，以及加密算法的基础算法，传输过程中能够保证数据传输的稳定性
     21      BASE64是可以编码和解码的
     22      */
    NSString *encodeStr = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    NSString *sendString = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
    NSLog(@"_____%@",sendString);
    NSURL *StoreURL=nil;
    if ([environment isEqualToString:@"environment=Sandbox"]) {
        
        StoreURL= [[NSURL alloc] initWithString: @"https://sandbox.itunes.apple.com/verifyReceipt"];
    }
    else{
        
        StoreURL= [[NSURL alloc] initWithString: @"https://buy.itunes.apple.com/verifyReceipt"];
    }
    //这个二进制数据由服务器进行验证；zl
    NSData *postData = [NSData dataWithBytes:[sendString UTF8String] length:[sendString length]];
    
    NSLog(@"++++++%@",postData);
    NSMutableURLRequest *connectionRequest = [NSMutableURLRequest requestWithURL:StoreURL];
    
    [connectionRequest setHTTPMethod:@"POST"];
    [connectionRequest setTimeoutInterval:50.0];//120.0---50.0zl
    [connectionRequest setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [connectionRequest setHTTPBody:postData];
    
    //开始请求
    NSError *error=nil;
    NSData *responseData=[NSURLConnection sendSynchronousRequest:connectionRequest returningResponse:nil error:&error];
    if (error) {
        NSLog(@"验证购买过程中发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"请求成功后的数据:%@",dic);
    //这里可以等待上面请求的数据完成后并且state = 0 验证凭据成功来判断后进入自己服务器逻辑的判断,也可以直接进行服务器逻辑的判断,验证凭据也就是一个安全的问题。楼主这里没有用state = 0 来判断。
    //  [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    NSString *product = transaction.payment.productIdentifier;
    
    NSLog(@"transaction.payment.productIdentifier++++%@",product);
    
    if ([product length] > 0)
    {
        NSArray *tt = [product componentsSeparatedByString:@"."];
        
        NSString *bookid = [tt lastObject];
        
        if([bookid length] > 0)
        {
            
            NSLog(@"打印bookid%@",bookid);
            //这里可以做操作吧用户对应的虚拟物品通过自己服务器进行下发操作,或者在这里通过判断得到用户将会得到多少虚拟物品,在后面（[self getApplePayDataToServerRequsetWith:transaction];的地方）上传上面自己的服务器。
        }
    }
    //此方法为将这一次操作上传给我本地服务器,记得在上传成功过后一定要记得销毁本次操作。调用[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
//    [self getApplePayDataToServerRequsetWith:transaction];
}

//结束后一定要销毁
- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

-(NSString * )environmentForReceipt:(NSString * )str
{
    str= [str stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
    str=[str stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    str=[str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    NSArray * arr=[str componentsSeparatedByString:@";"];
    
    //存储收据环境的变量
    NSString * environment=arr[2];
    return environment;
}

@end
