# Letter Drop Animation

中文 | [English](README_EN.md)

一个基于Flutter和Flame Forge2D物理引擎的赛博朋克风格字母掉落动画应用。

## 项目描述

这个应用程序展示了一个具有物理效果的字母掉落动画，字母会从屏幕顶部随机生成并掉落，遵循物理规则与边界和其他字母碰撞。每个字母都有赛博朋克风格的视觉效果，包括霓虹色彩、发光效果和故障艺术风格。

## 功能特点

- 基于物理引擎的真实掉落动画
- 赛博朋克风格的视觉设计
  - 霓虹色彩（量子蓝、故障紫、信号绿）
  - 发光和阴影效果
  - 故障艺术风格的视觉呈现
- 元音字母具有更大的质量
- 字母与边界和其他字母的物理碰撞
- 碰撞音效
- 定期自动生成新字母

## 技术栈

- Flutter框架
- Flame游戏引擎
- Forge2D物理引擎（Box2D的Dart实现）
- Flutter Riverpod状态管理
- Google Fonts字体
- AudioPlayers音频播放

## 安装与运行

1. 确保已安装Flutter SDK和相关依赖
2. 克隆此仓库
3. 运行以下命令安装依赖：

```bash
flutter pub get
```

4. 运行应用：

```bash
flutter run
```

## 项目结构

- `main.dart` - 应用程序入口点，包含UI设置和游戏世界初始化
- `letter_physics.dart` - 字母物理体的实现，包含视觉效果和物理属性

## 自定义

你可以通过修改以下参数来自定义动画效果：

- 在`LetterBody`类中修改颜色列表`cyberpunkColors`
- 调整`_startLetterGeneration`方法中的生成间隔
- 在`LetterBody.createBody`中修改物理属性（密度、摩擦力、弹性等）

## 许可

此项目采用MIT许可证。详情请参阅LICENSE文件。
