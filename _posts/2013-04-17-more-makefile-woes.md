---
layout: post
title: More makefile woes
date:   2013-04-17 00:00:01 +0000
categories: linux
---

Today I ran into another one of those annoying errors as below:

```
Makefile:321: *** missing `endif'.  Stop.
```

But as it turns out, the endif should have been introduced a couple hundred lines before the end of file. Granted the makefile parser can’t sensibly guess where we want our condition to end and as such does what seems sensible: report at EOF. In this case, it stemmed from my recent refactoring of a multiline rule, leaving the last statement before the endif with a trailing backslash, which caused make to interpret that there was no endif, making the existing one a continuation of the statement previous statement in the process..

Varying degrees of love and hate towards make/buildroot.