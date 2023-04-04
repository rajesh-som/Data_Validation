--- insert into validation table
INSERT INTO [dbo].[TGT_ClmData_Validation_Dtls]
select 
'CNC' Client_Name,cast(orig.meta_createdon as date) load_dt, 
'Duplicate Claims by Load Date' ValidationRule,
orig.CLAIM_TYPE_DESC,count(distinct orig.claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] Orig
inner join [CNC].[SRC_MDClaims] dup on orig.claim_NBR = dup.claim_NBR 
and orig.SERV_LINE = dup.SERV_LINE 
where cast(orig.meta_createdon as date) != cast(dup.meta_createdon as date)
group by orig.CLAIM_TYPE_DESC,cast(orig.meta_createdon as date)
union all
-- member validation 
select 
'CNC' Client_Name,cast(a.meta_createdon as date) load_dt, 
'Member Not Eligible during DOS' ValidationRule,
a.CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] a
left join [CNC].[SRC_memberenrollment] m on a.memb_id = m.memb_id 
		and CAST(serv_start_date AS date) between CAST(effective_date AS date) and CAST(term_date AS date)
where m.memb_id is null
group by cast(a.meta_createdon as date),a.CLAIM_TYPE_DESC
Union All
--- claim number and claimline is null
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Claim or ClaimLine is null' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where (trim(claim_NBR) is null or trim(serv_line) is null)
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- CLAIM_TYPE_DESC is null
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'CLAIM_TYPE_DESC is null' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where trim(CLAIM_TYPE_DESC) is null
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
---- memberid is null
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'MemberId or MBI Number is null' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where trim(memb_id ) is null 
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- type of bill edits
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'TypeOfBill is null for Hospital Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] a
where trim(bill_type) is null
and UB_IND = 'Y'
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All 
---0 not null for M
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'TypeOfBill is not null for Professional Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] a
where trim(bill_type) is not null
and UB_IND != 'Y'
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
-- length of type of bill
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Not a Valid TypeOfBill' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where len(trim(bill_type)) not in (3,4)
and UB_IND = 'Y'
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
---diag code edits
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Primary Diag Code is Null' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] a
where trim(ICD_dx_code_1) is null
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- claimstartdate edits
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimStartDate is Null' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where trim(serv_start_date) is null
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- claimstartdate > paiddate or current date
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Invalid claim_paid_date' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where len(claim_paid_date) != 8
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- claimstartdate > paiddate or current date
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimStartDate is Greater than ClaimPaidDate or SystemDate' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from (select * from [CNC].[SRC_MDClaims] where len(serv_start_date) = 8 and len(serv_start_date) = 8) a
where (CAST (a.serv_start_date AS date) > CAST (a.Claim_Paid_Date AS date))
OR (CAST (a.serv_start_date AS date) > CAST(getDate() As Date))
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- claimenddate edits
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimEndDate is null or Greater than ClaimPaidDate or Less than StartDate' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where (trim(serv_end_date) is null
 or (CAST (serv_end_date AS date) > CAST (Claim_Paid_Date AS date))
 or ( CAST (serv_end_date AS date) < CAST (serv_start_date AS date))
 or (CAST(serv_end_date AS date) > cast(getDate() As Date))
 )
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All*/
---- AdmitDate is null for institutional 
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Admit Date Required for Inpatient Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind = 'Y'
and (admit_date = '17530101' or CAST(admit_date AS date) is null )
and substring(bill_type,1,2) = '11'
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
union all
--- admission source & admission type
/*select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'AdmissionSourse and AdmissionType is Required for Inpatient Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind = 'Y'
and substring(bill_type,1,2) = '11'
and ((AdmissionSource is null )
or (admissiontype is null))
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
union all*/
--- discharge date validation
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Discharge Date is Required for Inpatient Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind = 'Y'
and ((disch_date  = '17530101')
or (CAST(disch_date  AS date) is null ))
and substring(bill_type,1,2) = '11'
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
/*Union All
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Discharge Date greater than ClaimPaidDate for Inpatient Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind = 'Y'
and CAST(trim(disch_date)  AS date) > CAST(trim(Claim_Paid_Date)  AS date)
and substring(bill_type,1,2) = '11'
group by cast(meta_createdon as date),CLAIM_TYPE_DESC*/
Union All
--- DischargeStatus validation 
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'DischargeStatus is null for Inpatient Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind = 'Y'
and substring(bill_type,1,2) = '11'
and disc_status_cd is null
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
/*Union All
--- claim paid date
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimPaidDate is null or Greater than sysdate' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where (((Claim_Paid_Date is null or Claim_Paid_Date = '17530101'))
or (CAST(Claim_Paid_Date  AS date) > cast(getDate() As Date)))
group by cast(meta_createdon as date),CLAIM_TYPE_DESC*/
Union All
---- drg code
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'DRG code null for Inpatient Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind = 'Y'
and substring(bill_type,1,2) = '11'
and trim(drg_code) is null
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- revenue code
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Revenue code is null or not valid Hospital Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind = 'Y'
and ((trim(rev_code)  is null)
or (len(rev_code) not in (3,4)))
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
select 'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Revenue code is not null for Professional Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind = 'Y'
and rev_code is not null
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- proc code
select  'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Proc code is null for Professional Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind != 'Y'
and procedure_code is null
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
--- place of service
select  'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'POS is null for Professional Claims' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where ub_ind != 'Y'
and plc_of_service is null 
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
select  'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'ServiceProvNPI is null' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where 1=1--CLAIM_TYPE_DESC = 'M'
and bill_prov_npi is null 
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
select  'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Billed Amount is null' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where trim(amt_billed) is null 
group by cast(meta_createdon as date),CLAIM_TYPE_DESC
Union All
select  'CNC' Client_Name,cast(meta_createdon as date) load_dt, 
'Paid Amount is null' ValidationRule,
CLAIM_TYPE_DESC,count(distinct claim_NBR),GETDATE(),user
from [CNC].[SRC_MDClaims] 
where trim(amt_total_paid) is null 
group by cast(meta_createdon as date),CLAIM_TYPE_DESC


