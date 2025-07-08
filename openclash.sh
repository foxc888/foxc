#!/bin/bash

echo "🪐 开始 OpenClash 一键部署..."

# 1. 安装依赖
echo "🔧 安装依赖..."
opkg update || true
opkg install python3 python3-pip wget unzip kmod-fs-cifs ksmbd-server ksmbd-tools luci-app-ksmbd || true
pip3 install pyyaml || true

# 2. 下载并解压 OpenClashManage
echo "📦 下载并解压 OpenClashManage..."
cd /root
wget -O OpenClashManage.zip "https://github.com/foxc888/foxc/raw/refs/heads/main/OpenClashManage.zip" || true
unzip -o OpenClashManage.zip || true
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

if ! grep -q "OpenClashManage/jk.sh" /etc/rc.local; then
    sed -i '$i nohup bash /root/OpenClashManage/jk.sh &' /etc/rc.local
    chmod +x /etc/rc.local
fi
nohup bash /root/OpenClashManage/jk.sh &

# 4. 清空 Passwall 配置并关闭
echo "⚠️ 清空 Passwall 网络配置..."
uci delete passwall.myshunt || true
uci delete passwall.kOkBcgHN || true
uci commit passwall
/etc/init.d/passwall stop || true
/etc/init.d/passwall disable || true

# 5. 下载新的 OpenClash 配置文件
echo "📥 下载新的 OpenClash 配置文件..."
wget -O /etc/openclash/config.yaml "https://raw.githubusercontent.com/foxc888/foxc/refs/heads/main/clashfile.yaml" || true

# 6. 启用 OpenClash
echo "🚀 启用 OpenClash..."
/etc/init.d/openclash enable || true
/etc/init.d/openclash restart || true

echo "✅ OpenClash 一键部署完成！"
echo "✅ 请确保重启软路由以生效全部设置。"

exit 0
