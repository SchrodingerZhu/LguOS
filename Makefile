all: kernel-build/arch/x86_64/boot/bzImage busybox-build/_install/initramfs

x86_64-linux-musl-cross.tgz:
	wget http://musl.cc/x86_64-linux-musl-cross.tgz -O x86_64-linux-musl-cross.tgz

x86_64-linux-musl-cross: x86_64-linux-musl-cross.tgz
	tar xaf x86_64-linux-musl-cross.tgz

kernel-build/Makefile: kernel-config
	mkdir kernel-build
	cp kernel-config kernel-build/.config
	make LLVM=1 -C linux O=$(shell realpath kernel-build) oldconfig 

kernel-build/arch/x86_64/boot/bzImage: kernel-build/Makefile
	make LLVM=1 -C linux O=$(shell realpath kernel-build) -j$(shell grep -c '^processor' /proc/cpuinfo)

busybox-build: x86_64-linux-musl-cross
	mkdir -p busybox-build
	LDFLAGS="--static" make -C busybox O=$(shell realpath busybox-build) \
	    CROSS_COMPILE=$(shell realpath x86_64-linux-musl-cross/bin/x86_64-linux-musl-) \
	    defconfig

busybox-build/_install: busybox-build x86_64-linux-musl-cross
	LDFLAGS="--static" make -C busybox O=$(shell realpath busybox-build) \
	   CROSS_COMPILE=$(shell realpath x86_64-linux-musl-cross/bin/x86_64-linux-musl-) \
	   -j$(shell grep -c '^processor' /proc/cpuinfo) install

busybox-build/_install/init: init
	cp init busybox-build/_install/init

busybox-build/_install/initramfs: busybox-build/_install busybox-build/_install/init
	cd busybox-build/_install/ && \
	find . -print0 | cpio --null -ov --format=newc | zstd -19 -o initramfs

clean:
	rm -rf kernel-build busybox-build
	
clean-toolchain:
	rm -rf x86_64-linux-musl-cross.tgz x86_64-linux-musl-cross
