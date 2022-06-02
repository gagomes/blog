---
layout: post
title: cloning all github repositories
date:   2015-07-17 00:00:01 +0000
categories: c linux
---

I was searching the web for a quick way to clone all of the XenServer repositories on github with little effort and came across this snippet on GIST by caniszczyk:

```
curl -s https://api.github.com/orgs/twitter/repos?per_page=200 | ruby -rubygems -e 'require "json"; JSON.load(STDIN.read).each { |repo| %x[git clone #{repo["ssh_url"]} ]}'
```

It worked neatly. Although, the sequential nature of the git-clone loop caused it to take a considerable amount of time to complete. This prompted me to think about how could I parallelize the git-clone and re-write it as a python oneliner instead, so my version of the script above, as translated to curl/python/xargs can be found below. The xargs -P command is used to control how many parallel processes are spawned, adjust according to your bandwidth/computer.

```
curl -s https://api.github.com/orgs/xenserver/repos?per_page=200 | python -c 'import sys,json; print "\n".join(map(lambda x: x.get("ssh_url"), json.loads(sys.stdin.read())))' |xargs -L1 -P 10 git clone
```