#!/bin/bash

eval "$(micromamba shell hook --shell=posix)"
micromamba activate base

export NEKRS_HOME=/opt/conda
