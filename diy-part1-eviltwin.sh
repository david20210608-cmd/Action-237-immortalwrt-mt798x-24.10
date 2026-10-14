#!/bin/bash
#
# 曾在此追加 openwrt 官方 packages feed 以补 php8/net-tools。
# 实测（run 38585799298 manifest）两者本就在 immortalwrt/packages@openwrt-24.10 里：
#   - php8 缺席的真因是 kconfig 可见性（php8-cgi 依赖 php8 为 depends，需显式
#     CONFIG_PACKAGE_php8=y），与 feed 无关
#   - net-tools 的包名是 net-tools-route（PROVIDES:=route）
# 故此脚本保留为空操作，workflow 入口不变。
#
exit 0
