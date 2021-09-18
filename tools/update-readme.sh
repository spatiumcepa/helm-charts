#!/bin/bash

mapfile -t charts < <(find stable/ -mindepth 1 -maxdepth 1 -exec basename {} \; | sort)
mapfile -t versions < <(grep -e '^version:' stable/**/Chart.yaml |
                        cut -d' ' -f'2' | sed 's/-/--/g')
mapfile -t appVersions < <(grep -e '^appVersion:' stable/**/Chart.yaml |
                           cut -d' ' -f'2' | sed 's/-/--/g')
template="$(cat << 'EOF'
| <CHART> | ![Version](https://img.shields.io/badge/Version-<VERSION>-informational?style=flat-square) | ![AppVersion](https://img.shields.io/badge/AppVersion-<APPVER>-informational?style=flat-square) |
EOF
)"

top() {
cat << 'EOF' > README.md
# helm-charts
Spatium Cepa Helm Charts

| Chart | Version | AppVersion |
| ----- | ------- | ---------- |
EOF
}

bottom() {
cat << 'EOF' >> README.md

## Development

To ensure your changes pass validation before submitting, configure your local repository githooks before you start a new branch:

```sh
cd ~/src/spatiumcepa/helm-charts
git config --local core.hooksPath $PWD/.githooks
```

EOF
}

main() {
  top
  for i in "${!charts[@]}"
  do
    header="$template"
    header="${header//<CHART>/${charts[$i]}}"
    header="${header//<VERSION>/${versions[$i]}}"
    header="${header//<APPVER>/${appVersions[$i]}}"
    echo "$header" >> README.md
  done
  bottom
}

main "$@"
