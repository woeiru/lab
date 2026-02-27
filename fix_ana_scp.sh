#!/bin/bash
sed -i 's/    truncate_and_pad() {/    _ana_scp_truncate_and_pad() {/' lib/gen/ana
sed -i 's/    print_separator() {/    _ana_scp_print_separator() {/' lib/gen/ana
sed -i 's/    print_row() {/    _ana_scp_print_row() {/' lib/gen/ana
sed -i 's/truncate_and_pad /_ana_scp_truncate_and_pad /g' lib/gen/ana
sed -i 's/print_separator/_ana_scp_print_separator/g' lib/gen/ana
sed -i 's/print_row /_ana_scp_print_row /g' lib/gen/ana
