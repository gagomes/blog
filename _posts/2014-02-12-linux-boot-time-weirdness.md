---
layout: post
title: linux boot time weirdness
date:   2014-02-12 00:00:01 +0000
categories: linux kernel
---
One of the recent projects I was responsible for was that of porting an ARM-based Network Switch platform to x86, essentially making it  VMware-friendly (although, as I used KVM for quick development/testing, qemu/kvm and Xen were working also by osmosis.)

One of the on-going sub-projects is that of integrating a limited edition of Cisco’s 5921 Embedded Services Router compiled to run on x86 hardware, specifically as 32bit dynamically compiled binary, which caused us a challenge. Our platform was 64bit, our libc was uCLibc.

A few solutions were considered and the one I decided to stick with was to build glibc via crosstool-ng and use it as a external toolchain. The compilation finished successfully with minimal fuss and below are last few lines of the booted up image which fail.

```
     [ 1.811947] Write protecting the kernel read-only data: 7552k
     [ 1.813656] Failed to execute /init
     [ 1.814278] Kernel panic - not syncing: No init found. Try 
    passing init= option to kernel.
     [ 1.815667] Pid: 1, comm: swapper Not tainted 2.6.31.8 #18
     [ 1.816549] Call Trace:
     [ 1.816977] [] panic+0x75/0x130
     [ 1.817905] [] name_to_dev_t+0x0/0x1e1
     [ 1.818917] [] kernel_init+0x192/0x19d
     [ 1.819884] [] child_rip+0xa/0x20
     [ 1.820980] [] ? kernel_init+0x0/0x19d
     [ 1.821979] [] ? child_rip+0x0/0x20
```

The reason for the failure is non-obvious, but something is wrong with /init. The /init is part of the initramfs, it is essentially the script that is responsible for kicking off the userspace initialisation, including rename the root dev and starting udev to probe for all the hardware and load drivers accordingly, etc.

So the first attempt at understanding the cause of this issue was to supply the parameter init=/bin/bash but this didn’t change the behaviour. I realized, though, that this is at initram stage, so the error is effectively misleading and I decided to try then rdinit=/bin/bash, which resulted in a Segmentation Fault.

At this stage it is clear that userspace is broken but I needed to root cause the issue, so the next obvious step was to try and chroot into the rootfs. This also proved unsuccessful but no obvious error was being shown. So suddenly it dawned on me that this could be a dynamic loader/linker related issue seeing as I had just fiddled with libc.

So I used readelf to find what interpreter bash is requesting

```
readelf -a /bin/bash | grep interpreter
      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
```

And the next step was to verify if the actual file exists. For some unknown reason, buildroot caused the linker to be installed in the /lib instead of /lib64, which all binaries expected, although, in fairness, this may be a bug in our tree as we are using a version that dates to May 2011; A symlink was enough to sort this out:

```
ln -s /lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
```