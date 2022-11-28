# Nim-pipexp

Expression-based pipe operators with placeholder argument for Nim.

## Nim already has UCS, dup and with

### UCS
Nim already has a nice syntax sugar called
"[Universal Call Syntax](https://en.wikipedia.org//wiki/Uniform_Function_Call_Syntax)"
or UCS that lets you call procedures on arguments with the popular 'dot'
notation of other object-oriented languages. So this already acts
like a simple chaining pipe operator for functions with
first argument on the left-hand side:

```nim
proc plus20(arg0: int): int = arg0 + 20
proc plus(arg0, x: int): int = arg0 + x

let a = 10 . plus20
10 . plus20 . echo
10 . plus20 . plus20() . echo
10 . plus(20) . echo
10 . plus(30) . plus(40) . echo
```

However you can't use this syntax if you want
to pipe into procs on arguments other than the
first one.

## Usage

With `pipexp` you can still use a UCS syntax, but also
use a placeholder "`_`" argument where the return of
the previous pipe is inserted to:

*I don't know if I'll keep `|` as the operator, it's still early*

```nim
import pipexp
proc plus20(arg0: int): int = arg0 + 20
proc plus_a0(arg, x: int): int = arg + x
proc plus_a1(x, arg: int): int = arg + x

let a = 10 | plus20
10 | plus20 | echo
10 | plus20 | plus20() | plus20(_) | echo
10 | plus_a0(20) | echo
10 | plus_a0(_,20) | echo
10 | plus_a1(20,_) | echo
10 | plus_a1(30,_) | plus_a1(40,_) | echo
```

You can also make use of a pipeline macro called `pipe`:
```nim
let b = pipe(10, plus20)
pipe(10, plus20, echo)
pipe(10, plus20, plus20(), plus20(_), echo)
pipe(10, plus_a1(30,_), plus_a1(40,_), echo)

let c = pipe 10:
  plus20
  plus_a0(40)
  plus_a1(30,_)
```

## To-do
- Support anonymous procs
- Other features like [Pipe.jl](https://github.com/oxinabox/Pipe.jl)
- Allow configuring the placeholder symbol
- Allow multiple instances of "`_`"

Maybe:
- Other operators like [magrittr](https://github.com/tidyverse/magrittr)

## Similar
- [Pipe](https://github.com/CosmicToast/pipe)
- [Pipelines](https://github.com/calebwin/pipelines)

## See also
- [Pipe proposal in JavaScript](https://github.com/tc39/proposal-pipeline-operator)
