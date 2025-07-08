#!/bin/bash

# ============================================
# 🪐 OpenClash 自动管理一键部署初始化脚本
# foxc 项目定制版（避免执行中断，自动容错）
# ============================================

echo "🪐 开始执行 OpenClash 自动化部署..."

# ============================================
# 1️⃣ 替换 OpenWRT 软件源以避免依赖下载失败
# ============================================
echo "🌐 切换软件源到 USTC 镜像..."
sed -i 's|http://downloads.openwrt.org|https://mirrors.ustc.edu.cn/openwrt|' /etc/opkg/distfeeds.conf
opkg update || true

# ============================================
# 2️⃣ 安装依赖（容错防止卡死）
# ============================================
echo "🔧 安装 Python、pip、wget、unzip..."
opkg install python3 python3-pip wget unzip || true
pip3 install pyyaml || true

echo "🔧 安装 ksmbd 以启用本地 SMB 文件映射..."
opkg install kmod-fs-cifs ksmbd-server ksmbd-tools luci-app-ksmbd || true

# ============================================
# 3️⃣ 下载并解压 OpenClashManage
# ============================================
echo "📦 下载并解压 OpenClashManage..."
cd /root
wget -O OpenClashManage.rar "https://github.com/foxc888/foxc/raw/refs/heads/main/OpenClashManage.zip" || true
unzip -o OpenClashManage.rar || unrar x OpenClashManage.rar || true
rm -f OpenClashManage.rar

# ============================================
# 4️⃣ 设置执行权限
# ============================================
echo "🔐 设置执行权限..."
chmod +x /root/OpenClashManage/jk.sh || true
chmod +x /root/OpenClashManage/zr.py || true

# ============================================
# 5️⃣ 配置 SMB 挂载映射
# ============================================
echo "🖇️ 配置 SMB 挂载映射..."
uci add ksmbd share || true
uci set ksmbd.@share[-1].name='OpenClashManage'
uci set ksmbd.@share[-1].path='/root/OpenClashManage/wangluo'
uci set ksmbd.@share[-1].read_only='no'
uci set ksmbd.@share[-1].guest_ok='yes'
uci commit ksmbd
/etc/init.d/ksmbd restart || true
/etc/init.d/ksmbd enable || true

# ============================================
# 6️⃣ 设置 jk.sh 守护脚本开机自启并立即执行
# ============================================
echo "🛠️ 设置 jk.sh 守护脚本开机自启..."
chmod -R 777 /root/OpenClashManage/wangluo || true
if ! grep -q "OpenClashManage/jk.sh" /etc/rc.local; then
    sed -i '$i nohup bash /root/OpenClashManage/jk.sh &' /etc/rc.local
    chmod +x /etc/rc.local
fi
nohup bash /root/OpenClashManage/jk.sh &

# ============================================
# 7️⃣ 设置 OpenClash 开机自启
# ============================================
echo "⚙️ 设置 OpenClash 开机自启..."
/etc/init.d/openclash enable || true

# ============================================
# ✅ 完成提示
# ============================================
echo "✅ OpenClash 自动管理环境部署完成！"
echo "✅ 可通过 Windows 网络访问 /root/OpenClashManage/wangluo 管理节点文件"
echo "✅ jk.sh 守护已启动并实现自动同步监控"
echo "✅ OpenClash 已配置开机自启，如需立即生效，请执行 reboot 重启软路由"

rm -- "$0"   # 删除当前脚本自身

exit 0
