import { CropModel, CropView } from '@xinyansoft/ohcrop';
import { image } from '@kit.ImageKit';
import fs from '@ohos.file.fs';
import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
@Entry
@Component
struct Index {
  @State private model: CropModel = new CropModel()
    .setFrameWidth(1000)
      // 如果要矩形取景框，把这个设置删掉
    .setEllipseFrame(true)
      // 如果要圆形，把比例设置成1
    .setFrameRatio(0.8);
  @State private cropUri? : string = undefined;

  private updateModel(src : string) {
    this.model.setImage(src)
      .setFrameWidth(1000)
      // 如果要矩形取景框，把这个设置删掉
      .setEllipseFrame(true)
      // 如果要圆形，把比例设置成1
      .setFrameRatio(0.8);
  }

  build() {
    Column() {
      if(this.cropUri) {
        Image(this.cropUri)
          .layoutWeight(1)
          .objectFit(ImageFit.Contain)
          .width('100%')
      } else {
        CropView({
          model: this.model,
        })
          .layoutWeight(1)
          .width('100%')
      }


      Divider()
      Row() {
        Text('选图片')
          .height('100%')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .onClick(() => {
            this.openGallery();
          })

        Line()
          .height('50%')
          .width(0.5)
          .backgroundColor(0xdddddd)

        Text('确定')
          .height('100%')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .onClick(() => {
            this.crop();
          })
      }
      .width('100%')
      .height(44)
    }
    .width('100%')
    .height('100%')
  }

  private async openGallery() {
    let context = getContext(this) as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    let info = await bundleManager.getBundleInfoForSelf(0);
    if (info && info.appInfo) {
      let result = atManager.verifyAccessTokenSync(info.appInfo.accessTokenId, "ohos.permission.READ_MEDIA");
      if (abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED == result) {
        this.openGalleryInternal();
      }
    } else {
      atManager.requestPermissionsFromUser(context, ["ohos.permission.READ_MEDIA"], (error, result) => {
        if (result) {
          console.log("result: " + JSON.stringify(result));
          if (result.authResults[0] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
            this.openGalleryInternal();
          }
        }
      });
    }
  }

  private openGalleryInternal() {
    let photoPicker = new picker.PhotoViewPicker();
    photoPicker.select({
      MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 1
    }, (error, result) => {
      if (result) {
        this.cropUri = undefined;
        this.updateModel(result.photoUris[0]);
      } else {
      }
    });
  }

  async crop() {
    if(this.cropUri) {
      return;
    }
    let pm = await this.model.crop();
    this.packToFile(getContext(this), pm);
  }

  async  packToFile(context: Context, pixelMap: PixelMap): Promise<void> {
    const fPath: string = context.cacheDir + '/' + this.getTimeStr() + '.jpg';
    const writeFd: fs.File = await fs.open(fPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

    const opts : image.PackingOption = { format: "image/jpeg", quality: 100};
    const imagePacker = image.createImagePacker();
    await imagePacker.packToFile(pixelMap, writeFd.fd, opts);
    fs.closeSync(writeFd.fd);

    this.cropUri = "file://" + fPath;
  }

  getTimeStr(): string {
    const now: Date = new Date();
    const year: number = now.getFullYear();
    const month: number = now.getMonth() + 1;
    const day: number = now.getDate();
    const hours: number = now.getHours();
    const minutes: number = now.getMinutes();
    const seconds: number = now.getSeconds();
    return `${year}${month}${day}_${hours}${minutes}${seconds}`;
  }
}