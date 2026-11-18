# 项目记忆

## 技术架构
- Godot 4 像素风战棋卡牌游戏毕设，GDScript 为主
- 战斗系统：位置块(1-11) + 三种攻击模式(近战/射击/炮击) + 栈克制链(Melee→Shoot→Shelling→Melee)
- 卡牌系统：function_list[4] 模组化设计，apply_function 填充 _anim_queue，consume_queue 串行 await 执行
- 地图系统：骰子步数 + 能量条 + 8 种事件节点（商店/整备间/战斗等），TileMap 实现
- 动画调度：聚拢动画 fire-and-forget + await_hand_settled() 同步点，功能队列立即启动
- TextureRect 叠加做进度条，Label + 弹射/缩放/淡出做浮动文字

## 用户习惯
- 先分析根本原因再改代码，不盲目重写
- 会主动验证方案，不接受不需要的修改
- 喜欢简洁直接的指令，常用"对不对"确认
- 视觉描述偏好感性意象（"能量涌动"）

## 当前状态 (2026-04-29)
- BUFF 系统已实现：四个临时型（易伤/过热/致盲/哑火）+ 常驻型预留
- 敌人 AI 已实现：基础近战/射击/炮击/不可移动/变异体
- 回合制流程完整：玩家回合→敌人回合循环，胜负判定接入 news 界面
- 卡牌奖励系统（card_reward）随机生成，去重+签名机制
- 武器奖励系统（weapon_reward）随机生成，属性弹随机装备
- 地图探索框架已搭好，事件节点逻辑大多为空
- 待做：三个属性弹卡牌模组、哑火效果接入炮击等待时间、地图事件节点

## 类独立化 (2026-05-06)
- 武器类从 Profile.gd 内嵌类拆分为独立 .gd 文件（带 class_name）：Attack、Melee、Shoot、Shelling、Through_shoot、Sputtering_type_artillery、Multi_target_missile、Missile、Firebomb、FlashBang、Flare
- Item 类也独立为 Item.gd（class_name Item）
- SaveData 类独立为 SaveData.gd（class_name SaveData extends Resource）
- 所有外部脚本的 Profile.Melee/Shoot/Shelling/Attack 等类型引用已替换为全局类名
- Profile.gd 中仍保留：Role、Player、Enemy、Enemy_information、TimeRecorder、AnimationUnit 及其子类、EnemyBehavior 枚举
- Profile.item、Profile.player、Profile.Deck 等实例变量引用保持不变
- 存档系统：SaveData 用 ResourceSaver.save() 写 .tres 文件，存放在 user://savadata/save.tres
- 存档路径注意：内嵌类用 SubResource 导致 .tres 反序列化失败，拆分后用 ExtResource + class_name 解决
- Deck 存档用 id 数组（deck_ids: Array[Array]），读档时根据 id 重建卡牌
- 备份目录：scripts_backup_20260506
