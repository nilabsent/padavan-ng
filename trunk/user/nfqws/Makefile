# https://github.com/bol-van/zapret
# https://github.com/Anonym-tsk/nfqws-keenetic

SRC_ZAPRET = src
SRC_NFQ = nfq
URL_ZAPRET = https://github.com/bol-van/zapret

CFLAGS += $(shell test -d $(SRC_ZAPRET)/.git && echo -n -DZAPRET_GH_VER= && git -C $(SRC_ZAPRET) describe --tags | cut -d '-' -f1)
CFLAGS += $(shell test -d $(SRC_ZAPRET)/.git && echo -n -DZAPRET_GH_HASH= && git -C $(SRC_ZAPRET) rev-parse --short HEAD)

all: clean download
	cp -rf $(SRC_ZAPRET)/$(SRC_NFQ) $(SRC_NFQ)
	patch -p0 -i nfq-compat.patch
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NFQ)

download:
	test -d $(SRC_ZAPRET) || git clone $(URL_ZAPRET) $(SRC_ZAPRET)
	test -d $(SRC_ZAPRET)/.git && git -C $(SRC_ZAPRET) pull || :

clean:
	rm -rf $(SRC_NFQ)

romfs:
	$(ROMFSINST) -p +x $(SRC_NFQ)/nfqws /usr/bin/nfqws
	$(ROMFSINST) -p +x /usr/bin/zapret.sh
	$(ROMFSINST) /usr/share/zapret
