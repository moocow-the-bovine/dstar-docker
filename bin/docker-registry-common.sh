##-*- Mode: Shell-Script -*-

##======================================================================
## Globals
[ -n "$DOCKER_REGISTRY_URL" ] || DOCKER_REGISTRY_URL="http://localhost:5000"
#[ -z "$DOCKER_REGISTRY_CURLOPT" ] && DOCKER_REGISTRY_CURLOPT=""
#[ -z "$DOCKER_REGISTRY_VERBOSE" ] && DOCKER_REGISTRY_VERBOSE=""
#[ -z "$DOCKER_REGISTRY_DUMMY" ] && DOCKER_REGISTRY_DUMMY=""
#[ -z "$DOCKER_REGISTRY_RO" ] && DOCKER_REGISTRY_RO=""

##-- for docker registry container ... not used here
#[ -z "$DOCKER_REGISTRY_DIR" ] && DOCKER_REGISTRY_DIR="$(dirname ${BASH_SOURCE[0]})/registry"


##======================================================================
## high-level wrappers

## undef = read_rcfile RCFILE
read_rcfile() {
    [ -z "$DOCKER_REGISTRY_VERBOSE" -a -z "$DOCKER_REGISTRY_DUMMY" ] || echo "+ . $1" >&2
    . "$1"
}

## TABLE=$(registry_table GLOB...)
registry_table() {
    local repos=($(registry_catalog))
    local pats=("$@")
    [ ${#pats[@]} -gt 0 ] || pats=("*")
    local repo
    local pat
    local tag
    local hash
    local stamp
    local match
    for repo in "${repos[@]}"; do
	    for tag in $(registry_tags "${repo}"); do
	        match=''
	        for pat in "${pats[@]}"; do
		        [[ "$pat" == *:* ]] || pat="$pat:*"
		        if [ -z "$pat" ] || [[ "${repo}:${tag}" == $pat ]] ; then match=y; break; fi;
	        done
	        [ -z "$match" ] && continue
	        stamp=$(registry_timestamp "${repo}:${tag}")
	        hash=$(registry_hash "${repo}:${tag}")
	        echo -e "${repo}:${tag}\t${stamp}\t${hash}"
	    done
    done
}

## registry_stale_list IMAGE_GLOB[:TAG_GLOB] [NKEEP=1]
registry_stale_list() {
    local pat="$1"
    local nkeep="$2"
    if [ -z "$pat" ] ; then
	    echo "registry_stale_list: ERROR: no GLOB specified!" >&2
	    return 1
    elif [ -z "$nkeep" ] ; then
	    echo "registry_stale_list: WARNING: NKEEP not specified : keeping all images" >&2
	    nkeep=-1
    elif [ "$nkeep" -lt 0 ] ; then
	    echo "registry_stale_list: WARNING: NKEEP is negative : keeping all images" >&2
    fi

    ##-- get raw table (all tags, not just selected ones, sorted ascending by date)
    local table=$(registry_table $(repo_image "$pat") | sort -t$'\t' -k2)

    ##-- apply pattern selection (detect deletable images)
    [ -n "$pat" ] || pat="*:*"
    [[ "$pat" == *:* ]] || pat="$pat:*"
    local repo
    local stamp
    local hash
    local skiphash=()
    while read repo stamp hash; do
	    if [[ "${repo}" != $pat ]] ; then skiphash[${#skiphash[@]}]="$hash"; fi
    done <<<"$table"

    ##-- propagate "skip"-status from non-matches (un-deletable)
    local matchrows=()
    while read repo stamp hash ; do
	    if ! list_contains "$hash" "${skiphash[@]}"; then
	        matchrows[${#matchrows[@]}]="$repo"$'\t'"$stamp"$'\t'"$hash"
	    else
	        echo -e "SKIP\t$repo\t$stamp\t$hash"
	    fi
    done <<<"$table"

    ##-- get number of deletable rows
    local nmatch=${#matchrows[@]}
    local matchtab=$(list_lines "${matchrows[@]}")
    if [ $nkeep -lt 0 -o $nmatch -le $nkeep ] ; then
	    echo "registry_stale_list: no prunable images found for pattern '$pat' (keep=$nkeep)" >&2
	    [ $nmatch -eq 0 ] || (sed 's/^/KEEP	/;' <<<"$matchtab")
    else
	    local keeprows=$(tail -n $nkeep <<<"$matchtab")
	    local prunerows=$(head -n -$nkeep <<<"$matchtab")
	    local nprune=$(wc -l <<<"$prunerows")
	    echo "registry_stale_list: found $nprune of $nmatch prunable image(s) for pattern '$pat' (keep=$nkeep)" >&2
	    [ -z "$prunerows" ] || (sed 's/^/PRUNE	/;' <<<"$prunerows")
	    [ -z "$keeprows" ] || (sed 's/^/KEEP	/;' <<<"$keeprows")
    fi
}

## registry_prune IMAGE_GLOB[:TAG_GLOB] [NKEEP=1]
registry_prune() {
    local prow
    local pcols
    registry_stale_list "$@" | \
	    while read prow; do
	        echo "$prow"
	        pcols=($prow)
	        [ "${pcols[0]}" != "PRUNE" ] || registry_delete "${pcols[1]}"
	    done
}

##======================================================================
## mid-level wrappers

## REPOS=$(registry_repos)
## REPOS=$(registry_repos REPOS_OR_GLOB)
registry_repos() {
    local repos=("$@")
    if [ ${#repos[@]} -eq 0 ]; then
	    repos=($(registry_catalog))
    elif [ ${#repos[@]} -eq 1 ] && [[ "${repos[*]}" == *"*"* ]] ; then
	    repos=($(registry_catalog $(repo_image "${repos[0]}")))
    fi
    [ -z "${repos[*]}" ] || echo "${repos[*]}"
}

## REPOS=$(registry_catalog)
## REPOS=$(registry_catalog GLOB)
registry_catalog() {
    local repos=$(reget /v2/_catalog | jq -r .repositories[])
    local pat=$(repo_image "$1")
    [ -n "$pat" ] && glob_filter "$pat" "$repos" || echo "$repos"
}

## TAGS=$(registry_tags IMAGE)
## TAGS=$(registry_tags IMAGE:GLOB)
registry_tags() {
    local img=$(repo_image "$1")
    local pat=$(repo_usertag "$1")
    local tags=$(reget /v2/"$img"/tags/list | jq -r '(.tags//[])[]')
    glob_filter "$pat" "$tags"
}

## MANIFEST=$(registry_manifest IMAGE:TAG)
registry_manifest() {
    local repo="$1"; shift
    reget /v2/$(repo_image "$repo")/manifests/$(repo_tag "$repo") "$@"
}

## MANIFEST=$(registry_manifest_ext IMAGE:TAG)
registry_manifest_ext() {
    registry_manifest "$@" -H "Accept: application/vnd.docker.distribution.manifest.v2+json"
}

## HASHID=$(registry_hash IMAGE:TAG)
registry_hash() {
    #registry_manifest_ext "$1" | jq -r .config.digest
    #registry_manifest_ext "$1" -v 2>&1 | fgrep Docker-Content-Digest | head -n1 | awk '{print ($3)}'
    registry_manifest_ext "$1" -I | grep '^Docker-Content-Digest:' | cut -d' ' -f2- | tr -d '\r'
}

## TIMESTAMP=$(registry_timestamp IMAGE:TAG)
registry_timestamp() {
    registry_manifest "$1" \
	    | jq -r '(.history//[])[].v1Compatibility' \
	    | jq -r '.created' \
	    | xargs -r -i{} date +"%FT%TZ" -d{} \
	    | sort \
	    | tail -n1
}

## RSP=$(registry_delete IMAGE:TAG)
registry_delete() {
    redel /v2/$(repo_image "$1")/manifests/$(registry_hash "$1") -H "Accept: application/vnd.docker.distribution.manifest.v2+json"
}


##======================================================================
## Utils

##--------------------------------------------------------------
## Utils: verbose commands
runcmd() {
    [ -z "$DOCKER_REGISTRY_VERBOSE" -a -z "$DOCKER_REGISTRY_DUMMY" ] || echo "+ $*" >&2
    if [ -n "$DOCKER_REGISTRY_DUMMY" ] ; then return 0 ; fi
    "$@"
}

runcmd_rw() {
    [ -z "$DOCKER_REGISTRY_VERBOSE" -a -z "$DOCKER_REGISTRY_DUMMY" ] || echo "+ $*" >&2
    if [ -n "$DOCKER_REGISTRY_DUMMY" -o -n "$DOCKER_REGISTRY_RO" ] ; then return 0 ; fi
    "$@"
}


##--------------------------------------------------------------
## Utils: basic registry requests
registry_request() {
    local method="$1"; shift
    local path="$1"; shift
    runcmd curl -sSL -X "$method" $DOCKER_REGISTRY_CURLOPT "${DOCKER_REGISTRY_URL}${path}" "$@"
}
registry_request_rw() {
    local method="$1"; shift
    local path="$1"; shift
    runcmd_rw curl -sSL -X "$method" $DOCKER_REGISTRY_CURLOPT "${DOCKER_REGISTRY_URL}${path}" "$@"
}

rehead() { registry_request HEAD "$@"; }
reget() { registry_request GET "$@"; }
reput() { registry_request_rw PUT "$@"; }
repost() { registry_request_rw POST "$@"; }
redel() { registry_request_rw DELETE "$@"; }

##--------------------------------------------------------------
## Utils: repo parsing "IMAGE", "IMAGE:TAG"

## IMAGE=$(repo_image REPO:TAG)
repo_image() {
    local repo="$1"
    echo "${repo%%:*}"
}

## TAG=$(repo_usertag REPO:TAG)
repo_usertag() {
    local repo="$1"
    local tag=""
    [[ "$repo" != *":"* ]] || tag="${repo#*:}"
    echo "$tag"
}

## HASHVAL=$(hash_digest "sha256:TAG")
hash_digest() {
    local hash="$1"
    [[ "$hash" != *":"* ]] || hash="${hash##*:}"
    echo "$hash"
}

## TAG_or_latest=$(repo_tag REPO:TAG)
repo_tag() {
    local tag=$(repo_usertag "$1")
    [ -n "$tag" ] || tag=latest
    echo "$tag"
}

##--------------------------------------------------------------
## Utils: filtering

## LINES_FILTERED=$(glob_filter PAT LINES)
glob_filter() {
    local pat="$1"
    shift
    [ -n "$pat" ] || pat='*'
    local item
    list_lines "$@" | while read item; do [[ "$item" != $pat ]] || echo "$item"; done
}

## LINES=$(list_lines LIST...)
list_lines() {
    local line
    for line in "$@"; do echo "$line"; done
}

## list_contains ELT LIST... ; echo $?
list_contains() {
    local elt="$1"
    local item
    shift
    for item in "$@" ; do
	    if [ "$elt" == "$item" ]; then return 0; fi
    done
    return 1
}

#echo "loaded ${BASH_SOURCE[0]}" >&2

