#!/bin/bash --login

set -a

ENVIRONMENT_NAME=$1

if [ -z "$ENVIRONMENT_NAME" ]; then
  echo "No environment specified!"
  echo "Usage: ./release.sh environment"
  exit 1
fi

echo "Loading environment variables for $ENVIRONMENT_NAME"
echo "Sourcing .$ENVIRONMENT_NAME.config"
echo

source ".$ENVIRONMENT_NAME.config"

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_S3_BUCKET" ]; then
  echo "Not all expected variables are present, stopping deployment"
  exit 1
fi

echo "Building website"
export JEKYLL_ENV=$ENVIRONMENT_NAME
bundle exec jekyll build
echo

echo "Moving all html files into directories"
export SITE_DIR="_site"
for filename in $(find $SITE_DIR -regex "$SITE_DIR.*[0-9].*\.html"); do
  dir=${filename%.*}

  mkdir -pv $dir
  mv -v $filename $dir/index.html
done
echo

echo "Deploying to bucket: $AWS_S3_BUCKET"
bundle exec s3_website push

if [ -n "$WEBSITE_URL" ]; then
  open $WEBSITE_URL
fi
