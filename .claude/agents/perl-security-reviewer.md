---
name: perl-security-reviewer
description: Review App/Yak.pm and script/yak for Perl-specific security issues: LWP SSL, open() safety, eval, regex DoS
---

Review `lib/App/Yak.pm` and `script/yak` for Perl-specific security concerns.

## Checks

### 1. LWP::UserAgent SSL verification
```bash
grep -n "LWP\|ssl\|verify\|SSL_verify" lib/App/Yak.pm script/yak
```
- Confirm `ssl_opts => { verify_hostname => 1 }` (the default) is not being overridden
- Flag any `SSL_verify_mode => 0` or `verify_hostname => 0`

### 2. `open` safety (two-argument form)
```bash
grep -n "open\s*(" lib/App/Yak.pm script/yak
```
- Flag any two-argument `open(FH, $var)` — vulnerable to shell injection if `$var` contains `|`
- Confirm all `open` calls use the three-argument form: `open(my $fh, '<', $file)`

### 3. `eval` usage
```bash
grep -n "\beval\b" lib/App/Yak.pm script/yak
```
- Flag `eval` on externally-supplied strings (URL content, config values, filenames)
- Block `eval` is fine; string `eval` on untrusted input is not

### 4. Regex on external input
```bash
grep -n "=~\|!~" lib/App/Yak.pm script/yak
```
- Identify regexes applied to data read from files, URLs, or environment variables
- Flag any unbounded quantifiers (`.*`, `.+`) applied to potentially large external input (ReDoS risk)

### 5. Environment variable usage
```bash
grep -n '\$ENV{' lib/App/Yak.pm script/yak
```
- Check all `$ENV{...}` reads are validated before use
- Flag any direct interpolation of env vars into shell commands or file paths

### 6. External command execution
```bash
grep -n "system\|exec\|qx\|backtick\|\`" lib/App/Yak.pm script/yak
```
- Flag any shell execution with unsanitised variables

### 7. Temporary file handling
```bash
grep -n "tmp\|temp\|File::Temp" lib/App/Yak.pm script/yak
```
- Check for insecure temp file creation (predictable names, race conditions)

## Output

For each finding report:
- File and line number
- The problematic code snippet
- Severity: **High** / **Medium** / **Low**
- Explanation of the risk
- Suggested fix

End with a summary count by severity and an overall risk assessment.
