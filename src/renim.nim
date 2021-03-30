import os, strutils, strformat, re, parseopt

# replace strings in filenames, takes 1 or two arguments,
# if second argument is absent, replaces first argument with empty string.

let args = commandLineParams()


proc makeUnique(path: string): string =
  ## make filenames unique
  var
    n = 1
    new_path: string
  let
    (dir, name, ext) = splitFile(path)

  while true:
    new_path = fmt"{dir}/{name}-{n}{ext}"
    if fileExists(new_path):
      n += 1
    else:
      return new_path


proc rename(this: string|Regex, that = "") =
  ## replace "this" string or regex pattern with "that" string in filenames
  var
    newFilepath: string
    newFilename: string

  for kind, oldFilepath in walkDir(getCurrentDir()):
    if kind == pcFile and not oldFilepath.contains("/."):
      let (_, oldFilename, _) = splitFile(oldFilepath)

      if oldFilename.contains(this):
        newFilename = oldFilename.replace(this, that)
        newFilepath = oldFilepath.replace(oldFilename, newFilename)

        if fileExists(newFilepath):
          if sameFileContent(oldFilepath, newFilepath):
            discard tryRemoveFile(oldFilepath)
            continue
          else:
            newFilepath = makeUnique(newFilepath)

        moveFile(oldFilepath, newFilepath)
        echo oldFilename, " --> ", newFilename


proc renameRec(this: string|Regex, that = "") =
  ## recursively replace "this" string or regex pattern with "that" string in filenames
  var
    newFilepath: string
    newFilename: string

  for oldFilepath in walkDirRec(getCurrentDir()):
    if not oldFilepath.contains("/."):
      let (_, oldFilename, _) = splitFile(oldFilepath)

      if oldFilename.contains(this):
        newFilename = oldFilename.replace(this, that)
        newFilepath = oldFilepath.replace(oldFilename, newFilename)

        if fileExists(newFilepath):
          if sameFileContent(oldFilepath, newFilepath):
            discard tryRemoveFile(oldFilepath)
            continue
          else:
            newFilepath = makeUnique(newFilepath)

        moveFile(oldFilepath, newFilepath)
        echo oldFilename, " --> ", newFilename


when isMainModule:
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
    rec: bool
    reg: bool

  if args.len < 1:
    echo "<no argument>"
  else:
    for kind, key, val in getopt(shortNoVal=sNoVal, longNoVal=lNoVal):
      case kind
      of cmdArgument:
        discard
      of cmdShortOption, cmdLongOption:
        case key
          of "r", "recursive":
            rec = true
          of "p", "pattern":
            reg = true
      of cmdEnd:
        quit(0)

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
