//
//  AmChartView.m
//  AmChartsLibrary
//
//  Created by Andrew on 5/5/14.
//  Copyright (c) 2014 Chimp Studios. All rights reserved.
//

#import "AmMobileChartView.h"
#import "AmCharts.h"

@interface AmMobileChartView()
@property (strong) JSContext *context;
@property (nullable, strong) void (^readyBlock)(AmMobileChartView*);
@property (assign) BOOL hasSetup;
@end

@implementation AmMobileChartView

@synthesize readyBlock;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    if (_hasSetup) {
        return;
    }

    self.hasSetup = YES;
    self.chartView = [[UIWebView alloc] initWithFrame:self.frame];
    [self addSubview:self.chartView];
    self.chartView.delegate = self;
	
	[self.chartView setBackgroundColor:[UIColor clearColor]];
	[self.chartView setOpaque:NO];
	
    [self.chartView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[_chartView]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(_chartView)]];
    [self addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[_chartView]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(_chartView)]];
    
    if (!self.templateFilepath) {
        NSURL *chartResourceBundleURL = [[NSBundle mainBundle] URLForResource:@"AmChartResources" withExtension:@"bundle"];
        if (chartResourceBundleURL) {
            NSBundle *bundle = [NSBundle bundleWithURL:chartResourceBundleURL];
            self.templateFilepath = [bundle pathForResource:@"chart" ofType:@"html" inDirectory:@"AmChartsWeb"];
        } else {
          //  NSLog(@"setup not completed");
            _hasSetup = NO;
            return;
        }
    }
    
    NSURL *localURL = [NSURL fileURLWithPath:self.templateFilepath];
    [self.chartView loadHTMLString:[NSString stringWithContentsOfFile:self.templateFilepath encoding:NSUTF8StringEncoding error:nil] baseURL:localURL];
	
	UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
	tapper.delegate = self;
	[_chartView addGestureRecognizer: tapper];
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setTemplateFilepath:(NSString *)templateFilepath
{
    if (_templateFilepath != templateFilepath) {
        _templateFilepath = templateFilepath;
        self.hasSetup = NO;
        [self setup];
    }
}

- (void)didTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
	[_chartView stringByEvaluatingJavaScriptFromString:@"getSelectedObject();"];
}

- (void)drawChart
{
    if (_chart && _isReady) {
        NSString *scrpt = [NSString stringWithFormat:@"generateChartWithJSONData(%@);", [_chart javascriptRepresentation]];
        [self.chartView stringByEvaluatingJavaScriptFromString:scrpt];
    } else if (_chart) {
        /*
#ifdef DEBUG
        NSLog(@"AmCharts is not ready yet!");
#endif
         */
        [self performSelector:@selector(drawChart) withObject:nil afterDelay:1.0];
         
    } else if (_isReady) {
#ifdef DEBUG
        NSLog(@"No chart has been assigned");
#endif
    }
}

- (void)drawChartWithCompletionHandler:(void (^)(AmMobileChartView*))handler{
	readyBlock = handler;
	[self drawChart];
}

#pragma mark -
#pragma mark - Setters
- (void)setChart:(id)chart
{
    if (![_chart isEqual:chart]) {
        
        // make sure this new object is of type AmChart or AmStockChart
        if ([[chart class] isSubclassOfClass:[AmChart class]] ||
            [[chart class] isSubclassOfClass:[AmStockChart class]]) {
            _chart = chart;
        } else {
#ifdef DEBUG
            NSLog(@"chart must inherit from AmChart or AmStockChart");
#endif
        }
    }
}

#pragma mark -
#pragma mark - AmChartViewExport
-(void)amChartsAreReady
{
    if (!_isReady) {
        self.isReady = YES;
        NSLog(@"AmCharts is ready!");
    }
}

#pragma mark -
#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"]; // Undocumented access to UIWebView's JSContext
    self.context[@"ios"] = self;
}
-(void)webViewDidFinishLoad:(UIWebView *)view{
    self.isReady = YES;

    self.context = [view valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"]; // Undocumented access to UIWebView's JSContext
    self.context[@"ios"] = self;
	
	if(readyBlock){
		readyBlock(self);
		readyBlock = nil;
	}
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
	if ([[[request URL] scheme] isEqualToString:@"myapp"]) {
		NSString *currentCountry = [[request URL] lastPathComponent];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"selectedMapCountry" object:currentCountry];
		return NO;
	}
	return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
	return YES;
}
#pragma mark -
#pragma mark - Layout / Resizing
/**
 calls through to AmCharts chart.validateNow();
 */
- (void)validateChart
{
    [self.chartView stringByEvaluatingJavaScriptFromString:@"chart.validateNow();"];
}

@end
