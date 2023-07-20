import { LightningElement } from 'lwc';

import run from '@salesforce/apex/MemberBalanceCheckController.run';
import runFailed from '@salesforce/apex/MemberBalanceCheckController.runFailed';
import getRecord from '@salesforce/apex/MemberBalanceCheckController.getRecord';

import MemberBalanceStatus from '@salesforce/label/c.MemberBalanceStatus';
import SubmittedOn from '@salesforce/label/c.SubmittedOn';
import Progress from '@salesforce/label/c.Progress';
import TotalJobItems from '@salesforce/label/c.TotalJobItems';
import JobItemsProcessed from '@salesforce/label/c.JobItemsProcessed';
import NumberOfErrors from '@salesforce/label/c.NumberOfErrors';
import ElapsedTime from '@salesforce/label/c.ElapsedTime';
import ETA from '@salesforce/label/c.ETA';
import LastExecutionTitle from '@salesforce/label/c.LastExecutionTitle';
import Run from '@salesforce/label/c.Run';
import RunFailed from '@salesforce/label/c.RunFailed';
import Refresh from '@salesforce/label/c.Refresh';
import CompletedOn from '@salesforce/label/c.CompletedOn';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class BMemberBalanceCheckStatus extends LightningElement {
    label = {
        MemberBalanceStatus,
        SubmittedOn,
        Progress,
        TotalJobItems,
        JobItemsProcessed,
        NumberOfErrors,
        ElapsedTime,
        ETA,
        LastExecutionTitle,
        Run,
        RunFailed,
        Refresh,
        CompletedOn
    }

    record = {};

    connectedCallback() {
        this.callGetRecord();
    }

    handleRunClick() {
        this.callRun();
    }

    handleRunFailedClick() {
        this.callRunFailed();
    }

    handleRefreshClick() {
        this.callGetRecord();
    }

    async callRun() {
        try {
            this.record = await run();
        } catch (error) {
            this.handleError(error);
        }
    }

    async callRunFailed() {
        try {
            this.record = await runFailed();
        } catch (error) {
            this.handleError(error);
        }
    }

    async callGetRecord() {
        try {
            let record = await getRecord();

            this.record = record || {};
        } catch (error) {
            this.handleError(error);
        }
    }

    handleError(error) {
        try {
            console.error(error);
            const errorEvent = new ShowToastEvent({
              title: this.label.fielo_error,
              message: error &&
                error.body &&
                error.body.message ||
                (error && error.name && error.name+':') +
                (error && error.message && error.message),
              variant: 'error',
              mode: 'dismissable'
            });
            this.dispatchEvent(errorEvent);
        } catch (error) {
            console.error(error);
        }
        this.showSpinner = false;
        this.isLoading = false;
    }
}