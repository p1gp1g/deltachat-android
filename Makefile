
SHELL := /bin/bash
UPSTREAM := https://github.com/deltachat/deltachat-android
ORIGIN_SSH := ssh://git@codeberg.org/s1m/delta-chaton.git
# on upstream remote
UPSTREAM_MAIN_BRANCH := main
# on our remote
OUR_MAIN_BRANCH := chaton/main
# on our remote
OUR_UPSTREAM_BRANCH := upstream

fetch:
	git remote -v | grep upstream || git remote add upstream $(UPSTREAM) ;\
	git fetch upstream $(UPSTREAM_MAIN_BRANCH):$(OUR_UPSTREAM_BRANCH) --tags --no-recurse-submodules

may_fetch:
	-$(MAKE) fetch

revision ?= 00

assert_rev:
	@if ! echo "$(revision)" | grep -Eq '^[0-9]{2}$$' ; then echo "Revision must be 2 digits" >&2; exit 1; fi

update: assert_rev
	@set -eu ;\
	LAST_LOCAL_TAG="$$(git tag --sort=creatordate | grep '^v[0-9]*\.[0-9]*\.[0-9]*-chaton[0-9]{2}$$' | tail -n1)" ;\
	echo "LAST_LOCAL_TAG=$$LAST_LOCAL_TAG" ;\
	LAST_UPSTREAM_TAG="$$(git tag --sort=creatordate | grep '^v[0-9]*\.[0-9]*\.[0-9]*$$' | tail -n1)" ;\
	echo "LAST_UPSTREAM_TAG=$$LAST_UPSTREAM_TAG" ;\
	[[ "$$LAST_UPSTREAM_TAG-chaton" != "$$LAST_LOCAL_TAG" ]] && $(MAKE) new_merge tag=$$LAST_UPSTREAM_TAG revision=$(revision)

new_merge: assert_rev
	@if [ -z "$(tag)" ]; then echo "tag is not set" >&2; exit 1; fi;
	@set -eu ;\
	BRANCH="chaton/$(tag)" ;\
	git checkout $(tag) ;\
	git checkout -b $$BRANCH ;\
	git merge $(OUR_MAIN_BRANCH) --no-edit ;\
	$(MAKE) patch revision=$(revision)
	git commit -o build.gradle -o fastlane -o src -m "$(tag)-chaton$(revision)" ;\
	git tag $(tag)-test$(revision)

patch: assert_rev
	@set -eu ;\
	# Change versionCode & name, to have 99 possible revisions
	sed -i 's/\(versionCode [0-9]*\)/\1'$(revision)'/' build.gradle ;\
	sed -i 's/\(versionName .[0-9]*.[0-9]*.[0-9]*\)/\1-chaton'$(revision)'/' build.gradle ;\
	# Do not apply google services - we don't have any google-service.json for Delta Chaton
	sed -i "s/^\( *id 'com.google.gms.google-services' version '[0-9]*\.[0-9]\.[0-9]*'\)/\1 apply false/" build.gradle ;\
	sed -i '/apply plugin: "com.google.gms.google-services"/d' build.gradle ;\
	# We keep ony en-US fastlane metadata for simplicity
	git rm -r fastlane/metadata/android/* ;\
	git checkout HEAD fastlane/metadata/android/en-US ;\
	sed -i 's/Delta Chat/Delta Chaton/g' src/main/res/values*/strings.xml 

push:
	@if ! git branch --show-current | grep -Eq '^chaton/v[0-9]' ; then echo "Current branch is not a version branch" >&2; exit 1; fi
	git remote set-url origin $(ORIGIN_SSH)
	git push origin $$(git branch --show-current)
	git push origin $(OUR_UPSTREAM_BRANCH)
	git push --tags

test:
	-$(MAKE) update

clean_test:
	git checkout $(OUR_MAIN_BRANCH)
	-git branch -D chaton/v2.53.0
	-git tag --delete v2.53.0-test00
