# !/bin/bash

# curl -v -k https://energy-enterprise-3310-dev-ed.my.salesforce.com/services/oauth2/authorize \
#     -d "response_type=code" \
#     -d "client_id=3MVG9hPGCoG2ZiCtIgUMXALgPfThJPnB9GkL4_jH6hy0PKriVRCpqp2dgZ7oF8QUVgyUC4VE5njFKyr6q_2_J" \
#     -d "redirect_uri=https://www.salesforce.com"

curl -v -k https://energy-enterprise-3310-dev-ed.my.salesforce.com/services/oauth2/token \
    -d "grant_type=password" \
    -d "client_id=3MVG9hPGCoG2ZiCtIgUMXALgPfThJPnB9GkL4_jH6hy0PKriVRCpqp2dgZ7oF8QUVgyUC4VE5njFKyr6q_2_J" \
    -d "client_secret=6519387C986FF88BD0CA3842D9DD63C5E27CB2DE34CAA2B1A729BAE830C7053C" \
    -d "username=devtiago@mbc-001.org" \
    -d "password=cjYoznrr8sra]MJYtc07D7tDJxv8ng6icQg4M"