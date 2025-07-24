#!/bin/bash

echo "🪐 开始 OpenClash 一键部署..."

# 1. 安装依赖
echo "🔧 安装依赖..."
opkg update || true
opkg install python3 python3-pip wget unzip luci-app-ksmbd ksmbd-server || true

# 兼容 OpenWrt 无 kmod-fs-cifs 和 ksmbd-tools 情况
opkg install kmod-fs-cifs 2>/dev/null || echo "⚠️ kmod-fs-cifs 未找到，可能被合并或不适配当前架构"
opkg install ksmbd-tools 2>/dev/null || echo "⚠️ ksmbd-tools 未找到，可忽略"

# 安装 Python 模块
pip3 install --no-cache-dir pyyaml ruamel.yaml || true

# 2. 下载并解压 OpenClashManage
echo "📦 下载并解压 OpenClashManage..."
cd /root
wget -O OpenClashManage.zip "https://github.com/foxc888/foxc/raw/refs/heads/main/OpenClashManage.zip" || true

# 解压时强制使用 GBK 编码防乱码
unzip -o -O GBK OpenClashManage.zip -d /root/OpenClashManage || unzip -o OpenClashManage.zip -d /root/OpenClashManage || true
rm -f OpenClashManage.zip

chmod +x /root/OpenClashManage/jk.sh || true
chmod +x /root/OpenClashManage/zr.py || true

# 3. 配置 SMB 挂载
echo "🖇️ 配置 SMB 挂载..."
uci add ksmbd share || true
uci set ksmbd.@share[-1].name='OpenClashManage'
uci set ksmbd.@share[-1].path='/root/OpenClashManage/wangluo'
uci set ksmbd.@share[-1].read_only='no'
uci set ksmbd.@share[-1].guest_ok='yes'
uci commit ksmbd
/etc/init.d/ksmbd restart || true
/etc/init.d/ksmbd enable || true

chmod -R 777 /root/OpenClashManage/wangluo || true

# 启动守护脚本
if ! grep -q "OpenClashManage/jk.sh" /etc/rc.local; then
    sed -i '$i nohup bash /root/OpenClashManage/jk.sh &\n' /etc/rc.local
    chmod +x /etc/rc.local
fi
nohup bash /root/OpenClashManage/jk.sh &

# 4. 清空 Passwall 配置（不删除主程序）
echo "⚠️ 重置 Passwall 配置..."
rm -f /etc/config/passwall
rm -rf /etc/passwall/*
uci commit

# 5. 启用并启动 OpenClash
echo "🚀 启用并启动 OpenClash..."
if [ -x /etc/init.d/openclash ]; then
    /etc/init.d/openclash enable || true
    /etc/init.d/openclash stop || true
    /etc/init.d/openclash start || true
else
    echo "❌ 未检测到 OpenClash 启动脚本，可能未安装 luci-app-openclash"
fi

echo "✅ OpenClash 一键部署完成！"
echo "✅ 请确保重启软路由以生效全部设置。"

# 删除当前脚本文件
rm -- "$0"
exit 0
