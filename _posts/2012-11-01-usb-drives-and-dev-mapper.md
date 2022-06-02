---
layout: post
title: USB drives and the device mapper
date: 2012-11-01
categories: linux storage
comments: true
---

My desk is a mess of cables. Off the top of my head, I have 6 power cords, 2 power strips daisy chained, 7 USB cables, 4 ethernet cables, 2 serial cables and I’m quite sure that it wouldn’t get any upvotes on r/cableporn (SFW). Occasionally, I pull the wrong cable. Today I pulled the plug on one of my external hard-drives by accident. After re-plugging it in and subsequently trying to access the mount point, I observed the following errors:

``` shell
root@goncalo-pc:~#  cd /media/disk1
root@goncalo-pc:/media/disk1#  ls
ls: cannot access music: Input/output error
ls: cannot access hs: Input/output error
ls: cannot access goncalog: Input/output error
ls: cannot access backup-laptop: Input/output error
ls: cannot access conf: Input/output error
```

So I turned on the hard-disk and noticed Linux attributed it a different name (now being seen as sdd) I also noticed the device sdb was still alive, albeit as a stale device and still enslaved by dm-0 as well. Any form of IO to either of these devices would yield an immediate IO error. The solution, in this case, was trivial (though overtime I have become more and more familiar with Linux storage related problems): un-mount the mount-point to clean any filesystem/VFS layer references AND use dmsetup to remove the device mapping.

``` shell
# umount /media/disk1
# dmsetup remove /dev/dm-0
```

Finally, re-activate the volume group and all its logical volumes and mount.

``` shell
# vgchange -a y
  1 logical volume(s) in volume group "vgdep" now active
# mount /dev/vgdep/lvroot /media/disk1
```