curl -XDELETE 'http://localhost:9200/stats,marketing/_query' -d '{
    "term" : { "recipient" : "mamluka" }
}
'

curl -XDELETE 'http://localhost:9200/stats,marketing/_query' -d '{
    "term" : { "recipient" : "david.mazvovsky" }
}
'

curl -XDELETE 'http://localhost:9200/stats,marketing/_query' -d '{
    "term" : { "recipient" : "mail-tester.com" }
}
'
curl -XDELETE 'http://localhost:9200/stats,marketing/_query' -d '{
    "term" : { "recipient" : "mamluka_xomix" }
}
'
