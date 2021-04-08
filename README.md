# rn: r[e]n[ame]


### features:
+ minimal
+ supports regex and glob
+ shallow (default) and recursive modes
+ hidden files safe
+ collision/overwrite safe


### usage:
```
rn [options] this[ that]

Options:
  -r, --recursive                 Rename files recursively
  -p, --pattern                   Regex match
  -g, --glob                      Glob match
  -d, --dry                       Dry run

Examples:
  rn "&" and
  rn -r copy
  rn -p "\s+" _
  rn --glob --dry "*.jpeg" image
```


### installation:
```bash
nimble install rn
```


### notes:
+ for all modes except glob, leaving out the second argument ("that") simply removes the first argument ("this") from filenames, instead of replacing.
