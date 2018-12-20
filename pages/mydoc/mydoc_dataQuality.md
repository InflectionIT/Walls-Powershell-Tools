---
title: Perform Data Quality Checks
last_updated: December 20, 2018
keywords: data, quality, check, clients, matters, entities, users
sidebar: mydoc_sidebar
permalink: mydoc_dataQuality.html
folder: mydoc
toc: false
---

## Overview

This command will perform data quality checks on the entities (clients/matters/users/groups) to ensure proper data integrity

### Quality Checks

The command reports the following information:
* \# of matters with no EntityKeyMap
* \# of matters with mismatched client/matter pairing in EntityKeyMap
* \# of duplicate user/group/client entities
* \# of duplicate matter entities
* \# of matters with bad clients
* \# of entities with blank entityRemoteSystemId
* \# of entity IDs with spaces in the name

If any of these data integrity issues are found, please make the necessary changes to resolve them

## Output 

The command will indicate that the full repair has started

{% include image.html file="IISPrereqs.png" alt="Command output" caption="Results of command execution" %}

## SQL commands

#### Matters with no EntityKeyMap
```sql
select count(*) as count from Entities e left join EntityKeyMap ekm on e.EntityId = ekm.EntityId where ekm.EntityId is null and e.EntityTypeId = 4
```

#### Matters with mismatched client/matter pairing in EntityKeyMap
```sql
select count(*) as count from Entities e inner join entities e2 on e.entitytypeid=4 and e2.entitytypeid=3 and e.parentremotesystemid=e2.entityremotesystemid left join entitykeymap ekm on ekm.entityid=e.entityid and ekm.parententityid=e2.entityid where ekm.entityid is null
```

#### Duplicate user/group/client entities
```sql
SELECT COUNT(*) as count from Entities e
        join Entities e2 on e.EntityTypeId=e2.EntityTypeId and e.EntityId<>e2.EntityId
        and ( e.EntityRemoteSystemId=e2.EntityRemoteSystemId )
        WHERE e.EntityTypeId<>4
```

#### Duplicate matter entities
```sql
select count(*) as count from
    ( select EntityRemoteSystemId, entitytypeid, parentRemoteSystemId, count(entityRemotesystemid) as count from dbo.entities group by EntityRemoteSystemId, entitytypeid, parentRemoteSystemId 
    having entitytypeid=4 and count(entityRemotesystemid)>1
    ) t
```

#### Matters with bad clients
```sql
select count(*) as count
    from dbo.entities where entitytypeid=4 and (ParentRemoteSystemId is null or ParentRemoteSystemId='' or ParentTypeId<>3)
```

#### Entities with blank entityRemoteSystemId
```sql
select count(*) as count from dbo.entities where entityremotesystemid=''
```

#### Entity IDs with spaces in the name
```sql
select count(*) as count
        from Entities 
        where ((EntityRemoteSystemId like '% ' OR EntityRemoteSystemId like '%') 
        OR (EntityDisplayId like '% ' OR EntityDisplayId like ' %') 
        OR (TimeEntrySystemId like '% ' OR TimeEntrySystemId like ' %') 
        OR (RecordsSystemId like '% ' OR RecordsSystemId like ' %') 
        OR (FinancialSystemId like '% ' OR FinancialSystemId like ' %'))
```