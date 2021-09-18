#!/bin/bash
set -o nounset
set -o errexit

chart_root=$(git rev-parse --show-toplevel)/stable
branch=$(git branch | grep '[*]' | cut -d' ' -f'2')
remote=$(git merge-base main "$branch")
chart_changes=$(git diff "$remote"..."$branch" --name-only | grep stable |
  xargs -rL1 dirname | cut -d'/' -f2 | sort | uniq)

main() {
  echo "Chart root is at $chart_root"
  [[ -z $chart_changes ]] && num_changes=0 || num_changes=$(wc -l <<< "$chart_changes")
  echo "Detected $num_changes changes"
  [[ -n $chart_changes ]] && echo "$chart_changes"

  if (( num_changes > 0 )); then
    echo "Checking to make sure package version was updated..."
    for chart in $chart_changes; do
      dir=$chart_root/$chart
      version_changed=$(git diff "$remote"..."$branch" --name-only -G '^version:' -- "$dir/Chart.yaml" | wc -l)
      if (( version_changed > 0 )); then
        echo "Version for $chart was updated. Continuing..."
        helm dependency update "$dir"
        if ! git diff "$remote"..."$branch" "$dir/Chart.lock"; then
          echo "Chart.lock has been updated. Aborting push."
          exit 1
        fi
        check_lock "$dir"
      else
        echo "Version was NOT updated for $chart. Aborting push."
        exit 1
      fi
    done
  fi
}

check_lock() {
  (( $# == 1 )) || echo "Wrong number of arguments" || exit 1
  dir="$1"
  echo "Checking if Chart.lock has been updated..."
  echo -e "< Chart.yaml\n---\n> Chart.lock"
  diff <(sed -e '/ version:/!d' "$dir/Chart.yaml" | 
         sed -E 's/\s*(.*)/\1/' | sed -E 's/(.*) #.*/\1/') \
       <(sed -e '/ version:/!d' "$dir/Chart.lock" |
         sed -E 's/\s*(.*)/\1/')
  echo "Checking if digest has been updated..."
  if git diff "$remote"..."$branch" -G '^digest:' -- "$dir/Chart.lock"; then
    echo "Digest not updated. Aborting push."
    exit 1
  fi
}

main "$@"
