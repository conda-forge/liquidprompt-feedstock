#!/usr/bin/env bash
set -euf

export windows=
if [[ ${OS:-} == Windows* ]]; then
    windows=1
    export PATH=${LIBRARY_BIN}:$PATH
fi

# there is no build step

export prefix=$PREFIX
export etc_lp='${CONDA_PREFIX}/etc/liquidprompt'
export bin_lp='${CONDA_PREFIX}/bin/liquidprompt'

if [ ! -z ${windows} ]; then
  export prefix=$LIBRARY_PREFIX
  export etc_lp='$(cygpath ${CONDA_PREFIX})/Library/etc/liquidprompt'
  export bin_lp='$(cygpath ${CONDA_PREFIX})/Library/bin/liquidprompt'
fi
export activate_d=$PREFIX/etc/conda/activate.d

sed -e "s|/etc/liquidpromptrc|${etc_lp}rc|g" \
    -i \
    liquidprompt

mkdir -p ${prefix}/etc/liquidprompt
cp -R themes templates ${prefix}/etc/liquidprompt
cp liquidpromptrc-dist ${prefix}/etc/liquidpromptrc

mkdir -p ${prefix}/bin
cp liquidprompt ${prefix}/bin

mkdir -p ${activate_d}
cat > ${activate_d}/liquidprompt.sh <<EOF
if [[ \$- = *i* ]]; then
    source ${bin_lp}
    # Sourcing a theme file only defines the theme; lp_theme is what switches
    # to it. Load every bundled theme so "lp_theme <name>" can switch between
    # them on demand, then select unfold.
    # https://liquidprompt.readthedocs.io/en/stable/theme.html#switching-themes
    for _lp_conda_theme in ${etc_lp}/themes/*/*.theme; do
        [[ -f \$_lp_conda_theme ]] && source "\$_lp_conda_theme"
    done
    unset _lp_conda_theme
    # The unfold theme already renders the prompt mark on a line of its own, so
    # this package no longer overrides LP_MARK_PREFIX to split the prompt.
    # Only switch while the shell is still on the built-in theme, so a user who
    # selected their own keeps it across a re-activation.
    if [[ \${LP_THEME-} == default ]]; then
        lp_theme unfold
    fi
fi
EOF
