# 随手记

一个使用 Flutter 开发的轻量级随手记应用，支持 Android、iOS 和 Web。

## 功能

- 底部输入框快速记录想法、待办和灵感
- 点击笔记进行编辑
- 置顶重要笔记
- 搜索历史笔记
- 滑动或点击删除，支持撤销
- 使用 `shared_preferences` 在本地持久化保存

## 运行

```bash
flutter pub get
flutter run
```

## 测试与检查

```bash
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

当前代码已在 Flutter 3.35.7 下通过 `flutter analyze`、`flutter test`、Web release 构建和 Android APK release 构建。默认 APK 使用 debug 签名，适合本机安装测试；正式发布前请配置自己的签名密钥。

仓库包含 GitHub Actions 工作流 `.github/workflows/ios-ipa.yml`，会在 macOS runner 上构建未签名 iOS IPA 并上传为 artifact。未签名 IPA 不能直接安装到普通真机，需要重新签名。
