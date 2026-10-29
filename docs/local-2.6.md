# 2.6 系列开发验证记录

以下记录保留各开发阶段的验证范围；2.6.4 现已准备发布，历史条目中的“未发布”指当时状态。

- 便便窗口改为桌面图标层级，普通应用窗口可遮挡。
- 鼠标关注间隔缩短为3–7秒，仍只持续跟随3–5秒。
- 新增“允许糯米拖动文件夹”。首次开启触发Finder自动化授权；仅改变桌面图标坐标，不改变文件内容或路径。
- 开启15秒后尝试，之后90–180秒一次；仅在Finder前台、180点内有文件夹、猫咪清醒空闲时执行。当前仅主屏幕坐标范围。
- 使用确认过的预览素材，去除素材内示意文件夹的绘制区域，以Finder实际图标作为拖动物体。每次6步、共42点向左。
- 拖动猫咪、暂停、隐藏、睡眠、关闭开关或切换应用时停止；每步检查文件夹仍在预期位置，拒绝覆盖用户同时改变的位置。Finder自动排列导致读回位置不符时停止。

验证：应用编译签名通过，原有JS/Swift回归与新动画状态互斥测试通过。
真实Finder授权、图标咬合对齐、自动排列及多屏/全屏完整视觉验收尚未完成，不能视作已验证的稳定发布版。
原2.5应用保存在本机原输出目录的“糯米桌面宠物-2.5备份.app”。没有更新GitHub仓库或Release。

## 2.6.1 手动触发

右键新增“拖动文件（立即拖动最近的文件）”：不依赖自动开关、不等待冷却、不要求Finder前台、不受180点距离限制；支持普通文件与文件夹，排除磁盘。会结束当前动作并恢复清醒后执行。桌面边缘目标改为限制猫咪窗口位置，不再直接跳过。找不到目标、动画未准备好、Finder位置读回失败时提供明确提示。
仍仅在主屏幕范围选择可移动图标，仍只更改桌面位置，不更改文件路径。编译、签名与动画状态测试通过；实际Finder位置改变需要用户授权后的本地测试，不声称已经端到端验证。

## 2.6.2 Finder 引用错误修复

实机确认系统的“糯米 → Finder”权限已经开启。应用进程内诊断得到 -1728（无法获取 item 1 of desktop），原提示错误地归因于权限。
将桌面枚举改为先 get every item of desktop 获取快照，再逐项 contents of itemRef 解引用，并显式读取 name 和 desktop position。现在仅 -1743 提示授权问题，其余错误显示真实错误码与说明。
在正式应用进程内成功读取21个桌面项目，并将一个项目位置写回原值、读回校验成功。该测试没有移动任何图标，不代表完整动画咬合已经视觉验收。
保留一次性 finderDiagnosticsOnce 内部诊断开关，默认关闭，运行即清除；结果只存错误/数量和写回成功状态，不保存文件名。

## 2.6.3 可见图标位置与拖动时序

用户授权关闭Finder叠放并将排序设为无，实际通过系统UI完成。原桌面为GroupBy=Kind、arrangeBy=dateAdded，存储坐标与叠放显示位置不一致。
新增桌面布局检测，启用叠放或自动排序时拒绝拖动；按实际iconSize计算接触点；在到达目标之前保持待机外观；各拉动帧对齐嘴部锚点。取消会破坏咬合位置的窗口强制夹紧，无法对齐时明确停止。
用户同意后的实机测试使用同一“立即拖动”代码，Finder读回记录fromX=1446、toX=1404、steps=6，且桌面前后截图可见对应图标左移。没有改动文件路径与内容。
动画状态测试及原有JS回归通过。工具截图按单应用分层，尚未获得猫咪与图标同屏的连续视觉验证；精确咬合观感仍需用户现场确认。
内部folderDragTestOnce仅显式设置时触发一次手动拖动，启动后立即清除，默认不启用。本轮没有更新远程仓库或Release。

## 2.6.4 一键还原文件位置

右键新增“一键还原文件位置”。每个桌面项目首次成功拖动时保存原始坐标，重复拖动不覆盖；历史持久保存到偏好设置。还原会先停止当前拖动，通过同一串行Finder队列在已提交的移动之后执行，逐个写回原坐标并读回验证。成功项目删除记录，失败项目保留，结束后报告数量；自动拖动延后180秒。
还原期间阻止新拖动。叠放或自动排列开启时提示先关闭，不会暗改桌面设置。按桌面项目名称匹配，重命名或移出桌面的项目会保留记录并报失败。
旧版仅有最后一次拖动记录，因此只导入那一次已成功拖动的起点一次；不能推算更早历史。
PositionHistory单测覆盖首次起点不覆盖、重启保留、旧记录只导入一次、成功清理与重新拖动的新起点；编译签名和动画状态测试通过。没有擅自执行用户全部文件位置还原。

## 2.6.6 — automatic file drag scheduling
- Removed Finder-frontmost requirement; desktop-level cat and icons remain underneath ordinary app windows.
- Automatic drag can interrupt ambient roaming/gaze, but not sleep, pause, user dragging, potty or other locked actions.
- Nearby search radius: 180 → 300 points. Unsuccessful attempts retry after 10 seconds; completed drags rest 60–120 seconds. Initial launch delay remains 30 seconds.
- `lastFolderDrag.automatic` distinguishes a real automatic move from a manual test; coordinate readback and original-position history remain required for every successful step.
- Regression suite passed, including interruption/exclusion tests; signed 2.6.6 local build installed. Runtime auto-drag observation recorded separately below.
