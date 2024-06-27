# Kismet enrichment
### Kismet datasources
http://localhost:2501/datasource/all_sources.json

 - Copy into /tmp/kismet_datasources.json on manager node
 - Place kismet-datasources.sh script onto manager
 - Run ```sudo bash kismet-datasources.sh```
   - Script will
     - Create kismet-datasources index
     - Import kismet datasources as documents
       - Only includes kismet_datasource_uuid & kismet_datasource_name
     - Creates enrich policy to match kismet uuid -> interface name
     - Executes enrich policy to initialize / update enrich index

### Update ingest pipeline
 - Update kismet.seenby ingest pipeline to match incoming docs
 ```
 {
    "enrich": {
      "field": "_ingest._value.serial_number",
      "policy_name": "kismet-enrich-policy",
      "target_field": "enrich",
      "ignore_failure": true
    }
  }
  ```



