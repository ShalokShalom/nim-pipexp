import unittest

import pipexp

proc plus20(arg0: int): int = arg0 + 20

suite "|":
  test "builtin procs":
    let arg0 = 10
    assert arg0 + 20 == arg0 | +20

  test "1 argument procs":
    let arg0 = 10
    assert plus20(arg0) == arg0 | plus20
    assert plus20(arg0) == arg0 | plus20()
    assert plus20(arg0) == arg0 | plus20(_)


suite "pipe":
  test "1 argument procs":
    let arg0 = 10
    assert plus20(arg0) == pipe(arg0, plus20)
    assert plus20(arg0) == pipe(arg0, plus20())
    assert plus20(arg0) == pipe(arg0, plus20(_))

    let ret1 = pipe arg0:
      plus20
    let ret2 = pipe arg0:
      plus20()
    let ret3 = pipe arg0:
      plus20(_)

    assert plus20(arg0) == ret1
    assert plus20(arg0) == ret2
    assert plus20(arg0) == ret3

