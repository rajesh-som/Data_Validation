---- Insert into data validation table
INSERT INTO [dbo].[TGT_ClmData_Validation_Dtls]
select 
'HCSC' Client_Name,cast(orig.meta_createdon as date) load_dt, 
'Duplicate Claims by Load Date' ValidationRule,
case when orig.revenue_code is not null then 'H' else 'M' end formtype,
count(distinct orig.claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] Orig
inner join [hcsc].[SRC_MDClaims] dup on orig.claim = dup.claim 
and orig.claim_num = dup.claim_num 
where cast(orig.meta_createdon as date) != cast(dup.meta_createdon as date)
group by cast(orig.meta_createdon as date), case when orig.revenue_code is not null then 'H' else 'M' end
union all
-- member validation 
select 
'HCSC' Client_Name,cast(a.meta_createdon as date) load_dt, 
'Member Not Eligible during DOS' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,
count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
left join [hcsc].[SRC_memberenrollment] m on a.member_id = m.member_id 
		and CAST(claim_start_date AS date) between CAST(effective_date AS date) and CAST(end_date AS date)
where 1=1
and m.member_id is null
group by cast(a.meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
--- claim number and claimline is null
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Claim or ClaimLine is null' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,
count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where (trim(claim) is null or trim(claim_num) is null)
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
-- claimstatus is null
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'FormType is null' ValidationRule,case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where trim(claim_status ) is null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
---- memberid is null
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'MemberId is null' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,
count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where member_id is null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
--- type of bill edits
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'TypeOfBill is null for Hospital Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where trim(type_of_bill) is null
and a.revenue_code is not null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All 
---0 not null for M
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'TypeOfBill is not null for Professional Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where trim(type_of_bill) is not null
and a.revenue_code is null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
-- length of type of bill
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Not a Valid TypeOfBill' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where len(trim(type_of_bill)) not in (3,4)
and a.revenue_code is not null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
---diag code edits
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Primary Diag Code is Null' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where trim(icddiag1) is null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
--- claimstartdate edits
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimStartDate is Null' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where trim(claim_start_date) is null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
--- claimstartdate > paiddate or current date
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimStartDate is Greater than ClaimPaidDate or SystemDate' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where ((CAST (claim_start_date AS date) > (CAST (Claim_Paid_Date AS date)  )
OR (CAST (claim_start_date AS date) > CAST(getDate() As Date)) ))
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end  
Union All
--- claimenddate edits
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimEndDate is null or Greater than ClaimPaidDate or Less than StartDate' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where (trim(claim_end_date) is null
 or (CAST (claim_end_date AS date) > CAST (Claim_Paid_Date AS date))
 or ( CAST (claim_end_date AS date) < CAST (claim_start_date AS date))
 or (CAST(claim_end_date AS date) > cast(getDate() As Date))
 )
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
---- AdmitDate is null for institutional 
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Admit Date Required for Inpatient Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where 1=1
and (admit_date = '17530101' or CAST(admit_date AS date) is null )
and substring(Type_of_Bill,1,2) = '11'
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
union all
--- admission source & admission type
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'AdmissionSourse and AdmissionType is Required for Inpatient Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where substring(Type_of_Bill,1,2) = '11'
and ((Admission_Source is null )
or (admission_type is null))
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
union all
--- discharge date validation
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Discharge Date is Required for Inpatient Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end  formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where ((Discharge_Date  = '17530101')
or (CAST(Discharge_Date  AS date) is null ))
and substring(Type_of_Bill,1,2) = '11'
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Discharge Date greater than ClaimPaidDate for Inpatient Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where CAST(Discharge_Date  AS date) > CAST(Claim_Paid_Date  AS date)
and substring(Type_of_Bill,1,2) = '11'
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end 
Union All
--- DischargeStatus validation 
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'DischargeStatus is null for Inpatient Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where substring(Type_of_Bill,1,2) = '11'
and Discharge_Status is null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end
Union All
--- claim paid date
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimPaidDate is null or Greater than sysdate' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where (((Claim_Paid_Date is null or Claim_Paid_Date = '17530101'))
or (CAST(Claim_Paid_Date  AS date) > cast(getDate() As Date)))
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end
Union All
---- drg code
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'DRG code null for Inpatient Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where substring(type_of_bill,1,2) = '11'
and trim(drg_code) is null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end
Union All
--- revenue code
select 'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Revenue code not valid Hospital Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where len(Revenue_Code) not in (3,4)
and a.revenue_code is not null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end
Union All
--- proc code
select  'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Proc code is null for Professional Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where revenue_code is null
and proc_code is null
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end
Union All
--- place of service
select  'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'POS is null for Professional Claims' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where a.revenue_code is null
and Place_Of_Service is null 
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end
Union All
select  'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Service Provider Id is null' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where Service_Prov_id is null 
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end
Union All
select  'HCSC' Client_Name,cast(meta_createdon as date) load_dt, 
'Paid Amount is null' ValidationRule,
case when a.revenue_code is not null then 'H' else 'M' end formtype,count(distinct claim),GETDATE(),user
from [hcsc].[SRC_MDClaims] a
where trim(Paid_Amt) is null 
group by cast(meta_createdon as date),case when a.revenue_code is not null then 'H' else 'M' end;