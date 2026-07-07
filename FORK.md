# Fork strategy

The chaton/main is the main branch,
based on an upstream tag with the additional commits that can be merged by next release.

The upstream branch is the upstream project's main branch.

Every release get its new branch, but don't necessarily lead to an update on the main branch.
For example, if the main branch is based on 3.0.0, and 3.1.0 is released upstream,
then a new branch chaton/3.1.0 is created but main is not updated.

If changes on the main branch can't be merged in a new upstream tag,
then it is manually rebased on the new tag and force-pushed.

The CI push tags `v\d+\.\d+\.\d+-test\d{2}` which runs a new CI that tries to build the APK.
If the APK build correctly, we publish a release.

Our own releases are formated like `v\d+\.\d+\.\d+-chaton\d{2}`,
and app version code are the upstream's one x100 + the patch number (2 digits),
so we can release fix version in case something break:
* For example the hypothetical v3.0.0,
  versionCode=12345 will lead to our release v3.0.0-chaton01, versionCode=1234501

Changes from the upstream projects are minimal,
the fork may follow upstream automatically (with CI),
and hopefully without much human actions

Note: this file is not for AI agents,
but for humans who want to understand how the fork works,
and for myself to clarify my thoughts
