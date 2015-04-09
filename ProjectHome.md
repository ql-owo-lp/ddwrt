# THIS IS NO DD-WRT OFFICIAL SITE! #

This project mainly help you make the maximum use of your DD-Wrt Router(technically, almost all scripts are capable to support Tomato, openWrt, Dualwan and other linux-based platform)

So far, most branches of this project require your router **NO JFFS**.  You can merely save an **AUTOLOAD** script in your _startup_ box and reboot your router, everything will be finished automatically in couple of minutes after your wan's up.

# 这不是DD-WRT的官方网站！ #
此开源项目主要用于帮助你最大限度利用路由器的性能，帮助你在不支持JFFS的路由器上安装额外软件。只需要在启动命令框中填写一段脚本代码，路由器便会在每次重启后自动从互联网上获取安装软件并进行自动安装，整个过程不需要任何人为干预，方便吧！～

# WARNING #
This script will cost your router about 3m-6m(in unzip mode it takes about 5-6mb, and 3-4mb in gzip mode, 2-3m for Host Only mode), and maximum at 8m(when fetching and installing new packages).  Be careful if you don't have enough memory!  But you can still make a try before giving it up as the following steps say.

# 警告 #
本脚本大约消耗路由器内存为3m-6m（安装了unzip的情况下稳定运行为5-6m，直接使用gzip模式为3-4m，使用Host Only模式占用为2-3m），当下载和安装包裹时，最大消耗内存可能达到8m（Host Only模式除外，最大消耗3m）。所以，如果你的路由器内存不是非常充裕，请小心使用！但是你也可以进行尝试再说，具体见下面。

## Make a little try! ##
It's safe to try if you have enough memory to have this project installed on your router!  You can try the [simple install script](https://ddwrt.googlecode.com/svn/trunk/demo/starter-simple.sh)(which use gzip-custom mode to retreive hosts file, no other software is going to be installed on your router and saves you memory). Reboot the router and observe the **Free Memory** on **Status** page(you should wait couple minutes before the hosts file is downloaded; you can also login in router with telnet and use **ls /tmp -al** to see the size of hosts file, which is supposed to be larger than 400kb if the progress is successful, then use **free** to see the rest memory). If you are unlucky that the router finally dies of memory lack, don't worry!  Disconnect the cable of WAN and reboot the router, you will be safe to delete the installed script in **Startup Command**, then everything will be OK after you reboot the router again!  More information, check out the wiki page!

## 尝试一下再下定论！ ##
如果你不确定你的路由器是否有足够内存来安装此项目，不妨尝试一下。首先安装[简易配置脚本](https://ddwrt.googlecode.com/svn/trunk/demo/starter-simple.sh)(怎么安装在WIKI手册里面有说明，简易脚本的默认配置为GZIP自定义模式，即不会安装任何软件，节省内存)，然后重启路由等待脚本生效。重启后再次登录路由器，你可以在状态页面看到路由器空闲内存，注意观察（你也可以telnet进入路由器，使用**ls /tmp -al**命令来查看hosts文件的尺寸，如果整个过程顺利，耐心等待几分钟后，hosts文件应该有大于400k，此时你也可以使用**free**命令来监视你的路由器内存）。如果最后路由器因为内存耗尽而死机，没有关系，拔掉wan口网线确保路由器与网络断开连接，然后重启路由，去**启动命令**删除所插入的建议配置文件的代码。再次重启后一切都会恢复正常。详细安装步骤请参考使用手册。

## Project of hosts ##
_Project of hosts_ is mainly about updating the _hosts_ file of your router automatically and periodically.  The _hosts_ file we provide has the ability to block ads, block software activation(Adobe etc.) and help you getting through the Great Fark Wall.
[>>More About Hosts Project](http://code.google.com/p/ddwrt/wiki/HowToUseHostsScript)

## Hosts项目 ##
Hosts工程主要用于自动更新路由器上的Hosts文件，可以用于屏蔽广告、屏蔽软件激活验证(比如Adobe)，同时可以穿越功夫墙（Dropbox等）。在路由器上设置Hosts可以对整个网络进行屏蔽，而不用一一更新每台电脑的Hosts文件。
[>>中文版使用手册](http://code.google.com/p/ddwrt/wiki/ManPage_CN)

## Known Issues ##
  * Not yet...

## 已知问题 ##
  * 所有路由加载后，会有1800+的路由条目，非常不理想。后期会有更智能的方法。现阶段使用的[route](http://autoddvpn.googlecode.com/svn/trunk/grace.d/vpnup.sh)都是从[autoddvpn](http://code.google.com/p/autoddvpn/) grace mode自动加载的。我有比他更棒的idea~