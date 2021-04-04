# rn: mass rename done right


### features:
+ ultra minimal
+ supports regex and glob
+ shallow (default) and recursive modes
+ hidden files safe
+ collision/overwrite safe


### examples:
```bash
rn "&" and
rn -r this
rn "\s+" -
rn --dry *-copy file
```


### installation:
```bash
nimble install rn
```


### note:
  all input for "this" argument are handled as regex patterns and relevant special chars need to be escaped to be taken as literal. i.e. "\+" for literal "+".
