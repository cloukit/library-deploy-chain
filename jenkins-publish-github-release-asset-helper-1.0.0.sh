#!/bin/bash

####################################################################################
# MIT License
# Copyright (c) 2017 Bernhard Grünewaldt
# See https://github.com/codeclou/publish-github-release-assets-helper/blob/master/LICENSE
####################################################################################

VERSION=1.0.0

set -e

####################################################################################
#
# COLORS
#
####################################################################################

export CLICOLOR=1
C_RED='\x1B[31m'
C_CYN='\x1B[96m'
C_GRN='\x1B[32m'
C_MGN='\x1B[35m'
C_RST='\x1B[39m'

####################################################################################
#
# FUNCTIONS
#
####################################################################################

# Used to be able to use pass-by-reference in bash
#
#
return_by_reference() {
    if unset -v "$1"; then
        eval $1=\"\$2\"
    fi
}

# USAGE:
#  upload_asset_to_github_release \
#         codeclou \
#         foo \
#         1.0 \
#         123 \
#         build-results/ \
#         swagger.json \
#         "application/json"
#
# @param $1 {string} repository owner
# @param $2 {string} repository name
# @param $3 {release_name} release/tag name
# @param $4 {int} github release id
# @param $5 {string} filepath
# @param $6 {string} filename
# @param $7 {string} mime type
function upload_asset_to_github_release {
    local owner=$1
    local repo=$2
    local release_name=$3
    local release_id=$4
    local filepath=$5
    local filename=$6
    local mime_type=$7

    #
    # LIST ASSETS
    #
    local assets=$(curl -s \
        --fail \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
        "https://api.github.com/repos/${owner}/${repo}/releases/${release_id}/assets" \
        | jq ".")

    #
    # CHECK IF ASSET EXISTS
    #
    local asset_id=$(echo $assets | jq -r ".[] | select(.name == \"$filename\") | .id")

    #
    # DELETE ASSET IF EXISTS
    #
    if [ "$asset_id" != "" ]
    then
        local delete_existing_asset_response=$(curl \
             -s -o /dev/null \
             -w "%{http_code}" \
             -H "Content-Type: ${mime_type}" \
             -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
             -X DELETE \
             "https://api.github.com/repos/${owner}/${repo}/releases/assets/${asset_id}")
        if [[ "$delete_existing_asset_response" != "204" ]]
        then
            echo -e $C_CYN">> publish asset ........:${C_RST}${C_RED} DELETING EXISTING${C_RST} ${filename} of release ${release_name} failed with http ${delete_existing_asset_response}."
            exit 1
        else
            echo -e $C_CYN">> publish asset ........:${C_RST}${C_GRN} DELETING EXISTING${C_RST} ${filename} of release ${release_name} succeeded with http ${delete_existing_asset_response}."
        fi
    fi

    #
    # UPLOAD ASSET
    #
    local upload_response_status=$(curl \
         -s -o /dev/null \
         -w "%{http_code}" \
         -H "Content-Type: ${mime_type}" \
         -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
         -X POST \
         --data-binary "@${filepath}${filename}" \
         "https://uploads.github.com/repos/${owner}/${repo}/releases/${release_id}/assets?name=${filename}")
    if [[ "$upload_response_status" != "201" ]]
    then
        echo -e $C_CYN">> publish asset ........:${C_RST}${C_RED} UPLOADING        ${C_RST} ${filename} of release ${release_name} failed with http ${upload_response_status}."
        exit 1
    else
        echo -e $C_CYN">> publish asset ........:${C_RST}${C_GRN} UPLOADING        ${C_RST} ${filename} of release ${release_name} succeeded with http ${upload_response_status}."
    fi

    echo ""
}


# NOTE:
#    - release_name must match an existing Git Tag!
#    - if a release already exists, it just returns the release_id
#
# USAGE:
#  release_id=-1
#  create_github_release_and_get_release_id "codeclou"  "foo"  "1.0" "master" release_id
#  echo $release_id
#
# @param $1 {string} repository owner
# @param $2 {string} repository name
# @param $3 {release_name} release/tag name
# @param $4 {target_commitish} 'master' from which branch your tag should be created off
# @param $5 {int} return value passByReference release id
function create_github_release_and_get_release_id {
    local owner=$1
    local repo=$2
    local release_name=$3
    local target_commitish=$4

    echo ""
    echo -e $C_MGN'              __   ___     __          _ __  __        __                         '$C_RST
    echo -e $C_MGN'   ___  __ __/ /  / (_)__ / /    ___ _(_) /_/ /  __ __/ /                         '$C_RST
    echo -e $C_MGN'  / _ \/ // / _ \/ / (_-</ _ \  / _ `/ / __/ _ \/ // / _ \                        '$C_RST
    echo -e $C_MGN' / .__/\_,_/_.__/_/_/___/_//_/  \_, /_/\__/_//_/\_,_/_.__/                        '$C_RST
    echo -e $C_MGN'/_/        __                  /___/             __        __       __            '$C_RST
    echo -e $C_MGN'  _______ / /__ ___ ____ ___   ___ ____ ___ ___ / /____   / /  ___ / /__  ___ ____'$C_RST
    echo -e $C_MGN' / __/ -_) / -_) _ `(_-</ -_) / _ `(_-<(_-</ -_) __(_-<  / _ \/ -_) / _ \/ -_) __/'$C_RST
    echo -e $C_MGN'/_/  \__/_/\__/\_,_/___/\__/  \_,_/___/___/\__/\__/___/ /_//_/\__/_/ .__/\__/_/   '$C_RST
    echo -e $C_MGN'                                                                  /_/             '$C_RST
    echo ""
    echo -e $C_MGN'  Publish GitHub Release Assets with ease'$C_RST
    echo -e $C_MGN"  v${VERSION} - https://github.com/codeclou/publish-github-release-assets-helper"$C_RST
    echo -e $C_MGN'  ------'$C_RST
    echo ""

    local release_id=$(curl -s \
        --fail \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
        "https://api.github.com/repos/${owner}/${repo}/releases/tags/${release_name}" \
        | jq -r ".id")

    if (( release_id > 0 ))
    then
        echo -e $C_CYN">> create release .......:${C_RST}${C_MGN} SKIPPING      ${C_RST}    creation of release ${release_name} skipped since it does already exist."
    else
        # https://developer.github.com/v3/repos/releases/#create-a-release
        release_id=$(curl -s \
             --fail \
             -H "Accept: application/json" \
             -H "Content-Type: application/json" \
             -H "Authorization: token ${GITHUB_AUTH_TOKEN}" \
             -X POST \
             -d "{ \"tag_name\": \"$release_name\", \"target_commitish\": \"$target_commitish\", \"name\": \"$release_name\", \"body\": \"$release_name\" }" \
             "https://api.github.com/repos/${owner}/${repo}/releases" \
            | jq -r ".id")
        echo -e $C_CYN">> create release .......:${C_RST}${C_GRN} CREATED        ${C_RST}   creation of release ${release_name} succeeded with id ${release_id}."
    fi

    echo ""
    local "$5" && return_by_reference $5 $release_id
}
