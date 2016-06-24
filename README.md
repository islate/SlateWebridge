SlateWebridge
========

原生代码与网页JS之间互相调用的一种机制，支持同步/异步调用。

# 1 定义

## 1.1 原生代码调用网页内的js函数，并获得返回值。

	可调用的js函数格式约定:
		同步返回
			参数个数：一个
			参数类型：{object}
			返回值：  {object} 或 void
		
		异步返回
			方法名: 带有_async后缀
			参数个数: 两个
			参数1类型: {object}
			参数2类型: {function}    function (result)  result 返回值 {object}类型
			返回值:   void

## 1.2 网页内的js函数调用原生代码，传递方法名、参数、回调函数。通过回调函数获得返回值。

	可调用的原生方法约定：
		同步返回
			参数个数：一个
			参数类型：{object}
			返回值：  {object} 或 void
	
		异步返回
			参数个数：两个
			参数1类型：{object}
			参数2类型：block     void (^)(id result, NSError *error)
			返回值：   void

	回调js函数格式约定：
		参数个数：两个
		参数1类型：{object}  result  原生方法的返回值,json对象
		参数2类型：{string}  error   错误信息字符串象
		返回值：  void

# 2 适合场景

混合式App(Native + Web)开发

# 3 Usage

## 3.1 实现WebridgeHandler

	@implementation WebridgeHandler

	- (void)nativeCommand:(id)params completion:(SlateWebridgeCompletionBlock)completion webView:(UIWebView *)webView
	{
		// todo: 得到结果后调用 completion(result, error);
	}
    
	@end

## 3.2 注册WebridgeHandler

	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

        // 注册WebridgeHandler
	[[SlateWebridge sharedBridge] setPriorHandler:[WebridgeHandler new]];

## 3.3 js调用原生代码，并异步得到返回值

	webridge.jsToNative('nativeCommand', {'param':'value'}, function (result, error) {
		if (error.length > 0) {
			// 有错误，显示错误信息
		}
		else {
			// 没有错误，得到结果 result
		}
	});

## 3.4 原生代码调用js，并异步得到返回值

	[self.webView evalJSCommand:@"jsObject.jsCommand" jsParams:@{@"param": @"value"} 
			completionHandler:^(id result, NSError *error) {
				if (error) {
					// 有错误，显示错误信息
				}
				else {
					// 没有错误，得到结果 result
				}
			}];
	
	网页中相关js函数的实现，异步方式：
	jsObject.jsCommand_async = function(params, callback) {
		// todo: 得到结果result后，调用  callback(result);
	};
	
	同步方式:
	jsObject.jsCommand = function(params) {
		// todo: 得到结果result
		return result;
	};

# 4 引入

	pod 'SlateWebridge'

