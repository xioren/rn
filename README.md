# rn: r[e]n[ame]


### features:
+ minimal
+ supports regex and glob
+ shallow (default) and recursive modes
+ hidden files safe (*nix)
+ collision/overwrite safe


### usage:
```
usage: rn [options] this[ that]

options:
  -r, --recursive                 rename files recursively
  -R, --regex                     regex match
  -g, --glob                      glob match
  -d, --dry                       dry run

examples:
  rn "&" and
  rn -r copy
  rn -R "\s+" _
  rn --regex "(\d+)" "image-\$1"
  rn --glob --dry "*.jpeg" image
```


### installation:
```bash
nimble install rn
```


### notes:
+ for all modes except glob, leaving out the second argument ("that") simply removes the first argument ("this") from filenames, instead of replacing.
