#!/bin/sh

appledoc --project-name 'GCDObjects 0.0.1' \
         --project-company 'bryn austin bellomy' \
         --company-id 'com.signalenvelope' \
         -o ../appledoc \
         --ignore .m \
         --keep-merged-sections \
         --keep-undocumented-objects \
         --keep-undocumented-members \
         --search-undocumented-doc \
         ./**/*.h

# --include ./GCDObjects/*.h \
