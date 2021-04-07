import os, strutils, re, sequtils, strformat


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


proc renameGlob(this, that: string, dry: bool) =
  ## rename files matching "this" glob pattern with "that" string
  var newFilepath: string

  for oldFilepath in walkFiles(joinPath(getCurrentDir(), this)):
    if not isHidden(oldFilepath):
      let (dir, oldFilename, ext) = splitFile(oldFilepath)

      newFilepath = joinPath(dir, addFileExt(that, ext))

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
        echo oldFilename, " --> ", that
      except OSError:
        echo "error renaming ", oldFilename


proc renameGlobRec(this, that: string, dry: bool) =
  ## recursively rename files matching "this" glob pattern with "that" string
  var newFilepath: string

  for dir in walkDirRec(getCurrentDir(), yieldFilter = {pcDir}):
    for oldFilepath in walkFiles(joinPath(dir, this)):
      if "/." notin oldFilepath:
        let (_, oldFilename, ext) = splitFile(oldFilepath)

        newFilepath = joinPath(dir, addFileExt(that, ext))

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
          echo oldFilename, " --> ", that
        except OSError:
          echo "error renaming ", oldFilename


proc main() =
  ##[replace strings in filenames, takes 1 or two arguments,
  if second argument is absent, replaces first argument with empty string.]##
  var args = commandLineParams()
  const
    version = "0.1.0"
    help = """
  Usage: rn [options] this[ that]

  Options:
    -r, --recursive                 Rename files recursively
    -p, --pattern                   Regex match
    -g, --glob                      Glob match
    -d, --dry                       Dry run

  Examples:
    rn "&" and
    rn -r copy
    rn -p "\s+" _
    rn -g --dry "*.jpeg" image
  """
    acceptedArgs = ["-r", "--recursive", "-d", "--dry", "-p", "--pattern",
                    "-g", "--glob", "-h", "--help", "-v", "--version"]
  var
    rec = false
    dry = false
    reg = false
    glob = false

  proc filter(x: string): bool =
    not acceptedArgs.contains(x)

  if args.len < 1:
    echo "<no argument>"
  else:
    for arg in args:
      if arg == "-h" or arg == "--help":
        echo help
        return
      if arg == "-v" or arg == "--version":
        echo version
        return
      if arg == "-r" or arg == "--recursive":
        rec = true
      if arg == "-p" or arg == "--pattern":
        reg = true
      if arg == "-d" or arg == "--dry":
        dry = true
      if arg == "-g" or arg == "--glob":
        glob = true

    keepIf(args, filter)

    if reg:
      if rec:
        if args.len == 2:
          renameRec(re(args[0]), args[1], dry)
        else:
          renameRec(re(args[0]), dry=dry)
      else:
        if args.len == 2:
          rename(re(args[0]), args[1], dry)
        else:
          rename(re(args[0]), dry=dry)
    elif glob:
      if args.len == 2:
        renameGlob(args[0], args[1], dry)
        # TEMP: work around --> no true rec glob proc in std
        if rec:
          renameGlobRec(args[0], args[1], dry)
      else:
        echo "invalid arguments"
    else:
      if rec:
        if args.len == 2:
          renameRec(args[0], args[1], dry)
        else:
          renameRec(args[0], dry=dry)
      else:
        if args.len == 2:
          rename(args[0], args[1], dry)
        else:
          rename(args[0], dry=dry)


when isMainModule:
  main()
