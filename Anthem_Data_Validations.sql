---- Insert into data validation table

INSERT INTO [dbo].[TGT_ClmData_Validation_Dtls]
select --orig.formtype,cast(orig.meta_createdon as date),count(*)
'Anthem' Client_Name,cast(orig.meta_createdon as date) load_dt, 
'Duplicate Claims by Load Date' ValidationRule,
orig.formtype,count(distinct orig.claim),GETDATE(),user
--count(distinct a.claim)--distinct m.memberid,a.claim,a.memberid,a.medicareid, a.claimstartdate
from [anthem].[SRC_MDClaims] Orig
inner join [anthem].[SRC_MDClaims] dup on orig.claim = dup.claim 
and orig.claimline = dup.claimline 
where cast(orig.meta_createdon as date) != cast(dup.meta_createdon as date)
group by orig.formtype,cast(orig.meta_createdon as date)
union all
-- member validation 
--INSERT INTO [ANTHEM].[TGT_ClmData_Validation_Dtls]
select 
'Anthem' Client_Name,cast(a.meta_createdon as date) load_dt, 
'Member Not Eligible during DOS' ValidationRule,
a.formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] a
left join [anthem].[SRC_memberenrollment] m on a.memberid = m.memberid and a.medicareid = m.hicn 
		and CAST(claimstartdate AS date) between CAST(healthcoverageStartdate AS date) and CAST(healthcoverageEndDate AS date)
where 1=1--a.formtype = 'M'
--and cast(a.meta_createdon as date) = '2021-11-08'
and m.memberid is null
group by cast(a.meta_createdon as date),a.formtype
Union All
--- claim number and claimline is null
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Claim or ClaimLine is null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where (trim(claim) is null or trim(claimline) is null)
group by cast(meta_createdon as date),formtype
Union All
--- formtype is null
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'FormType is null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where trim(formtype) is null
group by cast(meta_createdon as date),formtype
Union All
--- LobDescription 
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'LOB is null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where trim(LOBdescription ) is null
group by cast(meta_createdon as date),formtype
Union All
-- claimstatus is null
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'FormType is null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where trim(claimstatus ) is null
group by cast(meta_createdon as date),formtype
Union All
---- memberid is null
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'MemberId or MBI Number is null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where (trim(memberid ) is null or trim(medicareid ) is null)
group by cast(meta_createdon as date),formtype
Union All
--- type of bill edits
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'TypeOfBill is null for Hospital Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] a
where trim(typeofbill) is null
and formtype = 'H'
group by cast(meta_createdon as date),formtype
Union All 
---0 not null for M
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'TypeOfBill is not null for Professional Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] a
where trim(typeofbill) is not null
and formtype = 'M'
group by cast(meta_createdon as date),formtype
Union All
-- length of type of bill
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Not a Valid TypeOfBill' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where len(trim(typeofbill)) not in (3,4)
and formtype = 'H'
group by cast(meta_createdon as date),formtype
Union All
---diag code edits
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Primary Diag Code is Null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] a
where trim(ICD10Diagnosis01) is null
group by cast(meta_createdon as date),formtype
Union All
--- claimstartdate edits
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimStartDate is Null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where trim(claimstartdate) is null
group by cast(meta_createdon as date),formtype
Union All
--- claimstartdate > paiddate or current date
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimStartDate is Greater than ClaimPaidDate or SystemDate' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where ((CAST (claimstartdate AS date) > (CAST (ClaimPaidDate AS date)  )
OR (CAST (claimstartdate AS date) > CAST(getDate() As Date)) ))
group by cast(meta_createdon as date),formtype
Union All
--- claimenddate edits
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimEndDate is null or Greater than ClaimPaidDate or Less than StartDate' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where (trim(claimenddate) is null
 or (CAST (claimenddate AS date) > CAST (ClaimPaidDate AS date))
 or ( CAST (claimenddate AS date) < CAST (claimstartdate AS date))
 or (CAST(claimenddate AS date) > cast(getDate() As Date))
 )
group by cast(meta_createdon as date),formtype
Union All
---- AdmitDate is null for institutional 
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Admit Date Required for Inpatient Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'H'
and (admitdate = '17530101' or CAST(admitdate AS date) is null )
and substring(TypeofBill,1,2) = '11'
group by cast(meta_createdon as date),formtype
union all
--- admission source & admission type
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'AdmissionSourse and AdmissionType is Required for Inpatient Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'H'
and substring(TypeofBill,1,2) = '11'
and ((AdmissionSource is null )
or (admissiontype is null))
group by cast(meta_createdon as date),formtype
union all
--- discharge date validation
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Discharge Date is Required for Inpatient Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'H'
and ((DischargeDate  = '17530101')
or (CAST(DischargeDate  AS date) is null ))
and substring(TypeofBill,1,2) = '11'
group by cast(meta_createdon as date),formtype
Union All
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Discharge Date greater than ClaimPaidDate for Inpatient Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'H'
and CAST(DischargeDate  AS date) > CAST(ClaimPaidDate  AS date)
and substring(TypeofBill,1,2) = '11'
group by cast(meta_createdon as date),formtype
Union All
--- DischargeStatus validation 
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'DischargeStatus is null for Inpatient Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'H'
and substring(TypeofBill,1,2) = '11'
and DischargeStatus is null
group by cast(meta_createdon as date),formtype
Union All
--- claim paid date
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'ClaimPaidDate is null or Greater than sysdate' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where (((ClaimPaidDate is null or ClaimPaidDate = '17530101'))
or (CAST(ClaimPaidDate  AS date) > cast(getDate() As Date)))
group by cast(meta_createdon as date),formtype
Union All
---- drg code
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'DRG code null for Inpatient Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'H'
and substring(typeofbill,1,2) = '11'
and trim(drgcode) is null
group by cast(meta_createdon as date),formtype
Union All
--- revenue code
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Revenue code is null or not valid Hospital Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'H'
and ((trim(RevenueCode)  is null)
or (len(RevenueCode) not in (3,4)))
group by cast(meta_createdon as date),formtype
Union All
select 'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Revenue code is not null for Professional Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'M'
and RevenueCode is not null
group by cast(meta_createdon as date),formtype
Union All
--- proc code
select  'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Proc code is null for Professional Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'M'
and proccode is null
group by cast(meta_createdon as date),formtype
Union All
--- place of service
select  'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'POS is null for Professional Claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where formtype = 'M'
and PlaceOfService is null 
group by cast(meta_createdon as date),formtype
Union All
select  'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'ServiceProvNPI is null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where 1=1--formtype = 'M'
and ServiceProvNPI is null 
group by cast(meta_createdon as date),formtype
Union All
select  'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Billed Amount is null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where trim(BilledAmt) is null 
group by cast(meta_createdon as date),formtype
Union All
select  'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'Paid Amount is null' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where trim(PaidAmt) is null 
group by cast(meta_createdon as date),formtype
Union All
select  'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'BilledDays are null for hospital claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where trim(billeddays) is null 
and formtype = 'H'
group by cast(meta_createdon as date),formtype
Union All
select  'Anthem' Client_Name,cast(meta_createdon as date) load_dt, 
'BilledDays are null for hospital claims' ValidationRule,
formtype,count(distinct claim),GETDATE(),user
from [anthem].[SRC_MDClaims] 
where trim(allowedunits) > billedunits
group by cast(meta_createdon as date),formtype

commit;