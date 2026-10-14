#!/bin/bash
#
# Evil Twin feed 补充：immortalwrt 精简过的 packages feed 缺 php8、net-tools，
# 追加 openwrt 官方 packages feed（openwrt-24.10 分支）补齐。
# 同名包以排在前面的 feed（immortalwrt）优先，官方 feed 只补缺口。
#

echo 'src-git openwrt_packages https://github.com/openwrt/packages.git;openwrt-24.10' >> feeds.conf.default
