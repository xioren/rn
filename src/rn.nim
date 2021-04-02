import os, strutils, strformat, re, parseopt


proc makeUnique(oldFilepath: string): string =
  ## make filenames unique
  var
    n = 1
    newFilepath: string
  let
    (dir, name, ext) = splitFile(oldFilepath)

  newFilepath = fmt"{dir}/{name}-{n}{ext}"
  while fileExists(newFilepath):
    n += 1
    newFilepath = fmt"{dir}/{name}-{n}{ext}"
  result = newFilepath


proc rename(this: string|Regex, that = "") =
  ## replace "this" string or regex pattern with "that" string in filenames
  var
    newFilepath: string
    newFilename: string

  for kind, oldFilepath in walkDir(getCurrentDir()):
    if kind == pcFile and not isHidden(oldFilepath):
      let (oldHead, oldFilename, ext) = splitFile(oldFilepath)

      if oldFilename.contains(this):
        newFilename = oldFilename.replace(this, that) & ext
        newFilepath = joinPath(oldHead, newFilename)

        if fileExists(newFilepath):
          if sameFileContent(oldFilepath, newFilepath):
            discard tryRemoveFile(oldFilepath)
            continue
          else:
            newFilepath = makeUnique(newFilepath)

        moveFile(oldFilepath, newFilepath)
        echo oldFilename, ext, " --> ", newFilename


proc renameRec(this: string|Regex, that = "") =
  ## recursively replace "this" string or regex pattern with "that" string in filenames
  var
    newFilepath: string
    newFilename: string

  for oldFilepath in walkDirRec(getCurrentDir()):
    if "/." notin oldFilepath:
      let (oldHead, oldFilename, ext) = splitFile(oldFilepath)

      if oldFilename.contains(this):
        newFilename = oldFilename.replace(this, that) & ext
        newFilepath = joinPath(oldHead, newFilename)

        if fileExists(newFilepath):
          if sameFileContent(oldFilepath, newFilepath):
            discard tryRemoveFile(oldFilepath)
            continue
          else:
            newFilepath = makeUnique(newFilepath)

        moveFile(oldFilepath, newFilepath)
        echo oldFilename, ext, " --> ", newFilename


when isMainModule:
  ## replace strings in filenames, takes 1 or two arguments,
  ## if second argument is absent, replaces first argument with empty string.
  let args = commandLineParams()
  const
    version = "0.0.1"
    help = """
  Usage: rn [options] this[ that]

  Options:
    -r, --recursive                 Rename files recursively
    -p, --pattern                   Use a regex pattern

  Examples:
    rn "My Files" my_files
    rn -r .
    rn --pattern "\s+" _
  """
    sNoVal = {'r', 'e'}
    lNoVal = @["recursive", "regex"]
  var
    rec = false
    reg = false

  if args.len < 1:
    echo "<no argument>"
  else:
    for kind, key, val in getopt(shortNoVal=sNoVal, longNoVal=lNoVal):
      case kind
      of cmdEnd:
        doAssert(false)
      of cmdArgument:
        discard
      of cmdShortOption, cmdLongOption:
        case key
          of "r", "recursive":
            rec = true
          of "p", "pattern":
            reg = true

    if rec and reg:
      if args.len == 3:
        renameRec(re(args[^1]))
      else:
        renameRec(re(args[^2]), args[^1])
    elif rec:
      if args.len == 2:
        renameRec(args[^1])
      else:
        renameRec(args[^2], args[^1])
    elif reg:
      if args.len == 2:
        rename(re(args[^1]))
      else:
        rename(re(args[^2]), args[^1])
    else:
      if args.len == 1:
        rename(args[0])
      else:
        rename(args[0], args[1])
