## 📚 简介 

oh-crop: OpenHarmony/HarmonyOS上的简单的图片剪裁库，可用于头像剪裁等常见场景。  

代码仓库：[oh-crop](https://github.com/sahooz/oh-crop)  

效果预览：  
![](./images/sample.gif)  

## 📚 下载安装

```shell
ohpm i @pura/harmony-utils
```

OpenHarmony ohpm 环境配置等更多内容，请参考: [下载安装三方库](https://ohpm.openharmony.cn/#/cn/help/downloadandinstall)  

## 📚 使用   

1. 定义CropModel对象 
``` typescript
@State private model: CropModel = new CropModel();
...  
this.model.setImage(src)
      .setFrameWidth(1000)
      .setFrameRatio(1);
```

2. 使用CropView 
```typescript
CropView({
  model: this.model,
})
  .layoutWeight(1)
  .width('100%')
```  
CropView仅仅包含图片的显示和手势操作、遮罩、取景框。


3. 剪裁
```typescript
let pm = await this.model.crop(image.PixelMapFormat.RGBA_8888);
```

4. 使用得到的PixelMap去实现你的业务逻辑  

## 📚 CropModel支持的配置项

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

CropModel设置是也支持setter链式调用。
