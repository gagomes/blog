---
layout: post
title: notes on blktap
date:   2013-03-03 00:00:01 +0000
categories: xen linux storage
---

Old notes taken from a glance at blktap and discussions with Daniel Stodden.

```
blkfront:
 * possible races in xenstore (xenstore paths removed by 3rd party domains)
 * XenbusStateInitWait -> waiting on the other end to "connect"
 * udev scripts / event based (blkfront hot-plug scripts, perhaps?)

Data Path:
 * gendisk (generic disk) gendisk.h

Ring IO
 * blkif_request's are misaligned
   * a potential solution requires entire backend redesign 
     and breaks compatibility

blktap
 * kernel code has margin for improvement around the blkrequest dequeing
 * tap-ctrl manages the devices in /dev/xen/blktap-2/

[block ] tapdev -- minor 0...2**24
                   major 252 (typically, may occasionally differ)

[char  ] blktap -- minor 0...2**24
            major 25? (go figure out the number :-) )

n.b: Linux shows these in /proc/devices

        in drivers/block/xen-blkback
  .-------.         
  | blkbk |  .--------------- [xenbus.c] [control, xenwatchd]
  \------/   | \
             |   \___________ [blkback.c]
             |
             |__ Interurpts (Xen Event Channels)
             |
             |__ xenblkd (kernel thread -- ring-io/blk-io dispatcher/completer)

 nodes:
 - control (allocate() in blktap)
 - fork /usr/libexec/tapdisk 

note: blktap is meant to support userspace IO to blk devices

 -----------------
 | ring           |    32 requests
 ------------------    11 pages per request
 | req 0          |    131072 bytes (aka 128MiB) 
 ------------------
 | req 1          |
 ------------------
 | req 2          |
 ------------------
 | req ...        |
 ------------------
 | req 31         |
 ------------------

 ioctl -> create_tapdev
          kick (_tapdev?)

  blktap_ctrl_ioctl() -- allocate/free minor

   blktap_control_create_tap
   blktap_control_get_minor() 

sysfs:
=============

/sys/class/blktap2

blktap pooling (See debug sysfs node)

tap-ctl list

/usr/lib/blktap/tapdisk

tap-ctl open -m 0 -p 18523 -a aio:/var/tmp/disk.raw
tap-ctl create -a aio:/var/tmp/disk.raw (shortcut?)

tap-ctl create  -> allocate -> spawn   -> attach -> open
tap-ctl destroy -> close    -> dettach -> free

No love for sysfs, but some users out there are still using it.

    -----> ( ring-io )
    |
    v
  -------                  ----------                    ------------­
  [ vbd ]  --------------- [ server ] ------------------ [ scheduler ]
  -------                  ----------                    -------------
    |
     \
       \
     \ ---------                --------
           [ image ] --- > -------- [ leaf ] 
           ---------                --------
              |  
              v
              |
           ---------
           [ image ]
           ---------

 * scheduler is just an eventloop (e.g does not follow any 
   scheduling algorithms.)

 * xenclient uses libvhdio small library

 * vbd requests are in struct td_vbd_request. Every request has to finish 
   in 2 mins. Can result from Network congestions or bugs.

 * td_forward_request -- for the case of multi-chained images

* tapdisk-vbd cleanup code
* recursion in queing code

---------------------------------------------------------------------

   [block io]             ___                   <AIO>
      |                  |   \ [filesystems] -----------> [sda1]
   [tapdev] ---|         |
               |         |
   -----------------------------------------------
               |         |
           [ blktap ] --/

  iocontext.h -- QoS/CFQ

-------------------------------------------------------------------
```