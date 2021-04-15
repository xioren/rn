# rn: r[e]n[ame]


### features:
+ minimal
+ supports regex and glob
+ shallow (default) and recursive modes
+ hidden files safe (*nix)
+ collision/overwrite safe


### usage:
```
rn [options] this[ that]

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
```


### installation:
```bash
nimble install rn
```


### notes:
+ for all modes except glob, leaving out the second argument ("that") simply removes the first argument ("this") from filenames, instead of replacing.
