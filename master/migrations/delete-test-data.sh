curl -XDELETE 'http://localhost:9200/stats,marketing/document/_query' -d '{
     "query_string": {
               "default_field": "recipient",
               "query": "mail-tester.com www.brandonchecketts.com"
            }
}'