---
layout: post
title: makefile woes
date:   2013-04-15 00:00:01 +0000
categories: linux
---

I’ve been playing with buildroot and trying to make our ARM environment x86* friendly. Occasionally, I get to spend time banging my head against the screen trying to find the cause of certain errors. This happened today with the makefile for our Linux package and after an hour trying to figure out what caused the following error is:

/bin/bash: -c: line 3: syntax error: unexpected end of file
make: *** [/home/g/br86/buildroot/output/build/linux-2.6.31.8/.stamp_copied] Error 1

I finally realized that makefiles pass rule sub-statements as shell one-liners (regardless of how many lines they span in actuality.) In this case, then it is expected that before the end of a control block the marking of end-of-block (usually a semi-colon) be used, but because in an actual shell it is optional and I have never used it if writing the loop in multiple lines I got stuck.

Example: the semicolon after /baz/ is required.

```
rule:
        if [ "`uname -m`" == *86* ]; \
        then \
                foo \
                bar \
                baz ; \
        fi
```