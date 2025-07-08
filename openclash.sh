#!/bin/bash

# =====================================
# 🪐 OpenClash 自动管理一键初始化脚本
# =====================================

echo "🪐 开始更新软件源并安装依赖..."
opkg update
opkg install python3 python3-pip inotifywait wget unzip kmod-fs-cifs ksmbd-server ksmbd-tools luci-app-ksmbd || true
pip3 install pyyaml || true

echo "🌍 下载并解压 OpenClashManage..."
cd /root
wget -O OpenClashManage.rar "https://github.com/foxc888/foxc/raw/refs/heads/main/OpenClashManage.rar"
unzip -o OpenClashManage.rar
rm OpenClashManage.rar

echo "🔐 设置执行权限..."
chmod +x /root/OpenClashManage/jk.sh
chmod +x /root/OpenClashManage/zr.py

# =============== SMB 挂载映射 ===============
echo "🖇️ 配置 SMB 挂载映射..."
uci add ksmbd share
uci set ksmbd.@share[-1].name='OpenClashManage'
uci set ksmbd.@share[-1].path='/root/OpenClashManage/wangluo'
uci set ksmbd.@share[-1].read_only='no'
uci set ksmbd.@share[-1].guest_ok='yes'
uci commit ksmbd
/etc/init.d/ksmbd restart
/etc/init.d/ksmbd enable

# =============== 权限及启动脚本 ===============
echo "🛠️ 设置文件夹读写权限..."
chmod -R 777 /root/OpenClashManage/wangluo

# 配置 jk.sh 守护脚本开机自启
if ! grep -q "OpenClashManage/jk.sh" /etc/rc.local; then
    echo "🚀 写入 jk.sh 到 /etc/rc.local 实现开机自启..."
    sed -i '$i nohup bash /root/OpenClashManage/jk.sh &' /etc/rc.local
    chmod +x /etc/rc.local
fi

# 启动监控脚本
nohup bash /root/OpenClashManage/jk.sh &

# =============== OpenClash 开机自启 ===============
echo "⚙️ 配置 OpenClash 开机自启..."
/etc/init.d/openclash enable

# =============== 完成提示 ===============
echo "✅ OpenClash 自动管理环境部署完成！"
echo "✅ 已挂载 SMB，可在 Windows 网络中访问 /root/OpenClashManage/wangluo 管理节点文件"
echo "✅ 已启动并配置 jk.sh 守护脚本实现自动同步监控"
echo "✅ 如需重启生效，执行 reboot 即可"
