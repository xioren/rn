# rn: r[e]n[ame]


### features:
+ minimal
+ supports regex and glob
+ shallow (default) and recursive modes
+ hidden files safe
+ collision/overwrite safe


### examples:
```bash
rn "&" and
rn -r copy
rn -p "\s+" -
rn -g --dry "*.jpeg" image
```


### installation:
```bash
nimble install rn
```


### notes:
+ for all modes except glob, leaving out the second argument ("that") simply removes the first argument ("this") from filenames, instead of replacing.
