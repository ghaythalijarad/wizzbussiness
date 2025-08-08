#!/bin/bash

# Add missing localization keys
sed -i '' 's/"chooseFromFiles": "Choose from Files"/"chooseFromFiles": "Choose from Files",\
  "errorPickingFile": "Error picking file"/g' /Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/l10n/app_en.arb

sed -i '' 's/"chooseFromFiles": "اختر من الملفات"/"chooseFromFiles": "اختر من الملفات",\
  "errorPickingFile": "خطأ في اختيار الملف"/g' /Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/l10n/app_ar.arb

echo "Localization keys added successfully"
