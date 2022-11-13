## 背景

设计一个通用app远程提示升级的 SDK，~~能覆盖到iOS、Android平台~~。设计客户端和服务端交互的协议（接口协议文档，重点协议的扩展性、通用性、字段的定义职责明确等），客户端的主要模块设计，配置文件和程序包下载过程中的安全性。
时间：1~3天
交付内容：协议文档，设计文档，和可运行的SDK代码；



## 协议

### 请求

域名：jjappupdate.com

路径：/service/version_update

请求方法：Post

请求体举例：

```json
{
	"common": {
		"region": "CN",
		"device_id": "1825627186151208",
		"app_id": 1128,
		"os_version": "16.1",
		"device_platform": "iphone",
		"device_type": "iPhone12,3",
    "channel": "inhouse",
		"sdk_version": "1.2.3",
		"app_name": "JJAppUpdate",
		"app_version": "23.3.0",
		"build_number": "233001"
	},
	"custom": {
		"reserve": ""
	},
	"auth": {
		"sign": "3e57f6fc49f25dc673ff5b8faa1b590a",
		"random": "1668169199"
	}
}
```

> 上述字段为通用参数，不再描述。



### 响应

响应体：

| 字段        | 类型   | 必选/可选 | 说明                                   |
| ----------- | ------ | --------- | -------------------------------------- |
| has_update  | Int    | 必选      | 是否有更新                             |
| new_version | String | 可选      | 最新的版本号                           |
| open_url    | String | 必选      | 更新链接(直接下载/跳转 App Store 链接) |

> 一级字段的 status、message、extra 为标准结构，不再描述。

例如：

```json
{
    "extra":{
        "has_update":1,
        "new_version":"23.5.0",
        "open_url":"itms-services://?action=download-manifest&url=https://www.jjappupdate.com/ios/manifest.plist"
    },
    "message":"success",
    "status":0
}
```







## 技术方案

### 被动接收 or 主动拉取

版本更新的信息可以被动接收也可以主动拉去：

1. 如果是被动接收的话有两种方案，一种是 App 自己建立长链接，一种是系统提供的 Push 能力，在接收到更新通知后直接弹窗提示用户去更新或者通过红点的方式提示用户去主动检查更新；
2. 如果是主动拉取的话，可以在合适的时机去拉取，例如每次 App 启动、进入版本更新页面手动点击去检查更新，后续逻辑同上；

不过由于版本更新本身优先级不高，特别是对于线上包，为此而建立一条长链通道有点不值得（强制更新除外），基于以上考虑本 demo 采用了方法二。



### 接口请求

因为请求过程中需要带入设备信息、当前用户信息、版本号等信息，所以采用 POST 协议比较合适，接口的请求参数中包含了用户隐私数据，所以在传递需要进行加密，例如使用加盐+Hash 的方法（不过加密逻辑应该有网络库内部完成，业务方无感知）。



### 数据接收

返回的数据格式可以考虑使用 Protobuf，既提高了传输的安全性，也提高了 iOS 和 Android 的兼容性。

不过经了解 Protobuf 方案收益其实并不高，且由于方案比较复杂，所以本 demo 还是采用了 Json 格式。

端上理应建立一套与网络端协商好的模型文件(应该由脚本工具自动生成)，但限于时间本 demo 省略了这一步。



### 更新逻辑

如果检查结果是需要更新，有两种方式去更新：

1. 可以直接跳转到 App Store 的下载页面让用户去点击更新；
2. 如果是 Inhouse 包则可以按照官方提供的方式进行安装，即直接加载 plist 文件并安装。

由于客户端的更新代码其实是一样的，所以至于采用哪种方案可以直接交给服务端，客户端直接使用服务端传回的 url 进行更新即可。



### 集成方式

代码的集成方式也有两种：

1. 可以用 CocoaPods 将代码打包成一个 Pod 供业务方使用；
2. 也可以直接打包成静态库。

考虑到本功能的强业务性，以及为了方便后续的业务迭代，所以本 demo 采用了方案一。





### 测试方法

可以利用 Mac 自带的 Apache 服务在 Mac 上开启一个本地服务，将准备好的 json 文件放到服务的根目录，测试机里的 url 地址设置为 `http://<MacIP>/<fileName>` 即可。

测试结果录屏如下：


<iframe width=443 height=960 src="./Resources/JJAppUpdateDemo.mp4">