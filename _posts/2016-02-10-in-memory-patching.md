---
layout: post
title: In memory live patching
date:  2016-02-10 00:20:24 +0000
categories: elf gdb linux-internals
---

A friend approached me asking how he could go about changing the flow of execution of his program during runtime using
a debugger. This sounded interesting because I knew in theory what to do, but had not applied this knowledge since the
early to mid 2000s, when problems like these were my playground as a C programmer yearning to learn about system
internals. After I gave him a rundown and demo, he asked, What if the binary is stripped? Well, that is slightly
different and it is far more complex to put together, but let's give it a go.

Seeing as I can't share my friend's code, I have come up with a simple program to serve as example.

```C
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
	if (argc < 1) {
		printf("Thank you marrrio, *smooch*!\n");
		return (EXIT_SUCCESS);
	}

	printf("Sorry but our princess is in another castle\n");
	return (EXIT_FAILURE);
}
```

The base idea is that, in order for you to get a smooch from the princess, the program above has to take a branch
(line 6) that, under normal circumstances it should not take. Two possible ways of achieving this: by changing the
instructions in the binary file or by attaching a debugger to the process and doing in-memory live patching.

So what can we do when symbolic and/or debugging information is amiss? We have to look at it as a black box, just like
an operating system would. There is a lot of theory which I am going to skip in this article purely for convenience
and time.

Start by compiling the code above with:

```
gcc castle.c -o castle -s -static
```

let's analyze the runtime.

```
$ ./castle
Sorry but our princess is in another castle
```
We executed the program and we branched out. Under normal circumstances, argv will always be populated with the name
that's passed during execution, e.g ./castle in the example above, which has the effect of making argc = 1 and any
subsequent parameter will respectively increase argc as well.

So what's happening under the hood when you execute a process? In a nutshell:

* Your shell forks and executes your binary
  * The kernel maps the binary into memory
  * If the binary is dynamically linked, the kernel looks up the interpreter (runtime dynamic linker) and calls it
    * The dynamic linker builds up a graph of dependencies and calls the program's entry point
      * Entry point is typically a stub with basic initialization. The function name is `_start`.
	* This function calls into the function `__libc_main_start` which is responsible for setting up and calling main's address

Armed with this knowledge, we can start getting down and dirty.

First we start by looking up the address of the `_start` function in the process, also known as the entry point. The
entry point is the first function in your binary that gets called by the kernel. The kernel calls it by setting the IP
register ($RIP) of the process to the address in the `e_entry` field of the elf header of the binary, therefore, this
seems a very good point to start with.

```SH
$ readelf -h castle
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
  Class:			     ELF64
  Data:			      2's complement, little endian
  Version:			   1 (current)
  OS/ABI:			    UNIX - System V
  ABI Version:		       0
  Type:			      EXEC (Executable file)
  Machine:			   Advanced Micro Devices X86-64
  Version:			   0x1
  Entry point address:	       0x400440
  Start of program headers:	  64 (bytes into file)
  Start of section headers:	  4488 (bytes into file)
  Flags:			     0x0
  Size of this header:	       64 (bytes)
  Size of program headers:	   56 (bytes)
  Number of program headers:	 9
  Size of section headers:	   64 (bytes)
  Number of section headers:	 28
  Section header string table index: 27
```

If the binary wasn't stripped, we could simply set the break point on the symbol `_start` using the gdb command `break
_start` but as symbolic information has been stripped, we must therefore use a valid address. Using the readelf tool
part of the binutils package we can find the address of start which is pointed to by the elf entry point at address
0x400440. Let's load our program into gdb, setup a breakpoint in the address 0x400440 and then run the program and
inspect it once it hits the breakpoint.

```
$ gdb -q castle
Reading symbols from castle...(no debugging symbols found)...done.
(gdb) break *0x400440
Breakpoint 1 at 0x400440
(gdb) run
Starting program: /home/goncalog/tmp/b/castle
Breakpoint 1, 0x0000000000400440 in ?? ()
```

So far, so good. gdb confirms there are no debugging symbols found. I built the binary stripped for purposes of
illustrating the scenario when we are in no man's land. So to summarize, so far we loaded the program, set a
breakpoint to the program's entry and ran it. It culminated with the program hitting the breakpoint as soon as the
kernel runs the binary by transferring control to the  entry point or `_start` function. What's next? Let's inspect our
entry point by disassembling it.

```
(gdb) disassemble $rip
No function contains specified address.
```

We attempt to disassemble the instruction pointer register (rip) which is of no help as the disassemble function of
gdb cannot map it to any section in the binary due to missing compound symbolic information. There is, of course an
alternative, which is to decode a range of instructions starting at the address held in the instruction pointer.

```ASM
(gdb) x/20i $rip
=> 0x400440:    xor    %ebp,%ebp
   0x400442:    mov    %rdx,%r9
   0x400445:    pop    %rsi
   0x400446:    mov    %rsp,%rdx
   0x400449:    and    $0xfffffffffffffff0,%rsp
   0x40044d:    push   %rax
   0x40044e:    push   %rsp
   0x40044f:    mov    $0x4005e0,%r8
   0x400456:    mov    $0x400570,%rcx
   0x40045d:    mov    $0x40052d,%rdi
   0x400464:    callq  0x400420 <__libc_start_main@plt>
(...)
```

We look at the first 20 instructions from the address in the entry point where our breakpoint hit and halted the
program's execution. This is also known as the address of the `_start` function and it is responsible for setting up the
stack and calling the linker function `__libc_start_main`, by passing it the address of the program's main (0x40052d) function as well
as constructor and destructor functions `__libc_csu_init` (0x400570) and `__libc_csu_fini` (0x4005e0) as
parameters. The astute reader may notice the string @plt in the symbol name. It says the address of this program is
stored in the Procedure Linkage Table and I'm deliberately skipping the details here for the sake of simplicity, but
plan to document these in a follow up post in larger detail.

Once the `__libc_start_main` gets called, it essentially pops the argc value off the stack and stores the value of stack
pointer register (%rsp),  calls the constructor code in `__libc_csu_init`, followed by the main function passing it the
argc and the top of stack passed as parameters and, assuming main returns normally, it finally calls the destructor
code in `__libc_csu_fini` (typically to perform any atexit handler calls and general libc cleanup)

Aha! So with this information, we can now just set a break point directly in the main function and continue from
there.

```
(gdb) break *0x40052d
Breakpoint 2 at 0x40052d
(gdb) continue
Continuing.
Breakpoint 2, 0x000000000040052d in ?? ()
```

So we hit the breakpoint, we can confirm it because the address of our breakpoint is exactly the address in the
breakpoint return address and now we are inside main. Let's disassemble it using the same command as before:

```
(gdb) x/15i $rip
=> 0x40052d:    push   %rbp
   0x40052e:    mov    %rsp,%rbp
   0x400531:    sub    $0x10,%rsp
   0x400535:    mov    %edi,-0x4(%rbp)
   0x400538:    mov    %rsi,-0x10(%rbp)
   0x40053c:    cmpl   $0x0,-0x4(%rbp)
   0x400540:    jg     0x400553
   0x400542:    mov    $0x4005f8,%edi
   0x400547:    callq  0x400410 <puts@plt>
   0x40054c:    mov    $0x0,%eax
   0x400551:    jmp    0x400562
   0x400553:    mov    $0x400618,%edi
   0x400558:    callq  0x400410 <puts@plt>
   0x40055d:    mov    $0x1,%eax
   0x400562:    leaveq
```

So there are some unexpected symbols being called in this output. Mainly a few calls to puts. Turns out, gcc replaces
calls to `printf` that have no formatting directives with puts instead. This is for optimization purposes in this case,
but let's focus on the bigger picture. This is what's happening in the code above:

* We setup the frame 0x40052d - 0x400538
* We compare argc-0x4(%rbp) to the value of zero.
  * if greater than zero: we continue executing at 0x400553 and find that our princess may no be in this castle
  * if lower than zero: we branch and successfully rescue the princess and move on with our lives

But there is more information in there that can help us understand which call to `puts` is most relevant. Looking into
gdb again, we can print the values put into registers in preparation for the call to puts.

```
(gdb) x/s 0x4005f8
0x4005f8:    "Thank you marrrio, *smooch*!"
(gdb) x/s 0x400618
0x400618:    "Sorry but our princess is in another castle"
```

So with this information we can be sure of which branch we would like to take, so we can make better decisions as to
what we want to live patch. To change the value from memory, we can simply break before the cmp (compare) instruction
is called and change the value of the base pointer register (rbp) at the offset -04 (which is where argc has been
allocated in the stack) and make it a number below 1. This way we can be sure to save the princess.

Let's peek into the value of $rbp-04

```
(gdb) x/x 0x7fffffffde4c
0x7fffffffde4c:    0x01
```

That resonates well with argc == 1. Let's update it to be zero.

```
(gdb) set *0x7fffffffde4c = 0
(gdb) continue
Continuing.
Thank you marrrio, *smooch*!
```

Phew!

## Summary

It's possible to change the memory from a process dynamically and alter it's flow of execution, provided we have some
insider knowledge (eg. source code) or have performed some analysis of the binary' instructions via disassembly. This
practice is often used to debug and validate assumptions, as well as to circumvent software protections. Remember:
With great power, comes great responsibility.

## Exercise

* Can you save the princess without modifying the binary?
* Can you make your change such that next time you run the program it will take your desirable path instead?


# Thanks

I'd like to thank my reviewers, namely: Zbigniew Halas, Volker Eckert and Joao Ferreira, and
lastly to Luis Miguel Silva for enticing my curiosity.

