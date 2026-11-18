-- Task 2.1 - Try to insert duplicate appointment id into the appointments TABLE
INSERT INTO appointments (appointment_id,patient_id,clinic_id,booked_on,appt_date,age,gender,distance_km,fee_inr,
booking_channel,visit_type,reminder_sent,prior_no_shows,status,lead_days,no_show)
VALUES ('A0001','P509','C05','2025-01-24','2025-01-25',60,'F',
11.6,850,'Phone','Consultation','Yes',1,'No-Show',1,1);

-- Error shown
Error Code: 1062. Duplicate entry 'A0001' for key 'appointments.PRIMARY'



-- Task 2.2 - No Show rate by Clinic's with more than 95 appointments
select c.clinic_name, c.city, count(a.appointment_id) as appointments, sum(a.no_show) as total_no_show, ROUND((100 * SUM(no_show))/COUNT(1),1) as no_show_pct
from clinics c
inner join appointments a on c.clinic_id = a.clinic_id
group by c.clinic_id
having appointments >= 95
order by no_show_pct desc;


-- Task 2.2 - No Show rate by Clinic
select c.clinic_name, c.city, count(a.appointment_id) as appointments, sum(a.no_show) as total_no_show, ROUND((100 * SUM(no_show))/COUNT(1),1) as no_show_pct
from clinics c
inner join appointments a on c.clinic_id = a.clinic_id
group by c.clinic_id
-- having appointments >= 95
order by no_show_pct desc;


-- Task 2.3 - Appointment Bands
with appointments_bands as
( select appointment_id, no_show, lead_days,
CASE
	WHEN lead_days > 30 THEN '31+'
    WHEN lead_days > 15 THEN '15-30'
    WHEN lead_days > 7 THEN '7-14'
    ELSE '1-7'
END AS 'lead_days_band'
from appointments)
select lead_days_band, count(appointment_id) as total_appts, sum(no_show) as total_no_show,
ROUND((100 * SUM(no_show))/COUNT(1),1) as no_show_pct from appointments_bands
group by lead_days_band
order by min(lead_days);


-- Task 2.4 - Month-by-Month trend
with monthly as
( select substr(appt_date,1,7) as mnth, no_show
from appointments),
monthly_pct as
(select mnth, sum(no_show), ROUND((100 * SUM(no_show))/COUNT(1),1) as no_show_pct from monthly
group by mnth)
select mnth, no_show_pct,
(no_show_pct - lag(no_show_pct) over (order by mnth)) as lag_no_show_pct  from monthly_pct
order by mnth;


-- Task 2.5 - Rank clinics inside the city
with clinic_appts as
( select clinic_name, city, no_show from clinics c
inner join appointments a on a.clinic_id = c.clinic_id),
clinic_rates as
(select clinic_name, city, ROUND((100 * SUM(no_show))/COUNT(1),1) as no_show_pct from clinic_appts
group by clinic_name, city),
clinic_rating as
(select *, (select avg(no_show_pct) from clinic_rates) as avg_rate,
rank() over (partition by city order by no_show_pct desc) as rank_in_city from clinic_rates)
select clinic_name, city, no_show_pct, rank_in_city,
CASE
    when no_show_pct < avg_rate then 'Below'
    when no_show_pct > avg_rate then 'Above'
    else 'Equal'
END as vs_overall
from clinic_rating
order by city, rank_in_city;
