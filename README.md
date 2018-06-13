# RepairKit
来自WCDB的sqlite修复工具，感谢WCDB这个优秀的开源库。

## 快速开始

### 准备工作

1. 把`RepairKit`文件夹拖入你的工程
2. 在`Build Settings`的`Other Linker Flags`中加入，`-ObjC`/`-force_load`/`./RepairKit路径/sqlcipher.framework/sqlcipher`这三项。
3. 在需要调用的类中`#import "WCRepairKitManage.h"`

### 备份数据库元数据

传入数据库路径即可完成备份。
```
BOOL isSuccess = [[WCRepairKitManage shareManage] backupDBPath:repairDBPath];
```
在有备份的情况，修复工具才可以生效。在数据库内的数据发生变化时，元数据备份有可能会过期。因此建议在子线程定期对其备份。

> 元数据通常只有几 kb 大小，且属于读操作，可以与其他操作并发执行。因此备份不会对性能产生大的影响。



### 修复数据库

传入数据库路径即可完成备份。

```
BOOL isSuccess = [[WCRepairKitManage shareManage] recoveryDBPath:repairDBPath DBPageSize:4096];
```

它将尝试从已损坏的数据库中读出数据，并插入到新数据库中。

修复过程根据数据库的大小不同，需要一定的时间。建议在界面上提示等待，并在子线程进行修复。

> 对于可再生的数据，如可从服务端重新拉取的数据，直接将数据库删掉重建是更好的恢复手段。

### 加密备份元数据文件

暂缺说明

## 来源

RepairKit来自[WCDB](https://github.com/Tencent/wcdb/wiki/iOS-macOS%e4%bd%bf%e7%94%a8%e6%95%99%e7%a8%8b)，因不属于对外接口，所以我通过参考Sample内的实现，完成了这个Demo。

## Sqlite修复原理

[微信 SQLite 数据库损坏恢复实践](https://pic.huodongjia.com/ganhuodocs/2017-06-26/1498444095.27.pdf)

[微信 SQLite 数据库修复实践](https://mp.weixin.qq.com/s?__biz=MzAwNDY1ODY2OQ%3D%3D&mid=2649286467&idx=1&sn=ea5b6dbfecffd33e333ec814473e1313&chksm=8334c3c1b4434ad7c364ff3acae1e62bc5e871a7350aa9cdcb24bd299b42875f0b020acb3620)

[微信移动端数据库组件WCDB系列（二） — 数据库修复三板斧](https://mp.weixin.qq.com/s/EV48e_VKFHd8F-96TbZ1rg)

[WCDB 损坏、备份、修复](https://github.com/Tencent/wcdb/wiki/Swift-%E6%8D%9F%E5%9D%8F%E3%80%81%E5%A4%87%E4%BB%BD%E3%80%81%E4%BF%AE%E5%A4%8D)

