# GOAP_LUA

纯lua实现的简易goap框架，规定了Action\Goal\State\Agent的数据结构，提供了对应的Plan方法

## 使用方法

项目中包含一个example.lua文件，示范了如何使用

## 分支

本项目包含2个分支，master分支下采用的是正向规划算法，inverse-planning分支采用的逆向规划算法

## 其他

1. 使用A*算法的 `PlanForGoal`函数，相较于使用广度优先搜索，在我个人的小规模测试中(也就是*example.lua*中的例子)可以获得40%的性能提升
2. 逆向规划在我个人的小规模测试中(也就是*example.lua*中的例子)，相较使用A*的正向规划，有9%左右的性能提升
3. 在逆向规划分支中，在调用 `GoapAgent`的 `SetActions`方法的时候，会对传入的action数组重新组织，将按照 `action`的 `effects`中能提供的效果对其分类存储，使用这种方法可以在 `PlanForGoal`算法中大幅减少遍历数量，测试可提高40%到50%的性能
