if (bigPictureStyleInformation.hideExpandedLargeIcon) {
      bigPictureStyle.bigLargeIcon((android.graphics.Bitmap) null);
    } else {
      bigPictureStyle.bigLargeIcon(bigPictureStyleInformation.expandedLargeIcon);
    }