import std/[os, strutils, re, sequtils, strformat, terminal]


proc echoDelta(this: string | Regex, that, oldFilename: string) {.inline.} =
  ## echo filename differences with highlighting
  let parts = oldFilename.split(this)
  stdout.styledWrite(fgMagenta, oldFilename, " --> ")

  if parts.len == 1:
    # NOTE: no splitting occured
    stdout.styledWriteLine(fgWhite, that)
  else:
    for part in parts[0..^2]:
      stdout.styledWrite(fgMagenta, part, fgWhite, that)
    stdout.styledWriteLine(fgMagenta, parts[^1])


proc makeUnique(filepath: var string) {.inline.} =
  ## make filenames unique
  var n = 1
  let (dir, name, ext) = splitFile(filepath)

  filepath = joinPath(dir, addFileExt(fmt"{name}-{n}", ext))
  while fileExists(filepath):
    inc n
    filepath = joinPath(dir, addFileExt(fmt"{name}-{n}", ext))


proc rename(this: string | Regex, that: string, dry: bool) =
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
          if sameFile(oldFilepath, newFilepath):
            continue
          else:
            makeUnique(newFilepath)

        try:
          if not dry:
            moveFile(oldFilepath, newFilepath)
          echoDelta(this, that, oldFilename)
        except OSError:
          echo "error renaming ", oldFilename


proc renameRec(this: string | Regex, that: string, dry: bool) =
  ## recursively replace "this" string or regex pattern with "that" string in filenames
  var
    newFilepath: string
    newFilename: string

  for oldFilepath in walkDirRec(getCurrentDir()):
    #[ NOTE: ignore non hidden files within hidden directories
      isHidden wont work 100% here ]#
    if "/." notin oldFilepath and not isHidden(oldFilepath):
      let (dir, oldFilename, ext) = splitFile(oldFilepath)

      if oldFilename.contains(this):
        newFilename = oldFilename.replace(this, that)
        newFilepath = joinPath(dir, addFileExt(newFilename, ext))

        if fileExists(newFilepath):
          if sameFile(oldFilepath, newFilepath):
            continue
          else:
            makeUnique(newFilepath)

        try:
          if not dry:
            moveFile(oldFilepath, newFilepath)
          echoDelta(this, that, oldFilename)
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
        if sameFile(oldFilepath, newFilepath):
          continue
        else:
          makeUnique(newFilepath)

      try:
        if not dry:
          moveFile(oldFilepath, newFilepath)
        echoDelta(this, that, oldFilename)
      except OSError:
        echo "error renaming ", oldFilename


proc renameGlobRec(this, that: string, dry: bool) =
  ## recursively rename files matching "this" glob pattern with "that" string
  var newFilepath: string

  for dir in walkDirRec(getCurrentDir(), yieldFilter = {pcDir}):
    for oldFilepath in walkFiles(joinPath(dir, this)):
      #[ NOTE: ignore non hidden files within hidden directories
        isHidden wont work 100% here ]#
      if "/." notin oldFilepath and not isHidden(oldFilepath):
        let (_, oldFilename, ext) = splitFile(oldFilepath)

        newFilepath = joinPath(dir, addFileExt(that, ext))

        if fileExists(newFilepath):
          if sameFile(oldFilepath, newFilepath):
            continue
          else:
            makeUnique(newFilepath)

        try:
          if not dry:
            moveFile(oldFilepath, newFilepath)
          echoDelta(this, that, oldFilename)
        except OSError:
          echo "error renaming ", oldFilename


proc main() =
  ##[ replace strings in filenames, takes 1 or two arguments,
  if second argument is absent, replaces first argument with empty string. ]##
  const
    version = "0.1.8"
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
    ## filter out parsed options
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

    var that: string
    if args.len == 2:
      that = args[1]
    elif args.len != 1 or glob:
      echo help
      return
    let this = args[0]

    if reg:
      if rec:
        renameRec(re(this), that, dry)
      else:
        rename(re(this), that, dry)
    elif glob:
      renameGlob(this, that, dry)
      if rec:
        # TEMP: work around --> no working rec glob proc in std
        renameGlobRec(this, that, dry)
    else:
      if rec:
        renameRec(this, that, dry)
      else:
        rename(this, that, dry)


when isMainModule:
  main()
