# !/bin/bash

sf package version list --concise --packages "FieloMBC" --order-by "CreatedDate desc" > .local/versions.txt && code -r .local/versions.txt