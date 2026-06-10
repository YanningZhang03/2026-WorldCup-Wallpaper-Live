# 2026-WorldCup-Wallpaper-Live

这是不依赖 Wallpaper Engine 的 Windows 便携版。解压后双击启动脚本即可运行。

## 使用方法

1. 解压整个文件夹。
2. 双击 `Start-WorldCup-Wallpaper.cmd` 启动壁纸。
3. 双击 `Stop-WorldCup-Wallpaper.cmd` 停止壁纸。
4. 想先预览效果，可以双击 `Open-Preview-In-Browser.cmd`。

## 运行环境

- Windows 10 / Windows 11
- Microsoft Edge
- 正常联网时会自动从 ESPN 更新赛程和赛果

## 说明

- 这个版本会用独立的 Edge profile 打开壁纸，不会影响用户平时使用的 Edge。
- 壁纸会嵌入桌面后层，停止脚本只会关闭本壁纸启动的 Edge 进程。
- 如果 ESPN 接口或网络不可用，会自动使用随包附带的 `worldcup-live-data.js` 缓存数据。
- 首次运行后会生成 `runtime/` 文件夹，用来保存壁纸运行状态和 Edge profile。

## 文件说明

- `Start-WorldCup-Wallpaper.cmd` - 双击启动
- `Stop-WorldCup-Wallpaper.cmd` - 双击停止
- `Open-Preview-In-Browser.cmd` - 浏览器预览
- `worldcup-countdown-wallpaper.html` - 壁纸页面
- `assets/` - 大力神杯图片
- `flags/` - 国旗图片
- `worldcup-live-data.js` - 离线缓存数据
