---
layout: post
title: nginx migration
date:   2015-05-13 00:00:01 +0000
categories: blog networking
---

Migrating to nginx and enabling https support has been on my backlog for a while and now I finally got around to do it. It was mostly a breeze, however, there were a couple of issues, particularly with proxying and serving Confluence from an http endpoint on an https one (I will document that in a separate post.) The certificates on the website are offered by cacert which provides certificates for free analogous to those you can make yourself (aka self-signed certificates) and so, unless you have imported the root CA, you will see a warning message in your browser. You should be able to ignore it. There is some documentation here.