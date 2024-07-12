import { CropModel, CropView } from '@xinyansoft/ohcrop';
import { image } from '@kit.ImageKit';
import { router } from '@kit.ArkUI';
import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
@Entry
@Component
struct Index {
  @State private model: CropModel = new CropModel();
  @State private pixelMap? : PixelMap = undefined;


  private updateModel(src : string) {
    this.model.setImage(src)
      .setFrameWidth(1000)
      .setFrameRatio(1);
  }

  build() {
    Column() {
      if(this.pixelMap) {
        Image(this.pixelMap)
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
        this.pixelMap?.release();
        this.pixelMap = undefined;
        this.updateModel(result.photoUris[0]);
      } else {
      }
    });
  }

  async crop() {
    if(this.pixelMap) {
      return;
    }
    let pm = await this.model.crop(image.PixelMapFormat.RGBA_8888);
    this.pixelMap = pm;
  }
}