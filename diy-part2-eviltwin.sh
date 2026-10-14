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
