#!/bin/bash
#
# Evil Twin 固件附加脚本
# fluxion 通过 `service xxx start/stop` 管理服务，OpenWrt（procd）没有 service 命令，
# 这里垫一个转发到 /etc/init.d 的壳，避免逐处修改 fluxion 源码。
#

mkdir -p package/base-files/files/usr/bin
cat > package/base-files/files/usr/bin/service <<'EOF'
#!/bin/sh
[ -x "/etc/init.d/$1" ] && exec /etc/init.d/"$1" "${2:-}"
echo "service: no such init script: $1" >&2
exit 1
EOF
chmod +x package/base-files/files/usr/bin/service
