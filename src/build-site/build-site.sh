#!/bin/sh

SCRIPT_FOLDER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH="$PATH:$SCRIPT_FOLDER"

if [ -z "$BASE_URL" ]; then
  BASE_URL="https://nepo.dev"
fi
export BASE_URL

BUILD_DIR="$SCRIPT_FOLDER/build"
PROJECT_ROOT="$SCRIPT_FOLDER/../.."

CATEGORIES=(tech food life)

main() {
  # Setup
  cd "$SCRIPT_FOLDER"
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"
  mkdir -p "$BUILD_DIR/posts"

  # Get list of posts ordered by date
  post_list="$(get-posts.sh)"
  if [ "$DEBUG" ] && [ "$BUILD_JUST_LAST_ARTICLE" ]; then
    post_list="$(head -n 1 <<< "$post_list")"
  fi

  # Build posts' content
  echo "$post_list"| while read -r post; do
    post_id="$(get-property.sh "$post" id)"
    echo "Generating $post_id.html"
    build-post.sh "$post" > "$BUILD_DIR/posts/$post_id.html"
  done <<< "$post_list"

  # Build index file
  echo "Generating index.html"
  build-index.sh <<< "$post_list" > "$BUILD_DIR/index.html"

  # Build subscribe form file
  echo "Generating subscribe.html"
  build-subscribe.sh > "$BUILD_DIR/subscribe.html"

  if [ -z "$DEBUG" ]; then
    # Build category lists
    for category in ${CATEGORIES[@]}; do
      echo "Generating $category.html"
      get-posts-in-category.sh "$category" | build-index.sh > "$BUILD_DIR/$category.html"
    done

    # Build RSS file
    echo "Generating atom feed"
    get-posts.sh | build-rss-feed.sh > "$BUILD_DIR/feed.atom"
  fi

  # Move to root + cleanup
  echo "Moving build files to project root"
  rm "$PROJECT_ROOT/index.html" || true
  mv "$BUILD_DIR/index.html" "$PROJECT_ROOT/index.html"
  mv "$BUILD_DIR/subscribe.html" "$PROJECT_ROOT/subscribe.html"
  if [ -z "$DEBUG" ]; then
    for category in ${CATEGORIES[@]}; do
      rm "$PROJECT_ROOT/$category.html" || true
      mv "$BUILD_DIR/$category.html" "$PROJECT_ROOT/$category.html"
    done
    rm "$PROJECT_ROOT/feed.atom" || true
    mv "$BUILD_DIR/feed.atom" "$PROJECT_ROOT/feed.atom"
  fi
  rm -rf "$PROJECT_ROOT/posts" || true
  mv "$BUILD_DIR/posts" "$PROJECT_ROOT/posts"
  
  rm -rf "$BUILD_DIR"
  echo "Build finished ✅"
}

main
