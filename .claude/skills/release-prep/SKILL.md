---
name: release-prep
description: Guide through an App::Yak release: version bump in Yak.pm and script/yak POD, CHANGELOG entry, dzil test, git tag
---

Guide the user through releasing a new version of App::Yak.

## Steps

1. **Ask for the new version number** — must be semver `vX.Y.Z` format (e.g. `v1.1.0`)

2. **Update version in `lib/App/Yak.pm`**
   - Find: `use version; our $VERSION = version->declare('v...');`
   - Replace with the new version

3. **Update version in `script/yak` POD**
   - Find the `=head1 VERSION` section
   - Update the version number there

4. **Draft CHANGELOG.md entry**
   - Run `git log --oneline $(git describe --tags --abbrev=0)..HEAD` to list commits since the last release
   - Add a new section at the top of CHANGELOG.md: `## [vX.Y.Z] - YYYY-MM-DD`
   - Summarize the changes in bullet points

5. **Run the full test suite**
   - Execute: `dzil test --all`
   - Report results; stop here if tests fail

6. **Stage, diff, and confirm**
   - Stage: `lib/App/Yak.pm`, `script/yak`, `CHANGELOG.md`
   - Show the diff and wait for the user to confirm before proceeding
   - After confirmation: `git commit -m "Release vX.Y.Z"` then `git tag -a vX.Y.Z -m "Release vX.Y.Z"`

7. **Remind about post-push automation**
   - After `git push && git push --tags`, the `publish.yml` workflow automatically builds and pushes Docker images to DockerHub (`jonasbn/yak:latest`) and GHCR (`ghcr.io/jonasbn/perl-app-yak:latest`)
   - Run `dzil release` separately if publishing to CPAN
