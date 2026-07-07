#!/usr/bin/env bash

# コールドスタート時、php-fpmのソケット生成前にnginxが起動すると
# 「connect() to unix:/var/run/php/php-fpm.sock failed」で502になるため、
# ソケットができるまで待ってからnginxを起動する（上限15秒＝0.25秒×60回）
for i in $(seq 1 60); do
    if [ -S /var/run/php/php-fpm.sock ]; then
        break
    fi
    sleep 0.25
done

exec nginx
