# !/bin/bash

export SENDGRID_API_KEY='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' &&

curl -X "POST" "https://api.sendgrid.com/v3/mail/send" \
     -H "Authorization: Bearer $SENDGRID_API_KEY" \
     -H 'Content-Type: application/json' \
     -d '{
   "from":{
      "email":"engineering@fielo.com",
      "name":"Fielo Engineering"
   },
   "reply_to":{
        "email":"engineering@fielo.com",
        "name":"Fielo Engineering"
    },
   "personalizations":[
      {
         "to":[
            {"email":"engineering@fielo.com"},
            {"email":"product@fielo.com"},
            {"email":"qa@fielo.com"}
         ],
         "dynamic_template_data":{
          "packageName": "Fielo MBC",
          "versionNumber": "v'"$1"'",
          "versionLink": "https://login.salesforce.com/packaging/installPackage.apexp?p0='"$2"'"
          }
      }
   ],
   "template_id":"d-da9cb68e2c414c27b040a6d0162563db"
}' \
    --show-error