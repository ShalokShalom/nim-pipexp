import
  std/macros

const PLACEHOLDER = "_"

proc placeholderPos(n: NimNode): seq[int] =
  ## Get the index positions of the placeholder arguments
  ## in the procedure call of `n`
  ## Empty seq if no placeholder was found
  # I first get the positions to know if no placeholder was passed
  for i in 1 ..< n.len:
    if n[i].eqIdent(PLACEHOLDER) or
      (n[i].kind in [nnkBracketExpr, nnkCall] and
       n[i][0].eqIdent(PLACEHOLDER)):
      result.add(i)


template addArgsAndPlaceholders(phIndices: seq[int], arg, fn: NimNode): untyped =
  if phIndices.len == 0:
    result.add arg
    for i in 1..fn.len-1:
      result.add fn[i]
  else:
    for i in 1..fn.len-1:
      if i in phIndices:
        if fn[i].eqIdent(PLACEHOLDER):
          # Single _ argument
          result.add arg
        elif (fn[i].kind in [nnkBracketExpr,nnkCall]) and
          fn[i][0].eqIdent(PLACEHOLDER):
          # _ with indexing/slicing or
          # with calling parentheses
          fn[i][0] = arg
          result.add fn[i]
      else:
        result.add fn[i]


macro `|`*(arg, fn: untyped): untyped =
  ## Pipe operator. Calls the procedure operand on the right
  ## with the operand on the left, broadcasting it as
  ## the first argument or on the placeholder "_" arguments

  case fn.kind:
  of nnkIdent:
    # When proc is passed without parentheses: arg0 | fn
    result = newCall(fn, arg)

  of nnkCall, nnkCommand:
    # When proc is passed with arguments: arg0 | fn(...)
    var u: seq[int] = placeholderPos(fn)
    result = newNimNode(nnkCall)
      .add(fn[0])
    if fn.len == 1:
      result.add arg
    else:
      addArgsAndPlaceholders(u, arg, fn)

  of nnkPar, nnkCurly:
    if fn[0].kind == nnkLambda:
      result = newCall(fn[0], arg)
    else:
      raise newException(Exception, "expected Lambda expression after '(' or '{'")

  else:
    result = fn
    result.insert(1, arg)


proc placeholderCall(fn, arg0: NimNode): NimNode =
  case fn.kind:
  of nnkIdent:
    # When proc is passed without parentheses: arg0 | fn
    result = newCall(fn, arg0)

  of nnkCall, nnkCommand:
    # When proc is passed with arguments: arg0 | fn(...)
    let
      u: seq[int] = placeholderPos(fn)
      arg: NimNode = arg0
    result = newNimNode(nnkCall)
      .add(fn[0])
    addArgsAndPlaceholders(u, arg, fn)

  of nnkPar, nnkCurly:
    if fn[0].kind == nnkLambda:
      result = newCall(fn[0], arg0)
    else:
      raise newException(Exception, "expected Lambda expression after '(' or '{'")

  of nnkStmtList, nnkStmtListExpr:
    # When a block of procs is passed as a pipeline:
    # pipe arg0:
    #   fn0
    #   fn1
    result = arg0
    for stmt in fn.children:
      result = placeholderCall(stmt, result)

  else:
    result = newCall(fn, arg0)


macro pipe*(arg: untyped, fns: varargs[untyped]): untyped =
  ## Pipeline macro.
  ## Passes the first argument through a pipeline of
  ## procedure calls from left to right
  ## It may also accept the calls as an indented statement list

  result = arg
  for fn in fns:
    result = placeholderCall(fn, result)
