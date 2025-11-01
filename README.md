## 随便解

碰到的一些随机的问题，用一些随缘的解。

## 目录

|脚本|描述|使用方式|
|:--:|:--:|:--:|
|[clipboard_sync.sh](./niri/clipboard_sync.sh)|同步 wayland 和 x11 的剪贴板|后台持续运行|
|[mask_kded6_generator.sh](./niri/mask_kded6_generator.sh)|用于屏蔽 kded6，在 kde 桌面环境下会自动恢复|运行一次即可，下次启动桌面时自动生效。或者手动运行生成的 mask_kded6.sh 脚本也可以即可生效。|
|[usb_watcher.sh](./niri/usb_watcher.sh)|usb 设备插入/拔出自动通知及快速打开目录|后台持续运行|
|screenshot 系列脚本|[screen_shot.sh](./niri/screenshot/screen_shot.sh) 当前显示器截图<br>[all_screen_shot.sh](./niri/screenshot/all_screen_shot.sh) 所有显示器截图<br>[area_shot.sh](./niri/screenshot/area_shot.sh) 区域截图<br>[edit_screen_shot.sh](./niri//screenshot/edit_screen_shot.sh) 编辑截图|运行脚本即可截图，截图后保存到文件，并复制文件路径到剪贴板（以文件复制形式），编辑截图需要读取截图路径，因此需要先截图才能使用|
|[start_app.sh](./niri/appManager/start_app.sh)|开机应用自启动，可设置启动的应用的目标显示器和目标工作区，以及屏蔽一些窗口如 discord 的 start 窗口|添加到开机运行的脚本，需要启动的应用列表在 [applist.txt](./niri/appManager/applist.txt) 配置，格式为：`应用名称:显示器名称:工作区名称:屏蔽标题`，不需要配置的项目请置空|