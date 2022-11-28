import
  std/macros


proc underscorePos(n: NimNode): int =
  for i in 1 ..< n.len:
    if n[i].eqIdent("_"): return i
  return 0


macro `|`*(arg, fn: untyped): untyped =
  case fn.kind:
  of nnkIdent:
    result = newCall(fn, arg)
  of nnkCall, nnkCommand:
    let u = underscorePos(fn)
    result = newNimNode(nnkCall)
      .add(fn[0])
    for i in 1..u-1: result.add fn[i]
    result.add(arg)
    for i in u+1..fn.len-1: result.add fn[i]
  else:
    result = fn
    result.insert(1, arg)


macro pipe*(arg: untyped, fns: varargs[untyped]): untyped =
  result = arg
  for fn in fns:
    case fn.kind:
    of nnkIdent:
      result = newCall(fn, result)
    of nnkCall, nnkCommand:
      let
        u = underscorePos(fn)
        arg = result
      result = newNimNode(nnkCall)
        .add(fn[0])
      for i in 1..u-1: result.add fn[i]
      result.add(arg)
      for i in u+1..fn.len-1: result.add fn[i]
    of nnkStmtList, nnkStmtListExpr:
      for stmt in fn.children:
        case stmt.kind:
        of nnkIdent:
          result = newCall(stmt, result)
        of nnkCall, nnkCommand:
          let
            u = underscorePos(stmt)
            arg = result
          result = newNimNode(nnkCall)
            .add(stmt[0])
          for i in 1..u-1: result.add stmt[i]
          result.add(arg)
          for i in u+1..stmt.len-1: result.add stmt[i]
        else:
          result = newCall(fn, result)
    else:
      result = newCall(fn, result)
