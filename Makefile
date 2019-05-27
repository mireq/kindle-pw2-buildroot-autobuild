
.PHONY: all buildroot distclean

PATH := $(PATH):$(shell pwd)/crosstool/bin

KINDLE=pw2

CROSS-TOOL-VERSION=crosstool-ng-1.24.0
CROSS-TOOL-DIR=crosstool-ng
CROSS-TOOL-BIN-DIR=crosstool
X-TOOLS-DIR=x-tools
BUILDROOT-DIR=buildroot

all: buildroot

.downloaded_ct_ng:
	wget https://github.com/crosstool-ng/crosstool-ng/archive/${CROSS-TOOL-VERSION}.tar.gz
	tar -xvzf ${CROSS-TOOL-VERSION}.tar.gz
	mv crosstool-ng-${CROSS-TOOL-VERSION} ${CROSS-TOOL-DIR}
	touch .downloaded_ct_ng

.bootstrap_ct_ng: .downloaded_ct_ng
	cd ${CROSS-TOOL-DIR}&&./bootstrap
	touch .bootstrap_ct_ng

.installed_ct_ng: .bootstrap_ct_ng
	cd ${CROSS-TOOL-DIR}&&./configure --prefix=$(shell pwd)/${CROSS-TOOL-BIN-DIR}
	sed -i "s/.*Recursion detected.*//g" ${CROSS-TOOL-DIR}/Makefile
	cd ${CROSS-TOOL-DIR}&&make
	cd ${CROSS-TOOL-DIR}&&make install
	touch .installed_ct_ng

.installed_xtools: .installed_ct_ng
	mkdir -p ${X-TOOLS-DIR}
	cd ${X-TOOLS-DIR}&&cat ../ng-${KINDLE}-config > .config
	cd ${X-TOOLS-DIR}&&ct-ng oldconfig
	cd ${X-TOOLS-DIR}&&ct-ng updatetools
	cd ${X-TOOLS-DIR}&&ct-ng build
	touch .installed_xtools

.downloaded_buildroot:
	git clone -b 2019.02.x --single-branch --depth 1 https://github.com/mireq/buildroot-kindle-pw2 ${BUILDROOT-DIR}
	touch .downloaded_buildroot

.configured_buildroot: .downloaded_buildroot .installed_xtools
	cp buildroot-config ${BUILDROOT-DIR}/configs/kindle_defconfig
	echo "BR2_TOOLCHAIN_EXTERNAL_PATH=\"$(shell pwd)/x-tools/arm-kindlepw2-linux-gnueabi\"" >> ${BUILDROOT-DIR}/configs/kindle_defconfig
	touch .configured_buildroot

.installed_buildroot: .configured_buildroot
	make -C ${BUILDROOT-DIR} kindle_defconfig
	touch .installed_buildroot_stage1

buildroot: .installed_buildroot
	make -C ${BUILDROOT-DIR}

distclean:
	rm -rf ${CROSS-TOOL-DIR}
	rm -f ${CROSS-TOOL-VERSION}.tar.gz
	rm -rf ${CROSS-TOOL-BIN-DIR}
	rm -rf ${X-TOOLS-DIR}
	rm -rf ${BUILDROOT-DIR}
	rm -f .downloaded_ct_ng
	rm -f .bootstrap_ct_ng
	rm -f .installed_ct_ng
	rm -f .installed_xtools
	rm -f .downloaded_buildroot
	rm -f .configured_buildroot
