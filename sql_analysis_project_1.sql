-- Підсумковий проект №1
--Тема проєкту: оцінка утримання користувачів (Retention Rate) методами Google Sheets та SQL на основі когортного аналізу (Cohort Analysis)
-- Перевірка двох таблиць на кількість унікальних користувачів та визначення можливого розміру таблиць
SELECT distinct(user_id)  
FROM cohort_users_raw
order by user_id
--LIMIT 10; 

SELECT distinct event_type  --перевірка видів event_type
FROM cohort_events_raw 
where event_type  <> 'test_event'
      and COALESCE(TRIM(event_type), '') <> ''
LIMIT 10; 


-- Завдання 1. Робота з базою даних та підготовка когортної таблиці
with tb1 as (     --Підзапит і проміжна таблиця №1 з приведенням колонки з датами до єдиного формату Timestemp
SELECT user_id,full_name, email,country,
       TO_DATE(                               -- перетворюємо результат в колонці в формат дати
            REPLACE(REPLACE(SPLIT_PART(TRIM(signup_datetime), ' ', 1), '/', '-'), '.', '-'), --замніюємо різні делімітери на '-'
            CASE 
                WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(SPLIT_PART(TRIM(signup_datetime), ' ', 1), '/', '-'), '.', '-'), '-', 3)) = 2
                THEN 'DD-MM-YY'
                ELSE 'DD-MM-YYYY'
            END
        ) AS signup_date,
       signup_source,
       signup_device,
       promo_signup_flag
FROM cohort_users_raw
),
tb2 as(           --Підзапит і проміжна таблиця №2 з приведенням колонки з датами до єдиного формату Timestemp за аналогією як 1-й таблиці
SELECT event_id, user_id, event_type, revenue,
       TO_DATE(
            REPLACE(REPLACE(SPLIT_PART(TRIM(event_datetime), ' ', 1), '/', '-'), '.', '-'),
            CASE 
                WHEN LENGTH(SPLIT_PART(REPLACE(REPLACE(SPLIT_PART(TRIM(event_datetime), ' ', 1), '/', '-'), '.', '-'), '-', 3)) = 2
                THEN 'DD-MM-YY'
                ELSE 'DD-MM-YYYY'
            END
        ) AS event_date
FROM cohort_events_raw 
)
select        --Обєднання , фільтрація та побудова фінальної агрегованої таблиці для вивантаження і когортного аналізу
       tb1.promo_signup_flag, --tb2.user_id, tb2.event_date, tb1.signup_date,
       date_trunc ('month', tb1.signup_date)::date  as chohort_month,--date_trunc ('month', tb1.signup_date)::date  as first_month,tb2.event_date
       EXTRACT('month' 
              from age(date_trunc ('month', tb2.event_date)::date,date_trunc ('month', tb1.signup_date)::date)) as month_diff,
       count (distinct(tb2.user_id)) as user_total
from tb2 
left join tb1 
on tb2.user_id=tb1.user_id
where tb2.event_date is not null
      and tb1.signup_date is not null
      and COALESCE(TRIM(tb2.event_type), '') <> ''
      and tb2.event_type <> 'test_event'
      and tb2.event_date between '2025-01-01' and '2025-06-30'  --and tb2.user_id ='1' додатковий фільтр і поля для перевірки вірності даних  
group by 1,2,3
order by 1,2,3
;



