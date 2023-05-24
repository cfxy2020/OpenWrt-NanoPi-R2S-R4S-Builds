#!/bin/bash
ROOTDIR=$(pwd)
echo $ROOTDIR
if [ ! -e "$ROOTDIR/build" ]; then
    echo "Please run from root / no build dir"
    exit 1
fi

OPENWRT_BRANCH=21.02

cd "$ROOTDIR/build"

# install feeds
cd openwrt

# clone stangri repo
# rm -rf stangri_repo
# git clone https://github.com/stangri/source.openwrt.melmac.net stangri_repo

git clone https://github.com/NueXini/NueXini_Packages.git package/feeds/NueXini_Packages
git clone https://github.com/chenhw2/luci-app-aliddns.git package/feeds/luci-app-aliddns

./scripts/feeds update -a

# Fix Bug：无法编译最新版的v2ray-core
rm -rf feeds/packages/lang/golang
svn co https://github.com/openwrt/packages/branches/openwrt-22.03/lang/golang feeds/packages/lang/golang

# replace vpn routing packages
rm -rf feeds/packages/net/vpn-policy-routing/
cp -R $ROOTDIR/openwrt-$OPENWRT_BRANCH/patches/package/vpn-policy-routing feeds/packages/net/
rm -rf feeds/luci/applications/luci-app-vpn-policy-routing
cp -R $ROOTDIR/openwrt-$OPENWRT_BRANCH/patches/package/luci-app-vpn-policy-routing feeds/luci/applications/

# copy patch for nodejs not building
cp $ROOTDIR/openwrt-21.02/patches/node/010-execvp-arg-list-too-long.patch feeds/packages/lang/node/patches/

./scripts/feeds update -i && ./scripts/feeds install -a

# 对于luci-app-aliddns，编译 po2lmo (如果有po2lmo可跳过)
pushd package/feeds/luci-app-aliddns/tools/po2lmo
make && sudo make install
popd

sed -i 's/dnsmasq/dnsmasq-full/g' ./include/target.mk

# Time stamp with $Build_Date=$(date +%Y.%m.%d)
MANUAL_DATE="$(date +%Y.%m.%d) (manual build)"
BUILD_STRING=${BUILD_STRING:-$MANUAL_DATE}
echo "Write build date in openwrt : $BUILD_DATE"
echo -e '\n'${BUILD_STRING}'\n'  >> package/base-files/files/etc/banner
#sed -i '/DISTRIB_REVISION/d' package/base-files/files/etc/openwrt_release
#echo "DISTRIB_REVISION='${BUILD_STRING}'" >> package/base-files/files/etc/openwrt_release
sed -i '/DISTRIB_DESCRIPTION/d' package/base-files/files/etc/openwrt_release
echo "DISTRIB_DESCRIPTION='${BUILD_STRING}'" >> package/base-files/files/etc/openwrt_release
sed -i '/luciversion/d' feeds/luci/modules/luci-base/luasrc/version.lua

rm -rf .config
