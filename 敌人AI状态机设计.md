# 敌人 AI 状态机设计

本文依据当前项目中的 `scripts/Profile.gd`、`scripts/fight_menu.gd` 与战场移动规则整理。它描述现有实现、已确认的战术意图，以及后续将敌人 AI 收敛为状态机时的推荐结构；本文不代表代码已经完成改造。

## 1. 当前实现结论

当前敌人不是完整的“状态机”，而是**敌人行为类型枚举 + 回合内分发**：

- `Profile.EnemyBehavior` 定义 `BASIC_MELEE`、`BASIC_SHOOT`、`BASIC_SHELLING`、`IMMOVABLE`、`MUTANT` 等兵种/策略类型。
- `Profile.Enemy.behavior` 保存该敌人的兵种策略。
- `fight_menu.gd` 的 `enemy_turn(enemy)` 使用 `match e.behavior` 分发到 `_ai_basic_melee()`、`_ai_basic_shoot()` 等函数。
- 炮击瞄准状态目前分散在 `Shelling.is_targeting`、`Lock` Buff、`Character.viscosity` 等字段中。

`behavior` 描述的是“这个敌人通常如何决策”，不是“这个敌人此刻正在做什么”。例如近战兵不会因为移动、攻击或瞄准而改变 `BASIC_MELEE`。

另有一项需要在实现改造前确认：`SLR_1` 的攻击模式为 `Shelling`，但当前配置的 `behavior` 是 `BASIC_SHOOT`。如果其设计目标是炮击敌人，应设置为 `BASIC_SHELLING`。

## 2. 推荐的分层模型

不要把兵种、临时行动、UI 选中状态混在同一个枚举或布尔值中。推荐拆为三层：

| 层级 | 数据 | 说明 |
| --- | --- | --- |
| 兵种策略 | `EnemyBehavior` | 近战、射击、炮击等长期属性，通常整个战斗不变。 |
| 战斗状态 | `EnemyActionState` | 当前是否等待决策、瞄准、行动、死亡。 |
| 本回合意图 | `EnemyIntent` | 本回合实际要攻击、靠近、压位置、后撤、待命。执行结束即失效。 |

`Character.isAimed` 继续只表示玩家 UI 当前选中的敌人，不应用来表示敌人炮击是否正在瞄准。

### 2.1 战斗状态

```gdscript
enum EnemyActionState {
	READY,   # 可开始本回合决策
	AIMING,  # 炮击已锁定，正在等待 Lock 倒计时
	ACTING,  # 正在移动、攻击或播放其流程
	DEAD,    # 已死亡，不能参与后续回合
}

class Enemy extends Role:
	var behavior: int = EnemyBehavior.BASIC_MELEE
	var action_state: int = EnemyActionState.READY
```

状态流转：

```text
READY
  ├─ 近战：选择攻击 / 靠近 / 压位置
  ├─ 射击：选择射击 / 后撤风筝
  └─ 炮击：开始瞄准
       ↓
ACTING ── 动作完成 ──→ READY

READY ── 炮击锁定 ──→ AIMING
AIMING ── Lock 尚未结束 ──→ AIMING
AIMING ── Lock 结束并发射 ──→ ACTING ──→ READY

任意状态 ── 血量归零 ──→ DEAD
```

### 2.2 回合意图

```gdscript
enum EnemyIntent {
	ATTACK,
	APPROACH,
	PRESS_POSITION,
	RETREAT,
	WAIT,
}
```

意图不是持久状态。它是敌人在 `READY` 状态中，基于本回合棋盘位置、玩家武器、队友火力和可移动格子得到的一次行动计划。

## 3. 决策必须先验证可执行性

敌人不能先决定“压位置”或“后撤”，执行时才发现越界、被敌对单位阻挡，最后白白空过一回合。

统一流程应为：

```text
收集候选意图
  → 检查每个意图的前提和目标格可行性
  → 按优先级选取第一个可执行意图
  → 执行已确认的计划
  → 极端情况下执行失败时，立刻走后备方案
```

因此，应提供“严格移动”判断。它只检查指定方向的目标格，不使用通用移动函数的反向弹回逻辑。

```gdscript
func _can_move_strict(character: Character, direction: int) -> bool:
	var places: Array = _get_places()
	var current_index: int = places.find(character.place)
	var target_index: int = current_index + direction

	if target_index < 0 or target_index >= places.size():
		return false

	var target_place: Position = places[target_index]
	var occupant: Character = _get_character_at(target_place, character)

	# 空格可走；同阵营是否可换位，沿用现有战场规则。
	return occupant == null or _are_allies(character, occupant)
```

实际执行时应使用与该判断相同的规则，例如 `_try_move_to_index()`。即使已预判可走，仍保留执行失败的后备动作，以防动画期间目标死亡、强制位移或后续机制改变棋盘。

## 4. 近战敌人的压位置

### 4.1 压位置的战术目的

当前近战 AI 已有压位置雏形：当自身已经能攻击玩家、队友潜在伤害高于自己、且玩家使用近战时，近战敌人会放弃本次攻击并朝玩家移动。

该行为的目的不是多移动一格，而是形成前排阵型：

1. 低输出近战敌人占据更靠近玩家的格子，限制玩家继续向前推进的空间。
2. 敌对单位占位会阻挡玩家进入该格；当前通用移动规则在原方向被敌方挡住时可能尝试反向移动。
3. 高输出射击或炮击队友留在后方持续输出。
4. 玩家被迫处理前排敌人，无法轻易推进至后排或自由选择接触位置。

因此，`PRESS_POSITION` 是近战兵在 `READY` 状态下的一个战术意图，不是新的敌人兵种，也不是类似 `AIMING` 的持久状态。

### 4.2 压位置的选择规则

```text
能攻击玩家
且玩家当前使用近战
且队友的预期总伤害高于自身伤害
且朝玩家方向的目标格可走
→ PRESS_POSITION

否则，若能攻击 → ATTACK
否则，若能朝玩家方向移动 → APPROACH
否则 → WAIT
```

示例：

```gdscript
func _decide_melee_intent(enemy: Character) -> int:
	var can_attack: bool = _can_melee_hit_player(enemy)
	var can_press: bool = _can_move_strict(enemy, -1)

	if can_attack and _should_press_position(enemy) and can_press:
		return EnemyIntent.PRESS_POSITION

	if can_attack:
		return EnemyIntent.ATTACK

	if can_press:
		return EnemyIntent.APPROACH

	return EnemyIntent.WAIT
```

压位置不能直接使用当前 `move_character(enemy, -1)`：该函数在前方不能移动时会反向尝试。压位失败应原地待命或执行后备攻击，而不应被动后撤。

## 5. 射击敌人的风筝

### 5.1 威胁距离

风筝的判断不能只看当前距离，而要看玩家在下一次敌人回合前可触及的最远距离：

```text
玩家最大威胁距离 = 当前武器攻击范围 + 本回合剩余可向前移动格数
安全距离 = 玩家最大威胁距离 + 1 格安全余量
```

例如玩家近战攻击范围为 3，且本回合还能够向前移动 1 格，射击敌人至少应保持 5 格距离，才能避免玩家“先前进、再攻击”后命中。

固定使用 `1` 格位移只能处理最简单的情况。由于玩家可能连续打出多张前进卡，真正要实现“始终打不到”，卡牌管理器最终需要提供“本回合玩家剩余可向前移动格数”。

### 5.2 可风筝的前提

当前规则中，射击基本不受距离限制，炮击锁定后也可能跟踪目标。因此距离风筝只对玩家当前使用 `Melee` 时有效：

- 玩家为 `Melee`：可通过后撤保持安全距离。
- 玩家为 `Shoot`：单纯后撤不能规避伤害，射击敌人应直接攻击或执行其他战术。
- 玩家为 `Shelling`：单纯后撤通常也不能规避锁定，应按炮击规则处理。

### 5.3 风筝选择规则

```text
玩家为近战
且当前距离小于安全距离
且能沿“远离玩家”方向后撤
→ RETREAT

其他所有情况
→ ATTACK
```

这样“退不了”时会射击，而不是什么也不做。

```gdscript
func _decide_kite_shoot_intent(enemy: Character) -> int:
	var player: Character = CharacterArray[0] as Character
	if player == null:
		return EnemyIntent.WAIT

	var enemy_index: int = _get_place_index(enemy)
	var player_index: int = _get_place_index(player)
	var distance: int = abs(enemy_index - player_index)
	var threat_distance: int = _get_player_threat_distance()

	# 玩家远程攻击不能靠拉开格数规避。
	if threat_distance >= 999:
		return EnemyIntent.ATTACK

	var safe_distance: int = threat_distance + 1
	var retreat_direction: int = 1 if enemy_index > player_index else -1

	if distance < safe_distance and _can_move_strict(enemy, retreat_direction):
		return EnemyIntent.RETREAT

	return EnemyIntent.ATTACK
```

后撤方向不应硬编码为右方；应由敌我当前位置动态计算。执行 `RETREAT` 时同样只能尝试远离玩家的目标格，不能使用会反向弹回的通用移动。

## 6. 回合入口示例

以下示例说明状态机的职责分配。具体函数名可在接入时与现有代码统一。

```gdscript
func enemy_turn(enemy: Character) -> void:
	var enemy_data: Profile.Enemy = enemy.setting as Profile.Enemy
	if enemy_data == null or enemy_data.action_state == Profile.EnemyActionState.DEAD:
		return

	match enemy_data.action_state:
		Profile.EnemyActionState.READY:
			await _run_enemy_ready_state(enemy, enemy_data)
		Profile.EnemyActionState.AIMING:
			await _run_enemy_aiming_state(enemy, enemy_data)
```

`READY` 只负责选择并执行一个可行意图；`AIMING` 只负责检查 `Lock` 是否结束、继续瞄准或自动发射。现有的 `trigger_shelling_attacks(enemy)` 已处理敌方自动炮击；若状态机正式接管炮击，应将敌方的自动发射逻辑收敛到 `_run_enemy_aiming_state()`，避免同一回合重复结算。

## 7. 接入顺序

建议按最小范围逐步接入，避免一次性重写全部敌人逻辑：

1. 在 `Profile.gd` 添加 `EnemyActionState` 和 `EnemyIntent`，并给 `Enemy` 添加 `action_state`。
2. 抽出严格移动的“可行性判断”和“严格执行”函数；先不改变原通用移动函数的反弹规则。
3. 将现有基础近战逻辑改为“决定意图 → 执行意图”，优先覆盖 `PRESS_POSITION` 的后备攻击逻辑。
4. 新增 `KITE_SHOOT` 行为，接入射击敌人的后撤/攻击决策。
5. 最后收敛炮击的 `AIMING` 状态，移除重复的布尔状态判断。
6. 为边界、敌对阻挡、友军换位、玩家远程、玩家多张前进卡、炮击锁定、敌人死亡中断等场景逐项验证。

## 8. 验收要点

- 压位置：只有目标格可走才压位；压位不可行但可攻击时必须攻击。
- 靠近：不能前进时不会触发不符合战术意图的反向移动。
- 风筝：不安全且可撤才后撤；无路可退时仍可射击。
- 风筝：面对玩家射击/炮击时不把“拉距离”误判为安全。
- 炮击：瞄准、倒计时、自动发射只发生一次，死亡敌人不会继续结算。
- 状态切换：行动完成回到 `READY`；死亡后固定为 `DEAD`。
