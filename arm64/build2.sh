#!/bin/bash
# 此脚本在Imagebuilder 根目录运行
source custom-packages.sh
echo "第三方软件包: $CUSTOM_PACKAGES"
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE

if [ -z "$CUSTOM_PACKAGES" ]; then
  echo "⚪️ 未选择 任何第三方软件包"
else
  # ============= 同步第三方插件库==============
  # 同步第三方软件仓库run/ipk
  echo "🔄 正在同步第三方软件仓库 Cloning run file repo..."
  git clone --depth=1 https://github.com/wukongdaily/store.git /tmp/store-run-repo

  # 拷贝 run/arm64 下所有 run 文件和ipk文件 到 extra-packages 目录
  mkdir -p extra-packages
  cp -r /tmp/store-run-repo/run/arm64/* extra-packages/

  echo "✅ Run files copied to extra-packages:"
  ls -lh extra-packages/*.run
  # 解压并拷贝ipk到packages目录
  sh prepare-packages.sh
  echo "打印imagebuilder/packages目录结构"
  ls -lah packages/ |grep partexp
fi

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."

# ============= iStoreOS 24.10 官方集成插件===================
# 定义初始化变量
PACKAGES=""

# ---------------------------------------------------------------------------------------
# 【核心修复部分 - 强制确保这三个核心包存在！】
# ---------------------------------------------------------------------------------------
# 即使 ImageBuilder 列表有，也要强制写入，解决 Cannot install package 错误
# 核心系统
PACKAGES="$PACKAGES uci libuci libuci-lua ubox libubox libubus libubus-lua"
# 核心依赖修复
PACKAGES="$PACKAGES kmod-nf-core kmod-crypto-core coreutils-nohup"
# Web 服务依赖修复
PACKAGES="$PACKAGES uhttpd libopenssl3 libiptext6-0"


# ---------------------------------------------------------------------------------------
# 【精简后的主列表】
# ---------------------------------------------------------------------------------------
PACKAGES="$PACKAGES attr avahi-dbus-daemon avahi-utils badblocks base-files bash blkid block-mount btrfs-progs busybox bzip2 ca-bundle ca-certificates cgi-io chat cifsmount coreutils coreutils-stat coreutils-stty curl davfs2 dbus dropbear e2fsprogs ethtool fdisk firewall4 fstools fwtool getrandom glib2 grub2-efi-arm hd-idle htop ip-full iperf3 ipip ipset iptables-mod-conntrack-extra iptables-mod-extra iptables-nft istoreos-files jansson4 jshn jsonfilter kernel logd losetup lsblk lscpu lua map mount-utils mtd netifd nftables-json openssh-sftp-server openssl-util openwrt-keyring opkg parted partx-utils pciids pciutils ppp ppp-mod-pppoe procd procd-seccomp procd-ujail procps-ng procps-ng-vmstat px5g-mbedtls quickstart relayd resize2fs resolveip rpcbind rpcd rpcd-mod-file rpcd-mod-luci rpcd-mod-rrdns rpcd-mod-ucode samba4-libs samba4-server script-utils shadow smartd smartmontools strace swap-utils sysfsutils sysstat tar taskd tcpdump terminfo ttyd tune2fs ubox uclient-fetch ucode ucode-mod-fs ucode-mod-html ucode-mod-lua ucode-mod-math ucode-mod-ubus ucode-mod-uci ucode-mod-uloop uhttpd uhttpd-mod-ubus unzip urandom-seed urngd usb-modeswitch usbids usbutils usign webdav2 wget-ssl wsdd2 xtables-nft xz xz-utils zlib zram-swap"


# --- 核心驱动 ---
PACKAGES="$PACKAGES kmod-dwmac-rockchip kmod-phy-realtek kmod-libphy kmod-mii kmod-stmmac-core kmod-dma-buf kmod-ata-core kmod-ata-ahci kmod-ata-dwc kmod-usb-core kmod-usb-dwc3 kmod-usb-ehci kmod-usb-xhci-hcd kmod-usb-storage kmod-fs-ext4 kmod-fs-vfat"

# --- LuCI App & I18N ---
PACKAGES="$PACKAGES luci luci-base luci-compat luci-ssl luci-theme-argon luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-light luci-lua-runtime luci-app-argon-config luci-app-cifs-mount luci-app-cpufreq luci-app-diskman luci-app-filetransfer luci-app-firewall luci-app-linkease luci-app-mergerfs luci-app-nfs luci-app-ota luci-app-package-manager luci-app-quickstart luci-app-samba4 luci-app-store luci-app-ttyd luci-app-wol"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn luci-i18n-argon-zh-cn luci-i18n-base-zh-cn luci-i18n-cifs-mount-zh-cn luci-i18n-cpufreq-zh-cn luci-i18n-diskman-zh-cn luci-i18n-filetransfer-zh-cn luci-i18n-firewall-zh-cn luci-i18n-linkease-zh-cn luci-i18n-mergerfs-zh-cn luci-i18n-nfs-zh-cn luci-i18n-ota-zh-cn luci-i18n-package-manager-zh-cn luci-i18n-quickstart-zh-cn luci-i18n-samba4-zh-cn luci-i18n-ttyd-zh-cn luci-i18n-wol-zh-cn"
PACKAGES="$PACKAGES luci-proto-ppp luci-proto-external luci-proto-wireguard" 

# --- 第三方可选插件 ---
PACKAGES="$PACKAGES luci-app-ramfree luci-i18n-ramfree-zh-cn"
PACKAGES="$PACKAGES vlmscd luci-app-vlmcsd" 
PACKAGES="$PACKAGES luci-app-openclash"

# --- 强制排除所有不需要和冲突的包 (重点清理所有冲突和冗余模块) ---
PACKAGES="$PACKAGES \
-kmod-ssb -kmod-bnx2x -kmod-pppol2tp \
-kmod-md-raid0 -kmod-md-raid1 -kmod-md-raid10 -kmod-md-raid456 -mdadm \
-kmod-ata-artop -kmod-ata-nvidia-sata -kmod-ata-piix -kmod-ata-sil -kmod-ata-sil24 \
-kmod-dwmac-sun8i -kmod-phy-smsc -kmod-phy-marvell-10g -kmod-mdio -kmod-vmxnet3 -kmod-bcmgenet \
-kmod-usb-audio -kmod-usb-printer -kmod-video-uvc -kmod-video-videobuf2 \
-rtl8192cu-firmware -kmod-mt76-core -hostapd-common -iw -wifi-scripts \
-odhcp6c -ip6tables-nft -kmod-nf-nat6 -kmod-gre6 \
-ddns-scripts -luci-app-ddns \
-docker -luci-lib-docker -containerd -runc -tini \
-perl -ruby \
-luci-i18n-unishare-zh-cn -luci-app-unishare \
"

# 追加自定义包
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"


# -----------------------------------------------------------
# 【调试步骤：开启详细日志】
# -----------------------------------------------------------
echo "开始构建......打印所有包名===="
echo "$PACKAGES"

# 开始构建
make image PROFILE=generic PACKAGES="$PACKAGES" FILES="files"

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 构建成功."
