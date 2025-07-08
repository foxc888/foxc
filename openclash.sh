#!/bin/bash

echo "🪐 开始执行 OpenClash 自动化部署..."

# 替换软件源
echo "🌐 切换软件源到 USTC 镜像..."
sed -i 's|http://downloads.openwrt.org|https://mirrors.ustc.edu.cn/openwrt|' /etc/opkg/distfeeds.conf
opkg update || true

# 安装依赖
echo "🔧 安装必要依赖..."
opkg install python3 python3-pip wget unzip kmod-fs-cifs ksmbd-server ksmbd-tools luci-app-ksmbd || true
pip3 install pyyaml || true

# 下载并解压 OpenClashManage
echo "📦 下载并解压 OpenClashManage..."
cd /root
wget -O OpenClashManage.zip "https://github.com/foxc888/foxc/raw/refs/heads/main/OpenClashManage.zip" || true
unzip -o OpenClashManage.zip || true
rm -f OpenClashManage.zip

# 设置权限
echo "🔐 设置执行权限..."
chmod +x /root/OpenClashManage/jk.sh || true
chmod +x /root/OpenClashManage/zr.py || true

# 配置 SMB 挂载映射
echo "🖇️ 配置 SMB 挂载映射..."
uci add ksmbd share || true
uci set ksmbd.@share[-1].name='OpenClashManage'
uci set ksmbd.@share[-1].path='/root/OpenClashManage/wangluo'
uci set ksmbd.@share[-1].read_only='no'
uci set ksmbd.@share[-1].guest_ok='yes'
uci commit ksmbd
/etc/init.d/ksmbd restart || true
/etc/init.d/ksmbd enable || true

# 设置 jk.sh 守护脚本开机自启
echo "🛠️ 设置 jk.sh 守护脚本开机自启..."
chmod -R 777 /root/OpenClashManage/wangluo || true
if ! grep -q "OpenClashManage/jk.sh" /etc/rc.local; then
    sed -i '$i nohup bash /root/OpenClashManage/jk.sh &' /etc/rc.local
    chmod +x /etc/rc.local
fi
nohup bash /root/OpenClashManage/jk.sh &

# 下载并放置 OpenClash 配置文件
echo "📥 下载 OpenClash 配置文件..."
mkdir -p /etc/openclash
wget -O /etc/openclash/config.yaml "https://raw.githubusercontent.com/foxc888/foxc/refs/heads/main/2-254%E6%89%8B%E5%8A%A8%E9%85%8D%E7%BD%AE.yaml" || true

# 清空 PassWall 节点配置并关闭 PassWall
echo "🧹 清空 PassWall 节点并关闭服务..."
uci delete_passwall_nodes() {
  # 查找并删除所有 passwall 节点配置
  uci show passwall | grep "=nodes" | cut -d"." -f2- | while read -r line; do
    uci delete passwall."$line" || true
  done
  uci commit passwall || true
}
uci delete_passwall_nodes

/etc/init.d/passwall stop || true

# 启动并启用 OpenClash
echo "⚙️ 启动并启用 OpenClash..."
/etc/init.d/openclash enable || true
/etc/init.d/openclash restart || true

echo "✅ 部署完成！请确认配置。"

# 删除自身脚本
rm -- "$0"

exit 0
