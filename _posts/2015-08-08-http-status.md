---
layout: post
title: quick reference for http status codes in python
date:   2015-08-08 00:00:01 +0000
categories: c linux
---

Just came across this while browsing the SimpleHTTPServer code from the standard lib in Python 2.7 and as I’m a sucker for lists of codes and their inherent meanings, I figured I’d post it here (see also signals)

```python
from BaseHTTPServer import BaseHTTPRequestHandler
for code, meaning in BaseHTTPRequestHandler.responses.items():
    print code, "=>", meaning[0]
```

Output:

```
200 => OK
201 => Created
202 => Accepted
203 => Non-Authoritative Information
204 => No Content
205 => Reset Content
206 => Partial Content
400 => Bad Request
401 => Unauthorized
402 => Payment Required
403 => Forbidden
404 => Not Found
405 => Method Not Allowed
406 => Not Acceptable
407 => Proxy Authentication Required
408 => Request Timeout
409 => Conflict
410 => Gone
411 => Length Required
412 => Precondition Failed
413 => Request Entity Too Large
414 => Request-URI Too Long
415 => Unsupported Media Type
416 => Requested Range Not Satisfiable
417 => Expectation Failed
100 => Continue
101 => Switching Protocols
300 => Multiple Choices
301 => Moved Permanently
302 => Found
303 => See Other
304 => Not Modified
305 => Use Proxy
307 => Temporary Redirect
500 => Internal Server Error
501 => Not Implemented
502 => Bad Gateway
503 => Service Unavailable
504 => Gateway Timeout
505 => HTTP Version Not Supported
```