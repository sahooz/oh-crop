## 💡 简介

oh-crop: OpenHarmony/HarmonyOS上的简单的图片剪裁库，可用于头像剪裁等常见场景。

代码仓库：[oh-crop](https://github.com/sahooz/oh-crop)

效果预览：  
![](./images/sample.gif)

## ⚙️ 下载安装

```shell
ohpm i @xinyansoft/oh-crop
```

OpenHarmony ohpm 环境配置等更多内容，请参考: [下载安装三方库](https://ohpm.openharmony.cn/#/cn/help/downloadandinstall)

## ✍️ 使用

- 定义CropModel对象  

``` typescript
@State private model: CropModel = new CropModel()
  .setFrameWidth(1000)
    // 如果要矩形取景框，把这个设置删掉
  .setEllipseFrame(true)
    // 如果要圆形，把比例设置成1
  .setFrameRatio(0.8);

...
  
private updateModel(src : string) {
  this.model.setImage(src)
    .setFrameWidth(1000)
      // 如果要矩形取景框，把这个设置删掉
    .setEllipseFrame(true)
      // 如果要圆形，把比例设置成1
    .setFrameRatio(0.8);
}
```

- 使用CropView  

```typescript
CropView({
  model: this.model,
})
  .layoutWeight(1)
  .width('100%')
```  
CropView仅仅包含图片的显示和手势操作、遮罩、取景框。


- 剪裁  

```typescript
let pm = await this.model.crop();
```

- 使用得到的PixelMap去实现你的业务逻辑

## 🎗️ CropModel支持的配置项

```typescript
/**
* 图片uri
* 类型判断太麻烦了，先只支持string，其他形式的需要先转换成路径
*/
src: string = '';
/**
* 图片预览
*/
previewSource: string | Resource = '';
/**
* 是否可以拖动
*/
panEnabled: boolean = true;
/**
* 是否可以缩放
*/
zoomEnabled: boolean = true;
/**
* 取景框宽度
*/
frameWidth = 1000;
/**
* 取景框宽高比
*/
frameRatio = 1;
/**
 *  取景框是否椭圆/圆形
 */
ellipseFrame: boolean = false;
/**
* 遮罩颜色
*/
maskColor: string = '#AA000000';
/**
* 取景框边框颜色
*/
strokeColor: string = '#FFFFFF';
/**
* 图片加载监听
*/
imageLoadEventListener: ImageLoadEventListener | null = null;
```  

CropModel设置也支持setter链式调用。

## ⚠️ 局限性及注意事项

- 椭圆或者圆形取景框仅为视觉效果，剪裁的结果仍然是矩形图片
- 暂不支持旋转

> 如果确实有较多的以上两种情况的需求，后续再考虑支持  
> 欢迎PR，人人为我，我为人人

## 📱 更多

我开发的其他鸿蒙库：
1. [oh-topic-editor](https://ohpm.openharmony.cn/#/cn/detail/@xinyansoft%2Foh-topic-editor): OpenHarmony & HarmonyOS平台上基于RichEditor实现的支持添加话题、@用户的文本编辑组件。
2. [oh-date-picker](https://ohpm.openharmony.cn/#/cn/detail/@xinyansoft%2Foh-date-picker): OpenHarmony & HarmonyOS平台日期选择器增强版。

我的博客：https://blog.xinyanruanjian.com/

我的公众号：程序员吹白  
![](images/plat.jpg)

鸿蒙开发交流QQ群：546723002

## 🌐 开源协议

MIT
