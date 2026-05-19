---
name: pod-check
description: Check POD syntax and public-method coverage in App::Yak before committing — catches failures that dzil test --all would report
---

Check that POD documentation is complete and valid for `lib/App/Yak.pm` and `script/yak`.

## Steps

1. **Syntax check**
   ```bash
   podchecker lib/App/Yak.pm
   podchecker script/yak
   ```

2. **Coverage check** — every public method (no leading `_`) must have a POD entry
   ```bash
   carton exec perl -Ilib -MPod::Coverage -e '
     my $pc = Pod::Coverage->new(package => "App::Yak");
     my @naked = $pc->naked;
     if (@naked) {
       print "Missing POD for: " . join(", ", @naked) . "\n";
       exit 1;
     }
     print "POD coverage: OK\n";
   '
   ```

3. **Report results**
   - List any methods missing POD with suggestions for what to document
   - Note: methods matching `_\w+` are private and exempt from coverage requirements
   - If all checks pass, confirm it is safe to commit
