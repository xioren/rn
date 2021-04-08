import os, strutils, re, sequtils, strformat, terminal


proc fancyEcho(this: string | Regex, that, filename: string, ) {.inline.} =
  ## highlight swapped parts
  let parts = filename.split(this)
  stdout.styledWrite(fgCyan, filename & " --> ")

  if parts[0] == filename:
    stdout.styledWriteLine(fgWhite, that)
  else:
    for part in parts[0..^2]:
      stdout.styledWrite(fgCyan, part)
      stdout.styledWrite(fgWhite, that)
    stdout.styledWriteLine(fgCyan, parts[^1])


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
          fancyEcho(this, that, oldFilename)
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
          fancyEcho(this, that, oldFilename)
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
        fancyEcho(this, that, oldFilename)
      except OSError:
        echo "error renaming ", oldFilename


proc renameGlobRec(this, that: string, dry: bool) =
  ## recursively rename files matching "this" glob pattern with "that" string
  var newFilepath: string

  for dir in walkDirRec(getCurrentDir(), yieldFilter = {pcDir}):
    for oldFilepath in walkFiles(joinPath(dir, this)):
      # NOTE: ignore non hidden files within hidden directories
      # isHidden wont work here
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
          fancyEcho(this, that, oldFilename)
        except OSError:
          echo "error renaming ", oldFilename


proc main() =
  ##[replace strings in filenames, takes 1 or two arguments,
  if second argument is absent, replaces first argument with empty string.]##
  const
    version = "0.1.2"
    help = """
  Usage: rn [options] this[ that]

  Options:
    -r, --recursive                 Rename files recursively
    -R, --regex                     Regex match
    -g, --glob                      Glob match
    -d, --dry                       Dry run

  Examples:
    rn "&" and
    rn -r copy
    rn -R "\s+" _
    rn --glob --dry "*.jpeg" image
  """
  # NOTE: basic arg parser implemented as the parseopt module is not suitable
    acceptedOpts = ["-r", "--recursive", "-d", "--dry", "-R", "--regex",
                    "-g", "--glob", "-h", "--help", "-v", "--version"]
  var
    args = commandLineParams()
    rec = false
    dry = false
    reg = false
    glob = false

  proc filter(x: string): bool =
    ## filter out parsed options leaving only args remaining
    not acceptedOpts.contains(x)

  if args.len < 1:
    echo help
  else:
    for arg in args:
      if arg == "-h" or arg == "--help":
        echo help
        return
      elif arg == "-v" or arg == "--version":
        echo version
        return
      elif arg == "-r" or arg == "--recursive":
        rec = true
      elif arg == "-R" or arg == "--regex":
        reg = true
      elif arg == "-d" or arg == "--dry":
        dry = true
      elif arg == "-g" or arg == "--glob":
        glob = true

    keepIf(args, filter)

    if reg:
      if rec:
        if args.len == 2:
          renameRec(re(args[0]), args[1], dry)
        elif args.len == 1:
          renameRec(re(args[0]), dry=dry)
        else:
          echo help
      else:
        if args.len == 2:
          rename(re(args[0]), args[1], dry)
        elif args.len == 1:
          rename(re(args[0]), dry=dry)
        else:
          echo help
    elif glob:
      if args.len == 2:
        renameGlob(args[0], args[1], dry)
        # TEMP: work around --> no working rec glob proc in std
        if rec:
          renameGlobRec(args[0], args[1], dry)
      else:
        echo help
    else:
      if rec:
        if args.len == 2:
          renameRec(args[0], args[1], dry)
        elif args.len == 1:
          renameRec(args[0], dry=dry)
        else:
          echo help
      else:
        if args.len == 2:
          rename(args[0], args[1], dry)
        elif args.len == 1:
          rename(args[0], dry=dry)
        else:
          echo help


when isMainModule:
  main()
