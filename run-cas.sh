#!/bin/sh

# The source and destination directories.
src=/etc/cas-config
dst=/etc/cas

# A function to copy configuration files.
copy_configs() {
    rsync -ruLK "$src/" "$dst/"
}

# Initially copy the configs.
copy_configs

# Run the process.
java -jar /cas.war "$@"
exit "$!"
