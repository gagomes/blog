---
layout: post
title: serving confluence via nginx
date:   2015-05-14 00:00:01 +0000
categories: blog 
---

I’m a big fan of Atlassian products, so I bought myself a personal license for Confluence. In this post, I will be documenting my nginx and confluence setup as I struggled to find succinct documentation online, including in the official documentation.

The problem statement: I run nginx configured to serve the domain promisc.org over http and https. I also run Confluence on the same host on a higher port presented on traditional http. I wanted to be able to browse https://promisc.org/confluence and reach the container’s pages seamlessly over a secure channel.

To do so, I had to setup a reverse proxy. This is relatively straight-forward, In your server block, just add a new location pointing to where you want confluence to be mapped to, e.g /confluence. Here’s the example config I used:

```
    location /confluence {
        proxy_read_timeout 240;
        proxy_set_header X-Forwarded-Host $host;        
        proxy_set_header X-Forwarded-Server $host;        
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;        
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8000;
    }
```

The stanza above defines a set of variables, which we now need to tell Tomcat (the container that runs confluence) what to do with. We also need to tell it that what port we’re proxying from. The relevant change are highlighted in bold.

from confluence/conf/server.xml

```
<Connector className="org.apache.coyote.tomcat4.CoyoteConnector" 
                   port="8000" 
                   minProcessors="5"
                   maxProcessors="75"
                   enableLookups="false" 
                   redirectPort="8443" 
                   acceptCount="10" 
                   debug="0" 
                   connectionTimeout="20000"
                   useURIValidationHack="false" 
                   URIEncoding="UTF-8"
                   proxyName="www.promisc.org" 
                   proxyPort="443" />

<Engine name="Standalone" 
        defaultHost="localhost" 
        debug="0">

  <Host name="localhost" 
        debug="0" 
        appBase="webapps" 
        unpackWARs="true" 
        autoDeploy="false">

    <Context path="/confluence" 
             docBase="../confluence" 
             debug="0" 
             reloadable="false" 
             useHttpOnly="false">
             <Manager pathname="" />
    </Context> 
    <Valve className="org.apache.catalina.valves.RemoteIpValve"
           remoteIpHeader="x-forwarded-for"
                   remoteIpProxiesHeader="x-forwarded-by"
                   protocolHeader="x-forwarded-proto" 
/></Host>
</Engine>
```

And that’s all. With these small changes, it should be possible for you to serve Confluence or Jira under nginx.