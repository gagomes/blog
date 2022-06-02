---
layout: post
title: knock, knock who’s calling?
date:   2013-06-19 00:00:01 +0000
categories: python oop
---

One of the many great advantages of python is introspection. Python’s introspective design allows you to read, modify, write (and in some cases call) the functions, objects, variables defined in the current running instance of python. Amongst other things it allows for your programs to do smart things such as listing all methods and properties of an object instance, obtaining a list of frames and accessing your call stack.

One such case I needed to use introspection was in a debug function where I want it to print who the caller is, so that if I get a flood of debug messages, I know what their caller was. For my own needs, I don’t need to be specific as to the frame address because I know each parent would only have a single call to my debugging function, I just can’t tell which order they would be calling in due to the dynamic nature of my program.

That said, there is a simple way to do this. Python comes bundled with an extensive library of modules, one of which is the inspect module. This module defines a function called stack which returns a list of records for the stack above the caller’s frame, where 0 is the parent function to your inspect.stack() call and -1 (which is an alias to the last item in a list) is the <module>, or the bare python interpreter prior to __main__. The return list is essentially a list of record frames packed as tupples. Each record contains a frame object, filename, line number, function name, a list of lines of context, and index within the context.

```python
#!/usr/bin/python
import inspect

def foo():
    debug("starting...")

def main():
    foo()

def debug(x):
    print "caller=%s :: %s" % (inspect.stack()[1][3], x)

if __name__ == '__main__':
    main()
```



The output is as follows:

```shell
$ python foo.py
caller=foo :: starting...
```