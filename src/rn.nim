import os, strutils, re, parseopt, strformat


proc makeUnique(oldFilepath: string): string {.inline.} =
  ## make filenames unique
  var
    n = 1
    newFilepath: string
  let
    (dir, name, ext) = splitFile(oldFilepath)

  newFilepath = joinPath(dir, addFileExt(fmt"{name}-{n}", ext))
  while fileExists(newFilepath):
    n += 1
    newFilepath = joinPath(dir, addFileExt(fmt"{name}-{n}", ext))
  result = newFilepath


proc rename(this: Regex, that = "", dry: bool) =
  ## replace "this" regex pattern with "that" string in filenames
  var
    newFilepath: string
    newFilename: string

  for kind, oldFilepath in walkDir(getCurrentDir()):
    if kind == pcFile and not isHidden(oldFilepath):
      let (dir, oldFilename, ext) = splitFile(oldFilepath)

      if oldFilename.contains(this):
        newFilename = oldFilename.replace(this, that)
        newFilepath = joinPath(dir, addFileExt(newFilename, ext))

        if fileExists(newFilepath):
          if sameFileContent(oldFilepath, newFilepath):
            discard tryRemoveFile(oldFilepath)
            continue
          else:
            newFilepath = makeUnique(newFilepath)

        try:
          if not dry:
            moveFile(oldFilepath, newFilepath)
          echo oldFilename, " --> ", newFilename
        except OSError:
          echo "error renaming ", oldFilename


proc renameRec(this: Regex, that = "", dry: bool) =
  ## recursively replace "this" regex pattern with "that" string in filenames
  var
    newFilepath: string
    newFilename: string

  for oldFilepath in walkDirRec(getCurrentDir()):
    # NOTE: ignore non hidden files within hidden directories
    # isHidden wont work here
    if "/." notin oldFilepath:
      let (dir, oldFilename, ext) = splitFile(oldFilepath)

      if oldFilename.contains(this):
        newFilename = oldFilename.replace(this, that)
        newFilepath = joinPath(dir, addFileExt(newFilename, ext))

        if fileExists(newFilepath):
          if sameFileContent(oldFilepath, newFilepath):
            discard tryRemoveFile(oldFilepath)
            continue
          else:
            newFilepath = makeUnique(newFilepath)

        try:
          if not dry:
            moveFile(oldFilepath, newFilepath)
          echo oldFilename, " --> ", newFilename
        except OSError:
          echo "error renaming ", oldFilename


when isMainModule:
  ##[replace strings in filenames, takes 1 or two arguments,
  if second argument is absent, replaces first argument with empty string.]##
  let args = commandLineParams()
  const
    version = "0.0.2"
    help = """
  Usage: rn [options] this[ that]

  Options:
    -r, --recursive                 Rename files recursively
    -d, --dry                       Dry run

  Examples:
    rn "&" and
    rn -r this
    rn W"\s+" -
    rn -d *-copy file
  """
    sNoVal = {'r', 'd'}
    lNoVal = @["recursive", "dry"]
  var
    rec = false
    dry = false
    numCmdArgs = 0

  if args.len < 1:
    echo "<no argument>"
  else:
    for kind, key, val in getopt(shortNoVal=sNoVal, longNoVal=lNoVal):
      case kind
      of cmdEnd:
        assert false
      of cmdArgument:
        numCmdArgs += 1
      of cmdShortOption, cmdLongOption:
        case key
          of "h", "help": echo help;quit(0)
          of "v", "version": echo version;quit(0)
          of "r", "recursive":
            rec = true
          of "d", "dry":
            dry = true

    if numCmdArgs >= 2:
      if rec:
        renameRec(re(args[^2].replace("*", ".+")), args[^1], dry)
      else:
        rename(re(args[^2].replace("*", ".+")), args[^1], dry)
    else:
      if rec:
        renameRec(re(args[^1].replace("*", ".+")), dry=dry)
      else:
        rename(re(args[^1].replace("*", ".+")), dry=dry)
