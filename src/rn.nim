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


proc rename(this: string | Regex, that = "", dry: bool) =
  ## replace "this" string or regex pattern with "that" string in filenames
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
            # BUG: erroneously removes non-duplicate files when new name == old name
            # discard tryRemoveFile(oldFilepath)
            continue
          else:
            newFilepath = makeUnique(newFilepath)

        try:
          if not dry:
            moveFile(oldFilepath, newFilepath)
          echo oldFilename, " --> ", newFilename
        except OSError:
          echo "error renaming ", oldFilename


proc renameRec(this: string | Regex, that = "", dry: bool) =
  ## recursively replace "this" string or regex pattern with "that" string in filenames
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
            # BUG: erroneously removes non-duplicate files when new name == old name
            # discard tryRemoveFile(oldFilepath)
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
    version = "0.0.4"
    help = """
  Usage: rn [options] this[ that]

  Options:
    -r, --recursive                 Rename files recursively
    -p, --pattern                   Regex or glob pattern
    -d, --dry                       Dry run

  Examples:
    rn "&" and
    rn -r this
    rn -p "\s+" -
    rn -p --dry "*-copy" file
  """
    sNoVal = {'r', 'd', 'p'}
    lNoVal = @["recursive", "dry", "pattern"]
  var
    rec = false
    dry = false
    reg = false
    cmdArgs: seq[string] = @[]

  if args.len < 1:
    echo "<no argument>"
  else:
    for kind, key, val in getopt(shortNoVal=sNoVal, longNoVal=lNoVal):
      case kind
      of cmdEnd:
        assert false
      of cmdArgument:
        cmdArgs.add(key)
      of cmdShortOption, cmdLongOption:
        case key
          of "h", "help": echo help;quit(0)
          of "v", "version": echo version;quit(0)
          of "r", "recursive":
            rec = true
          of "p", "pattern":
            reg = true
          of "d", "dry":
            dry = true

    if rec and reg:
      if cmdArgs.len == 2:
        renameRec(re(cmdArgs[0].replace("*", ".+")), cmdArgs[1], dry)
      else:
        renameRec(re(cmdArgs[0].replace("*", ".+")), dry=dry)
    elif rec:
      if cmdArgs.len == 2:
        renameRec(cmdArgs[0], cmdArgs[1], dry)
      else:
        renameRec(cmdArgs[0], dry=dry)
    elif reg:
      if cmdArgs.len == 2:
        rename(re(cmdArgs[0].replace("*", ".+")), cmdArgs[1], dry)
      else:
        rename(re(cmdArgs[0].replace("*", ".+")), dry=dry)
    else:
      if cmdArgs.len == 2:
        rename(cmdArgs[0], cmdArgs[1], dry)
      else:
        rename(cmdArgs[0], dry=dry)
