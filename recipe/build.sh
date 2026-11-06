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
export deactivate_d=$PREFIX/etc/conda/deactivate.d

sed -e "s|/etc/liquidpromptrc|${etc_lp}rc|g" \
    -i \
    liquidprompt
sed -e "s|~/.config/liquidprompt/nojhan.theme|${etc_lp}/liquid.theme|" \
    -e "s|~/.config/liquidprompt/nojhan.ps1|${etc_lp}/liquid.ps1|" \
    -i \
    liquidpromptrc-dist

mkdir -p ${prefix}/etc/liquidprompt
cp liquid.ps1 liquid.theme ${prefix}/etc/liquidprompt
cp liquidpromptrc-dist ${prefix}/etc/liquidpromptrc

mkdir -p ${prefix}/bin
cp liquidprompt ${prefix}/bin

mkdir -p ${activate_d}
cat > ${activate_d}/liquidprompt.sh <<EOF
if [[ \$- = *i* ]]; then
    # Put the prompt mark on its own line. LP_MARK_PREFIX is liquidprompt's
    # documented hook for this; it is applied before the liquidpromptrc is
    # sourced, so a user config can still override it. Deliberately not
    # exported: liquidprompt is sourced into this same shell, so a plain
    # shell variable is enough, and the deactivate.d script below puts the
    # shell back the way it found it.
    if [[ -n \${LP_MARK_PREFIX+x} ]]; then
        _LP_CONDA_SAVED_MARK_PREFIX=\$LP_MARK_PREFIX
    fi
    : \${LP_MARK_PREFIX=\$'\n'}
    source ${bin_lp}
fi
EOF

mkdir -p ${deactivate_d}
cat > ${deactivate_d}/liquidprompt.sh <<'EOF'
if [[ $- = *i* ]]; then
    if [[ -n ${_LP_CONDA_SAVED_MARK_PREFIX+x} ]]; then
        LP_MARK_PREFIX=$_LP_CONDA_SAVED_MARK_PREFIX
        unset _LP_CONDA_SAVED_MARK_PREFIX
    else
        unset LP_MARK_PREFIX
    fi
fi
EOF
