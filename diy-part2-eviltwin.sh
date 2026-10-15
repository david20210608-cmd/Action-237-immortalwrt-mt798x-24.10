#!/bin/bash
#
# Evil Twin 固件附加脚本
# fluxion 通过 `service xxx start/stop` 管理服务，OpenWrt（procd）没有 service 命令，
# 这里垫一个转发到 /etc/init.d 的壳，避免逐处修改 fluxion 源码。
#

mkdir -p package/base-files/files/usr/bin
cat > package/base-files/files/usr/bin/service <<'SH'
#!/bin/sh
[ -x "/etc/init.d/$1" ] && exec /etc/init.d/"$1" "${2:-}"
echo "service: no such init script: $1" >&2
exit 1
SH
chmod +x package/base-files/files/usr/bin/service

#
# 自带源码包（官方 feed 已淘汰，配方在仓库 custom-packages/ 下）
#
rm -rf package/custom
mkdir -p package/custom
cp -af "$GITHUB_WORKSPACE/custom-packages/." package/custom/

#
# fluxion 依赖检查兜底 stub（只在依赖清单出现，攻击代码从不真正调用）：
#   rfkill —— mt76 没有 rfkill 设备，unblock all 本来就是 no-op，返回 0 即可
#   7zr    —— 仅 fluxion 的"更新安装器"用于打包备份，攻击流程不碰，触发即报错
#   dsniff —— 仅在依赖清单存在，源码中无任何调用点，触发即报错
#
cat > package/base-files/files/usr/bin/rfkill <<'SH'
#!/bin/sh
# stub: mt76 radios expose no rfkill devices; unblock is a no-op
exit 0
SH
for stub in 7zr dsniff; do
cat > "package/base-files/files/usr/bin/$stub" <<SH
#!/bin/sh
echo "$stub: not required by the evil-twin workflow" >&2
exit 1
SH
done
chmod +x package/base-files/files/usr/bin/rfkill \
         package/base-files/files/usr/bin/7zr \
         package/base-files/files/usr/bin/dsniff

#
# airmon-ng：airgeddon 必需项。feed 里有独立 airmon-ng 子包，但依赖已被 24.10
# 淘汰的 wireless-tools 无法安装；它只是个脚本，直接从 aircrack-ng 官方仓库
# 按 tag 取（1.7，与固件内 aircrack-ng 版本一致），装到与官方子包相同的路径。
#
mkdir -p package/base-files/files/usr/sbin
curl -fsSL https://raw.githubusercontent.com/aircrack-ng/aircrack-ng/1.7/scripts/airmon-ng.linux \
  -o package/base-files/files/usr/sbin/airmon-ng
chmod +x package/base-files/files/usr/sbin/airmon-ng

#
# Web 层固化修复（run 38742302041 实刷后 LuCI 403 的两处根因）：
#  1) lighttpd（captive portal 用）默认自启抢 IPv4:80，uhttpd 只剩 v6/443，
#     浏览器 http://IP 打到 lighttpd 得裸 403。攻击时 fluxion/airgeddon 会
#     自行 start lighttpd，平时禁用自启即可。
#  2) 本固件 LuCI 是 ucode 版，但 uhttpd-mod-ucode 未被依赖选中（kconfig
#     同类坑），uhttpd 无法派发 /cgi-bin/luci。config 已显式开
#     uhttpd-mod-ucode/uhttpd-mod-lua；这里补 ucode_prefix 并清掉指向
#     不存在 Lua SGI 的残留 lua_prefix。
#
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-evil-twin-web <<'SH'
#!/bin/sh
/etc/init.d/lighttpd disable
uci -q delete uhttpd.main.lua_prefix
uci -q add_list uhttpd.main.ucode_prefix='/cgi-bin/luci=/usr/share/ucode/luci/uhttpd.uc'
uci -q commit uhttpd
exit 0
SH
chmod +x package/base-files/files/etc/uci-defaults/99-evil-twin-web
