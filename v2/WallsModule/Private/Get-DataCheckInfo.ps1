function Get-DataCheckInfo {
    # Get Matters with no EntityKeyMap
    $MatterNoKeyMap = Invoke-SqlCommand -Query "select count(*) as count from Entities e left join EntityKeyMap ekm on e.EntityId = ekm.EntityId 
        where ekm.EntityId is null and e.EntityTypeId = 4"

    # Get Matters with mismatched client/matter pairing in EntityKeyMap
    $MatterBadPairing = Invoke-SqlCommand -Query "select count(*) as count from Entities e 
        inner join entities e2 on e.entitytypeid=4 and e2.entitytypeid=3 and e.parentremotesystemid=e2.entityremotesystemid 
        left join entitykeymap ekm on ekm.entityid=e.entityid and ekm.parententityid=e2.entityid 
        where ekm.entityid is null"

    # Get Duplicate user/group/client entities
    $DuplicateEntities = Invoke-SqlCommand -Query "SELECT COUNT(*) as count from Entities e
        join Entities e2 on e.EntityTypeId=e2.EntityTypeId and e.EntityId<>e2.EntityId
        and 
        (
        e.EntityRemoteSystemId=e2.EntityRemoteSystemId
        --or ISNULL(NULLIF(e.FinancialSystemId, ''), e.EntityRemoteSystemId)=ISNULL(NULLIF(e2.FinancialSystemId, e2.EntityRemoteSystemId), '')
        --or ISNULL(NULLIF(e.TimeEntrySystemId, ''), e.EntityRemoteSystemId)=ISNULL(NULLIF(e2.TimeEntrySystemId, e2.EntityRemoteSystemId), '')
        --or ISNULL(NULLIF(e.RecordsSystemId, ''), e.EntityRemoteSystemId)=ISNULL(NULLIF(e2.RecordsSystemId, e2.EntityRemoteSystemId), '')
        --or ISNULL(NULLIF(e.WindowsNetworkLogon, ''), e.EntityRemoteSystemId)=ISNULL(NULLIF(e2.WindowsNetworkLogon, e2.EntityRemoteSystemId), '')
        )
        WHERE e.EntityTypeId<>4"

    # Duplicate matter entities
    $DuplicateMatterEntities = Invoke-SqlCommand -Query "select count(*) as count from
    (
    select EntityRemoteSystemId, entitytypeid, parentRemoteSystemId, count(entityRemotesystemid) as count from dbo.entities group by EntityRemoteSystemId, entitytypeid, parentRemoteSystemId 
    having entitytypeid=4 and count(entityRemotesystemid)>1
    ) t"

    # Matters with bad clients
    $MatterBadClients = Invoke-SqlCommand -Query "select count(*) as count
    from dbo.entities where entitytypeid=4 and (ParentRemoteSystemId is null or ParentRemoteSystemId='' or ParentTypeId<>3)"

    # Entities with blank entityRemoteSystemID
    $EntityBlankSystemID = Invoke-SqlCommand -Query "select count(*) as count
        from dbo.entities where entityremotesystemid=''"

    # Entity IDs with spaces in the name
    $EntitySpaces = Invoke-SqlCommand -Query "select count(*) as count
        from Entities 
        where ((EntityRemoteSystemId like '% ' OR EntityRemoteSystemId like ' %') 
        OR (EntityDisplayId like '% ' OR EntityDisplayId like ' %') 
        OR (TimeEntrySystemId like '% ' OR TimeEntrySystemId like ' %') 
        OR (RecordsSystemId like '% ' OR RecordsSystemId like ' %') 
        OR (FinancialSystemId like '% ' OR FinancialSystemId like ' %'))"

    [PSCustomObject]@{
        MatterNoKeyMap          = $MatterNoKeyMap.rows[0].count;
        MatterBadPairing        = $MatterBadPairing.rows[0].count;
        DuplicateEntities       = $DuplicateEntities.rows[0].count;
        DuplicateMatterEntities = $DuplicateMatterEntities.rows[0].count;
        MatterBadClients        = $MatterBadClients.rows[0].count;
        EntityBlankSystemID     = $EntityBlankSystemID.rows[0].count;
        EntitySpaces            = $EntitySpaces.rows[0].count;
    }
}