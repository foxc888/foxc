#!/bin/bash

# ============================================
# 🪐 OpenClash 全自动管理一键部署初始化脚本
# foxc 项目定制版（自动处理 passwall 删除及关闭）
# ============================================

echo "🪐 开始执行 OpenClash 自动化部署..."

# 1️⃣ 切换软件源到 USTC 镜像
echo "🌐 切换软件源到 USTC 镜像..."
sed -i 's|http://downloads.openwrt.org|https://mirrors.ustc.edu.cn/openwrt|' /etc/opkg/distfeeds.conf
opkg update || true

# 2️⃣ 安装依赖
echo "🔧 安装 Python、pip、wget、unzip..."
opkg install python3 python3-pip wget unzip || true
pip3 install pyyaml || true

echo "🔧 安装 ksmbd 以启用本地 SMB 文件映射..."
opkg install kmod-fs-cifs ksmbd-server ksmbd-tools luci-app-ksmbd || true

# 3️⃣ 下载并解压 OpenClashManage
echo "📦 下载并解压 OpenClashManage..."
cd /root
wget -O OpenClashManage.zip "https://github.com/foxc888/foxc/raw/refs/heads/main/OpenClashManage.zip" || true
unzip -o OpenClashManage.zip || unrar x OpenClashManage.zip || true
rm -f OpenClashManage.zip

# 4️⃣ 设置执行权限
echo "🔐 设置执行权限..."
chmod +x /root/OpenClashManage/jk.sh || true
chmod +x /root/OpenClashManage/zr.py || true

# 5️⃣ 配置 SMB 挂载映射
echo "🖇️ 配置 SMB 挂载映射..."
uci add ksmbd share || true
uci set ksmbd.@share[-1].name='OpenClashManage'
uci set ksmbd.@share[-1].path='/root/OpenClashManage/wangluo'
uci set ksmbd.@share[-1].read_only='no'
uci set ksmbd.@share[-1].guest_ok='yes'
uci commit ksmbd
/etc/init.d/ksmbd restart || true
/etc/init.d/ksmbd enable || true

# 6️⃣ 设置 jk.sh 守护脚本开机自启并立即执行
echo "🛠️ 设置 jk.sh 守护脚本开机自启..."
chmod -R 777 /root/OpenClashManage/wangluo || true
if ! grep -q "OpenClashManage/jk.sh" /etc/rc.local; then
    sed -i '$i nohup bash /root/OpenClashManage/jk.sh &' /etc/rc.local
    chmod +x /etc/rc.local
fi
nohup bash /root/OpenClashManage/jk.sh &

# 7️⃣ 下载并写入 OpenClash 基础配置
echo "📥 下载 OpenClash 基础配置文件..."
mkdir -p /etc/openclash
wget -O /etc/openclash/config.yaml "https://raw.githubusercontent.com/foxc888/foxc/main/openclash_base_config.yaml" || true

# 8️⃣ 删除 passwall 所有网络配置
echo "🧹 删除 passwall 所有网络配置..."
PASSWALL_SECTIONS=$(uci show passwall | grep '=servers' | cut -d '.' -f 2 | cut -d '=' -f1)
for section in $PASSWALL_SECTIONS; do
    echo "删除 passwall 服务器配置: $section"
    uci delete passwall.$section
done
uci commit passwall

# 9️⃣ 关闭并禁用 passwall 服务
echo "⏹️ 停止并禁用 passwall 服务..."
/etc/init.d/passwall stop || true
/etc/init.d/passwall disable || true

# 🔟 启用并启动 openclash 服务
echo "▶️ 启用并启动 openclash 服务..."
/etc/init.d/openclash enable || true
/etc/init.d/openclash restart || true

# 1️⃣1️⃣ 脚本自身删除
echo "🗑️ 删除安装脚本自身..."
rm -- "$0"

echo "✅ OpenClash 全自动部署完成！"
echo "✅ 可通过 Windows 网络访问 /root/OpenClashManage/wangluo 管理节点文件"
echo "✅ jk.sh 守护已启动并实现自动同步监控"
echo "✅ passwall 已删除配置并关闭"
echo "✅ openclash 已启用并启动"

exit 0
