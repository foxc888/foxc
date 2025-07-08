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
wget -O /etc/openclash/config.yaml "https://raw.githubusercontent.com/foxc888/foxc/refs/heads/main/2-254%E6%89%8B%E5%8A%A8%E9%85%8D%E7%BD%AE.yaml" || true

# 7️⃣ 删除 Passwall 所有网络配置并关闭 Passwall
# （根据实际Passwall配置文件位置调整）
uci delete passwall.@global[0].enabled || true
uci delete passwall.@global[0].config || true
uci commit passwall || true
/etc/init.d/passwall stop || true
/etc/init.d/passwall disable || true

# 8️⃣ 启用并启动 OpenClash
/etc/init.d/openclash enable || true
/etc/init.d/openclash restart || true

# 9️⃣ jk.sh 守护脚本开机自启并立即运行
if ! grep -q "OpenClashManage/jk.sh" /etc/rc.local; then
    sed -i '$i nohup bash /root/OpenClashManage/jk.sh &' /etc/rc.local
    chmod +x /etc/rc.local
fi
nohup bash /root/OpenClashManage/jk.sh &

echo "✅ OpenClash 自动管理环境部署完成！"
echo "✅ 配置文件已部署到 /etc/openclash/config.yaml"
echo "✅ 已删除 Passwall 网络配置并关闭 Passwall"
echo "✅ OpenClash 已启用并启动"
echo "✅ jk.sh 守护脚本已启动并配置开机自启"

# 删除自身脚本
rm -- "$0"

exit 0
