trigger MBCFailedRecords on MBCFailedRecord__e (after insert) {
    try{
        MBCService.processEvents(Trigger.New);
    } catch(Exception e) {
        MBCService.insertError(e);
    }
}