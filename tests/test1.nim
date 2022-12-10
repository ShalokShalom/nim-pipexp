import unittest

import pipexp

proc plus20(arg0: int): int = arg0 + 20
proc plus30(arg0: int): int = arg0 + 30
proc mul3(arg0: int): int = arg0 * 3
proc plus20Multi(arg1, arg2, arg3: int): int = arg1 + arg2 + arg3 + 20
proc identityproc(x: proc): proc = x

import math
proc power10Sum[T](A: openArray[T]): T =
  let len = A.len
  for i in 0 ..< len:
    result +=  A[i] * 10^(len-i-1)


suite "|":
  let
    arg0 = 10
    A0 = @[1,2,3,4]

  test "builtin procs":
    check:
      arg0 + 20 == arg0 | +20
      arg0 - 15 == arg0 | - 15
      arg0 * 2 == arg0 | *2
      arg0 / 2 == arg0 | /2
      succ(arg0) == arg0 | succ
      pred(arg0) == arg0 | pred

      true and true == true | and(true)
      true or false == true | or(false)
      true xor false == true | xor(false)
      # `not` cannot be natively used
      #not true == true | not()

      (arg0 == arg0) == (arg0 | == arg0)
      (arg0 != arg0) == (arg0 | != arg0)
      (arg0 <= arg0+1) == (arg0 | <=(arg0+1))
      (arg0 >= arg0+1) == (arg0 | >=(arg0+1))
      (arg0 < arg0+1) == (arg0 | <(arg0+1))
      (arg0 > arg0+1) == (arg0 | >(arg0+1))
      arg0 in [arg0,0] == arg0 | in [arg0,0]

      A0[2] == A0 | `[]`(2)
      A0[1..3] == A0 | `[]`(1..3)

  test "1 argument procs":
    check:
      plus20(arg0) == arg0 | plus20
      plus20(arg0) == arg0 | plus20()
      plus20(arg0) == arg0 | plus20(_)

    test "pipelines":
      check:
        plus30(plus20(arg0)) == arg0 | plus20 | plus30
        plus20(plus30(arg0)) == arg0 | plus30 | plus20
        plus20(plus20(arg0)) == arg0 | plus20() | plus20
        plus20(plus20(arg0)) == arg0 | plus20 | plus20()
        plus20(plus20(arg0)) == arg0 | plus20() | plus20()
        plus20(plus20(arg0)) == arg0 | plus20(_) | plus20(_)

  test "multiple argument procs":
    check:
      plus20Multi(arg0,0,0) == arg0 | plus20Multi(0,0)
      plus20Multi(arg0,0,0) == arg0 | plus20Multi(_,0,0)
      plus20Multi(arg0,arg0,0) == arg0 | plus20Multi(_,_,0)
      plus20Multi(arg0,arg0,arg0) == arg0 | plus20Multi(_,_,_)

    test "pipelines":
      check:
       plus20Multi(plus20Multi(arg0,0,0),1,1) == arg0 | plus20Multi(0,0) | plus20Multi(1,1)
       plus20Multi(plus20Multi(arg0,0,0),1,1) == arg0 | plus20Multi(_,0,0) | plus20Multi(_,1,1)
       plus20Multi(plus20Multi(arg0,1,2),3,4) == arg0 | plus20Multi(1,2) | plus20Multi(3,4)
       plus20Multi(1,plus20Multi(arg0,0,0),1) == arg0 | plus20Multi(0,0) | plus20Multi(1,_,1)
       plus20Multi(1,1,plus20Multi(arg0,0,0)) == arg0 | plus20Multi(0,0) | plus20Multi(1,1,_)

  test "placeholder special":

    test "placeholder indexing":
      check:
        plus20(A0[0]) == A0 | plus20(_[0])
        plus20(A0[^1]) == A0 | plus20(_[^1])

    test "placeholder slicing":
      check:
        power10Sum(A0[0..2]) == A0 | power10Sum(_[0..2])
        power10Sum(A0[0..^1]) == A0 | power10Sum(_[0..^1])

    test "placeholder calling":
      check:
        mul3(plus20(arg0)) == plus20 | mul3(_(arg0))
        mul3(plus20(arg0)) == plus20 | identityproc | mul3(_(arg0))
        plus30(plus20(mul3(arg0))) == mul3 | plus20(_(arg0)) | plus30


  test "lambdas":
    check plus20(arg0) == arg0 | {
      proc (x: int): int = x + 20
    }

    test "pipelines":
      check plus20(arg0 + 40) == arg0 | {
        proc (x: int): int = x + 40
      } | plus20


suite "pipe":
  let
    arg0 = 10
    A0 = @[1,2,3,4]

  test "1 argument procs":
    check:
      plus20(arg0) == pipe(arg0, plus20)
      plus20(arg0) == pipe(arg0, plus20())
      plus20(arg0) == pipe(arg0, plus20(_))

    let ret1 = pipe arg0:
      plus20
    let ret2 = pipe arg0:
      plus20()
    let ret3 = pipe arg0:
      plus20(_)

    check:
      plus20(arg0) == ret1
      plus20(arg0) == ret2
      plus20(arg0) == ret3

  test "multiple argument procs":
    check:
      plus20Multi(arg0,0,0) == pipe(arg0, plus20Multi(0,0))
      plus20Multi(arg0,0,0) == pipe(arg0, plus20Multi(_,0,0))
      plus20Multi(arg0,arg0,0) == pipe(arg0, plus20Multi(_,_,0))
      plus20Multi(arg0,arg0,arg0) == pipe(arg0, plus20Multi(_,_,_))

  test "lambdas":
    check:
      plus20(arg0) == pipe(arg0,
        proc (x: int): int = x + 20
      )

      plus20(arg0) == pipe(arg0, {
        proc (x: int): int = x + 20
      })

    let ret1 = pipe arg0:
      { proc (x: int): int = x + 20 }

    check plus20(arg0) == ret1

  test "placeholder special":

    test "placeholder indexing":
      check:
        plus20(A0[0]) == pipe(A0, plus20(_[0]))
        plus20(A0[^1]) == pipe(A0, plus20(_[^1]))

    test "placeholder slicing":

      let ret1 = pipe A0:
        power10Sum(_[0..2])

      check:
        power10Sum(A0[0..2]) == pipe(A0, power10Sum(_[0..2]))
        power10Sum(A0[0..^1]) == pipe(A0, power10Sum(_[0..^1]))
        power10Sum(A0[0..2]) == ret1

    test "placeholder calling":
      let ret1 = pipe mul3:
        plus20(_(arg0))
        plus30

      check:
        mul3(plus20(arg0)) == pipe(plus20, mul3(_(arg0)))
        mul3(plus20(arg0)) == pipe(plus20, identityproc, mul3(_(arg0)))
        plus30(plus20(mul3(arg0))) == pipe(mul3, plus20(_(arg0)), plus30)
        plus30(plus20(mul3(arg0))) == ret1
