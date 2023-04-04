# GOAP_LUA

纯lua实现的简易goap框架，规定了Action\Goal\State\Agent的数据结构，提供了对应的Plan方法

项目中包含一个example.lua文件，示范了如何使用

本项目包含2个分支，master分支下采用的是正向规划算法，inverse-planning分支采用的逆向规划算法

逆向规划在我个人的小规模测试中(也就是example.lua中的例子)，相较正向规划，有9%左右的性能提升
