#!/usr/bin/env bash
mkdir -p share
qemu-system-x86_64 \
 -kernel kernel-build/arch/x86_64/boot/bzImage \
 -initrd busybox-build/_install/initramfs \
 -append "console=ttyS0" \
 --nographic -no-reboot \
 -virtfs local,path=share,mount_tag=host0,security_model=mapped,id=host0
