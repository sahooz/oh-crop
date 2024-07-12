import Matrix4 from '@ohos.matrix4'
import fs from '@ohos.file.fs';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { image } from '@kit.ImageKit';

@Component
export struct CropView {

  @State private model: CropModel = new CropModel();

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  @State private matrix: object = Matrix4.identity()
    .translate({ x: 0, y: 0 })
    .scale({ x: this.model.scale, y: this.model.scale});

  /** 临时变量，无需手动赋值 **/
  private tempScale = 1;
  /** 临时变量，无需手动赋值 **/
  private startOffsetX: number = 0;
  /** 临时变量，无需手动赋值 **/
  private startOffsetY: number = 0;

  build() {
    Stack() {
      Image(this.model.src)
        .width('100%')
        .height('100%')
        .alt(this.model.previewSource)
        .objectFit(ImageFit.Contain)
        .transform(this.matrix)
        .onComplete((msg) => {
          if (msg && msg.loadingStatus == 0) { // 图片加载成功
            this.model.imageWidth = msg.width;
            this.model.imageHeight = msg.height;
            this.model.componentWidth = msg.componentWidth;
            this.model.componentHeight = msg.componentHeight;
            if (this.model.imageLoadEventListener != null) {
              this.model.imageLoadEventListener.onImageLoaded(msg);
            }
            this.checkImageAdapt();
          }
        })
        .onError((error) => {
          if (this.model.imageLoadEventListener != null) {
            this.model.imageLoadEventListener.onImageLoadError(error);
          }
        })
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .onReady(() => {
          if (this.context == null) {
            return
          }

          let height = this.context.height
          let width = this.context.width
          this.context.fillStyle= this.model.maskColor;
          this.context.fillRect(0, 0, width, height)

          // 把中间的取景框透出来
          this.context.globalCompositeOperation = 'destination-out'
          this.context.fillStyle = 'white'
          let frameWidthInVp = px2vp(this.model.frameWidth);
          let frameHeightInVp = px2vp(this.model.getFrameHeight());
          let x = (width - px2vp(this.model.frameWidth)) / 2;
          let y = (height - px2vp(this.model.getFrameHeight())) / 2;
          this.context.fillRect(x, y, frameWidthInVp, frameHeightInVp)

          // 画出取景框边线，使边界明显一点
          this.context.globalCompositeOperation = 'source-over';
          this.context.strokeStyle = this.model.strokeColor;
          this.context.strokeRect(x, y, frameWidthInVp, frameHeightInVp)
        })
        .enabled(false)
    }
    .clip(true)
    .width('100%')
    .height('100%')
    .backgroundImage($r('app.media.crop_tile'), ImageRepeat.XY)
    .priorityGesture(
      TapGesture({ count: 2, fingers: 1 })
        .onAction((event:GestureEvent) => {
          if(!event){
            return
          }
          if (this.model.zoomEnabled) {
            if (this.model.scale != 1) {
              this.model.scale = 1;
              this.model.reset();
              this.updateMatrix();
            } else {
              this.zoomTo(2);
            }
          }

          this.checkImageAdapt();
        })
    )
    .gesture(
      GestureGroup(GestureMode.Parallel,
        // 拖动手势
        PanGesture({})
          .onActionStart(() => {
            hilog.info(0, "CropView", "Pan gesture start");
            this.startOffsetX = this.model.offsetX;
            this.startOffsetY = this.model.offsetY;
          })
          .onActionUpdate((event:GestureEvent) => {
            hilog.info(0, "CropView", `Pan gesture update: ${JSON.stringify(event)}`);
            if (event) {
              if (this.model.panEnabled) {
                let distanceX: number = this.startOffsetX + vp2px(event.offsetX) / this.model.scale;
                let distanceY: number = this.startOffsetY + vp2px(event.offsetY) / this.model.scale;
                this.model.offsetX = distanceX;
                this.model.offsetY = distanceY;
                this.updateMatrix()
              }
            }
          })
          .onActionEnd(() => {
            hilog.info(0, "CropView", "Pan gesture end");
            this.checkImageAdapt();
          }),

        // 缩放手势处理
        PinchGesture({ fingers: 2 })
          .onActionStart(() => {
            this.tempScale = this.model.scale
          })
          .onActionUpdate((event) => {
            if (event) {
              if (!this.model.zoomEnabled) return;
              this.zoomTo(this.tempScale * event.scale);
            }
          })
          .onActionEnd(() => {
            this.checkImageAdapt();
          })
      )
    )
  }

  /**
   * 检查手势操作后，图片是否填满取景框，没填满则进行调整
   */
  private checkImageAdapt() {
    let offsetX = this.model.offsetX;
    let offsetY = this.model.offsetY;
    let scale = this.model.scale;
    hilog.info(0, "CropView", `offsetX: ${offsetX}, offsetY: ${offsetY}, scale: ${scale}`)

    // 图片适配控件的时候也进行了缩放，计算出这个缩放比例
    let widthScale = this.model.componentWidth / this.model.imageWidth;
    let heightScale = this.model.componentHeight / this.model.imageHeight;
    let adaptScale = Math.min(widthScale, heightScale);
    hilog.info(0, "CropView", `Image scale ${adaptScale} while attaching the component[${this.model.componentWidth}, ${this.model.componentHeight}]`)

    // 经过两次缩放(适配控件、手势)后，图片的实际显示大小
    let showWidth = this.model.imageWidth * adaptScale * this.model.scale;
    let showHeight = this.model.imageHeight * adaptScale * this.model.scale;
    let imageX = (this.model.componentWidth - showWidth) / 2;
    let imageY = (this.model.componentHeight - showHeight) / 2;
    hilog.info(0, "CropView", `Image left top is (${imageX}, ${imageY})`)

    // 取景框的左上角坐标
    let frameX = (this.model.componentWidth - this.model.frameWidth) / 2;
    let frameY = (this.model.componentHeight - this.model.getFrameHeight()) / 2;

    // 图片左上角坐标
    let showX = imageX + offsetX * scale;
    let showY = imageY + offsetY * scale;
    hilog.info(0, "CropView", `Image show at (${showX}, ${showY})`)

    if(this.model.frameWidth > showWidth || this.model.getFrameHeight() > showHeight) { // 图片缩放后，大小不足以填满取景框
      let xScale = this.model.frameWidth / showWidth;
      let yScale = this.model.getFrameHeight() / showHeight;
      let newScale = Math.max(xScale, yScale);
      this.model.scale = this.model.scale * newScale;
      showX *= newScale;
      showY *= newScale;
    }

    // 调整x轴方向位置，使图像填满取景框
    if(showX > frameX) {
      showX = frameX;
    } else if(showX + showWidth < frameX + this.model.frameWidth) {
      showX = frameX + this.model.frameWidth - showWidth;
    }
    // 调整y轴方向位置，使图像填满取景框
    if(showY > frameY) {
      showY = frameY;
    } else if(showY + showHeight < frameY + this.model.getFrameHeight()) {
      showY = frameY + this.model.getFrameHeight() - showHeight;
    }
    this.model.offsetX = (showX - imageX) / scale;
    this.model.offsetY = (showY - imageY) / scale;
    this.updateMatrix();
  }

  public zoomTo(scale: number): void {
    this.model.scale = scale;
    this.updateMatrix();
  }

  public updateMatrix(): void {
    this.matrix = Matrix4.identity()
      .translate({ x: this.model.offsetX, y: this.model.offsetY })
      .scale({ x: this.model.scale, y: this.model.scale })
  }
}

interface ImageLoadedEvent {
  width: number;
  height: number;
  componentWidth: number;
  componentHeight: number;
  loadingStatus: number;
  contentWidth: number;
  contentHeight: number;
  contentOffsetX: number;
  contentOffsetY: number;
}

export interface ImageLoadEventListener {

  onImageLoaded(msg: ImageLoadedEvent): void;

  onImageLoadError(error: ImageError): void;
}

export class CropModel {
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

  /// 以下变量不要手动赋值 ///
  /**
   * 图片宽度，加载完成之后才会赋值
   */
  imageWidth: number = 0;
  /**
   * 图片高度，加载完成之后才会赋值
   */
  imageHeight: number = 0;
  /**
   * 控件宽度
   */
  componentWidth: number = 0;
  /**
   * 控件高度
   */
  componentHeight: number = 0;
  /**
   * 手势缩放比例
   * 图片经过了两重缩放，一是适配控件的时候进行了缩放，二是手势操作的时候进行了缩放
   */
  scale: number = 1;
  /**
   * x轴方向偏移量
   */
  offsetX: number = 0;
  /**
   * y轴方向偏移量
   */
  offsetY: number = 0;

  /////////////////////////////////////////////

  public setImage(src: string, previewSource?: string | Resource): CropModel {
    this.src = src;
    if (!!previewSource) {
      this.previewSource = previewSource;
    }
    return this;
  }

  public setScale(scale: number): CropModel {
    this.scale = scale;
    return this;
  }

  public isPanEnabled(): boolean {
    return this.panEnabled;
  }

  public setPanEnabled(panEnabled: boolean): CropModel {
    this.panEnabled = panEnabled;
    return this;
  }

  public setZoomEnabled(zoomEnabled: boolean): CropModel {
    this.zoomEnabled = zoomEnabled;
    return this;
  }

  public setFrameWidth(frameWidth: number) : CropModel {
    this.frameWidth = frameWidth;
    return this;
  }

  public setFrameRatio(frameRatio: number) : CropModel {
    this.frameRatio = frameRatio;
    return this;
  }

  public setMaskColor(color: string) : CropModel {
    this.maskColor = color;
    return this;
  }

  public setStrokeColor(color: string) : CropModel {
    this.strokeColor = color;
    return this;
  }

  public setImageLoadEventListener(listener: ImageLoadEventListener) : CropModel {
    this.imageLoadEventListener = listener;
    return this;
  }

  public getScale(): number {
    return this.scale;
  }

  public isZoomEnabled(): boolean {
    return this.zoomEnabled;
  }

  public getImageWidth(): number {
    return this.imageWidth;
  }

  public getImageHeight(): number {
    return this.imageHeight;
  }

  public getFrameHeight() {
    return this.frameWidth / this.frameRatio;
  }

  public reset(): void {
    this.scale = 1;
    this.offsetX = 0;
    this.offsetY = 0;
  }

  public async crop(format: image.PixelMapFormat) : Promise<image.PixelMap> {
    if(!this.src || this.src == '') {
      throw new Error('Please set src first');
    }
    if(this.imageWidth == 0 || this.imageHeight == 0) {
      throw new Error('The image is not loaded');
    }

    // 图片适配控件的时候也进行了缩放，计算出这个缩放比例
    let widthScale = this.componentWidth / this.imageWidth;
    let heightScale = this.componentHeight / this.imageHeight;
    let adaptScale = Math.min(widthScale, heightScale);

    // 经过两次缩放(适配控件、手势)后，图片的实际显示大小
    let totalScale = adaptScale * this.scale;
    let showWidth = this.imageWidth * totalScale;
    let showHeight = this.imageHeight * totalScale;
    let imageX = (this.componentWidth - showWidth) / 2;
    let imageY = (this.componentHeight - showHeight) / 2;

    // 取景框的左上角坐标
    let frameX = (this.componentWidth - this.frameWidth) / 2;
    let frameY = (this.componentHeight - this.getFrameHeight()) / 2;

    // 图片左上角坐标
    let showX = imageX + this.offsetX * this.scale;
    let showY = imageY + this.offsetY * this.scale;

    let x = (frameX - showX) / totalScale;
    let y = (frameY - showY) / totalScale;

    let file = fs.openSync(this.src, fs.OpenMode.READ_ONLY)
    let imageSource : image.ImageSource = image.createImageSource(file.fd);
    let decodingOptions : image.DecodingOptions = {
      editable: true,
      desiredPixelFormat: format,
    }
    // 创建pixelMap
    let pm = await imageSource.createPixelMap(decodingOptions);
    let region: image.Region = { x: x, y: y, size: { width: this.frameWidth / totalScale, height: this.getFrameHeight() / totalScale } };
    pm.cropSync(region);
    return pm;
  }
}
