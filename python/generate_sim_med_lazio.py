# generate_sim_med_lazio.py
# Generatore dati sintetici per piattaforma servizi medici (Regione Lazio)
# Produzione CSV: patients, providers, clinics, appointments, diagnoses, medications, lab_results, billing, feedback
# Requisiti: python 3.8+, pip install pandas numpy scikit-learn matplotlib

import numpy as np
import pandas as pd
import os, json
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

np.random.seed(42)
OUTPUT_DIR = "./sim_med_lazio"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Parametri (modificabili)
N_PATIENTS = 50000
N_APPTS = 300000
N_PROVIDERS = 400
START_DATE = datetime(2023,1,1)
END_DATE = datetime(2025,12,31)

# ----- Costruzione pazienti -----
cities = ["Roma","Latina","Frosinone","Viterbo","Rieti"]
city_weights = np.array([0.70,0.10,0.07,0.06,0.07])
city_weights = city_weights / city_weights.sum()

bucket_ranges = [(0,17),(18,34),(35,54),(55,74),(75,95)]
bucket_weights = np.array([0.12,0.22,0.33,0.23,0.10])

def sample_ages(n):
    buckets = np.random.choice(len(bucket_ranges), size=n, p=bucket_weights)
    return np.array([ np.random.randint(bucket_ranges[b][0], bucket_ranges[b][1]+1) for b in buckets ])

ages = sample_ages(N_PATIENTS)
birth_dates = [(datetime.now() - timedelta(days=int(a*365.25))).date() for a in ages]
genders = np.random.choice(["M","F"], size=N_PATIENTS, p=[0.49,0.51])
cities_assigned = np.random.choice(cities, size=N_PATIENTS, p=city_weights)
postcodes = (10000 + np.random.randint(0,9000, size=N_PATIENTS)).astype(str)
insurance = np.random.choice(["out_of_pocket","insurance","ssn"], size=N_PATIENTS, p=[0.60,0.30,0.10])
enrollment_dates = [ START_DATE + timedelta(days=int(np.random.rand() * (END_DATE-START_DATE).days)) for _ in range(N_PATIENTS) ]

def prob_by_age_array(base, ages):
    return np.clip(base * (1 + (np.maximum(0, ages-40)/60)), 0, 0.95)

base_prev = {"hypertension":0.25,"diabetes":0.06,"asthma_copd":0.06,"ischemic_heart":0.05,"obesity":0.15}
hypertension = (np.random.rand(N_PATIENTS) < prob_by_age_array(base_prev["hypertension"], ages)).astype(int)
diabetes = (np.random.rand(N_PATIENTS) < prob_by_age_array(base_prev["diabetes"], ages)).astype(int)
asthma_copd = (np.random.rand(N_PATIENTS) < prob_by_age_array(base_prev["asthma_copd"], ages)).astype(int)
ischemic_heart = (np.random.rand(N_PATIENTS) < prob_by_age_array(base_prev["ischemic_heart"], ages)).astype(int)
obesity = (np.random.rand(N_PATIENTS) < prob_by_age_array(base_prev["obesity"], ages)).astype(int)

patients = pd.DataFrame({
    "patient_id": np.arange(1,N_PATIENTS+1),
    "age": ages,
    "birth_date": birth_dates,
    "gender": genders,
    "city": cities_assigned,
    "postcode": postcodes,
    "enrollment_date": enrollment_dates,
    "hypertension": hypertension,
    "diabetes": diabetes,
    "asthma_copd": asthma_copd,
    "ischemic_heart": ischemic_heart,
    "obesity": obesity,
    "insurance_type": insurance
})

# ----- Providers e Clinics -----
specialties = [
    ("Medicina Generale", 40), ("Cardiologia", 100), ("Ortopedia", 120), ("Dermatologia", 80),
    ("Oculistica", 90), ("Pediatria", 60), ("Ginecologia", 110), ("Neurologia", 120),
    ("Otorinolaringoiatria", 85), ("Psicologia", 70), ("Endocrinologia", 95), ("Gastroenterologia", 110)
]
spec_names = [s[0] for s in specialties]
spec_base_price = {s[0]: s[1] for s in specialties}

provider_ids = np.arange(1, N_PROVIDERS+1)
prov_specs = np.random.choice(spec_names, size=N_PROVIDERS)
prov_cities = np.random.choice(cities, size=N_PROVIDERS, p=city_weights)
providers = pd.DataFrame({
    "provider_id": provider_ids,
    "specialty": prov_specs,
    "city": prov_cities,
    "joined_date": [ START_DATE + timedelta(days=int(np.random.rand()*365*3)) for _ in range(N_PROVIDERS) ],
    "active_flag": 1
})

N_CLINICS = max(10, N_PROVIDERS//8)
clinic_ids = np.arange(1, N_CLINICS+1)
clinic_cities = np.random.choice(cities, size=N_CLINICS, p=city_weights)
clinics = pd.DataFrame({
    "location_id": clinic_ids,
    "city": clinic_cities,
    "capacity": np.random.randint(1,6, size=N_CLINICS)
})
providers["location_id"] = np.random.choice(clinic_ids, size=N_PROVIDERS)

# ----- Appointments (vettoriale) -----
appt_patient_ids = np.random.choice(patients["patient_id"].values, size=N_APPTS)
appt_provider_ids = np.random.choice(providers["provider_id"].values, size=N_APPTS)
appt_location_ids = np.random.choice(clinics["location_id"].values, size=N_APPTS)

# Scheduled datetimes (weekday + seasonality)
total_days = (END_DATE - START_DATE).days + 1
day_offsets = np.arange(total_days)
dates = np.array([START_DATE + timedelta(days=int(d)) for d in day_offsets])
wd = np.array([d.weekday() for d in dates])
months = np.array([d.month for d in dates])
weights = np.where(wd<5, 1.2, 0.6) * np.where(np.isin(months, [12,1,2]), 1.2, 1.0)
probs = weights / weights.sum()
chosen_days = np.random.choice(day_offsets, size=N_APPTS, p=probs)
r = np.random.rand(N_APPTS)
hours = np.where(r<0.45, np.random.randint(9,12,size=N_APPTS),
                 np.where(r<0.85, np.random.randint(14,17,size=N_APPTS), np.random.randint(17,19,size=N_APPTS)))
minutes = np.random.choice([0,15,30,45], size=N_APPTS)
scheduled_datetimes = np.array([ START_DATE + timedelta(days=int(d), hours=int(h), minutes=int(m)) for d,h,m in zip(chosen_days,hours,minutes) ])

# lead_time e booking
lead_time_days = np.clip(np.random.exponential(scale=10, size=N_APPTS).astype(int), 0, 365)
booking_datetimes = scheduled_datetimes - np.array([timedelta(days=int(x)) for x in lead_time_days])
booking_datetimes = np.array([ max(START_DATE, bd) for bd in booking_datetimes ])

# appointment type trend per anno
appt_years = np.array([d.year for d in scheduled_datetimes])
telemed_prob = np.where(appt_years==2023, 0.12, np.where(appt_years==2024, 0.17, 0.22))
appointment_types = (np.random.rand(N_APPTS) < telemed_prob).astype(int)
appointment_type_str = np.where(appointment_types==1, "telemedicine","in-person")

# no-show propensity (patient-level + aggiustamenti)
base_no_show = 0.09
patient_propensity = np.clip(base_no_show * (1 + np.random.normal(0,0.6,size=N_PATIENTS)), 0.01, 0.5)
patient_prop_for_appt = patient_propensity[appt_patient_ids - 1]

p_no_show = patient_prop_for_appt.copy()
p_no_show += np.where(lead_time_days>30, 0.05, 0.0)
p_no_show += np.where(lead_time_days==0, 0.03, 0.0)
appt_patient_ages = ages[appt_patient_ids - 1]
p_no_show += np.where(appt_patient_ages<35, 0.02, 0.0)
p_no_show = np.where(appointment_types==1, p_no_show * 0.8, p_no_show)
reminder_sent = (np.random.rand(N_APPTS) < 0.75).astype(int)
p_no_show = np.where(reminder_sent==1, p_no_show * 0.6, p_no_show)
p_no_show = np.clip(p_no_show, 0.001, 0.9)

rand_draw = np.random.rand(N_APPTS)
statuses = np.where(rand_draw < p_no_show, "no-show",
                    np.where(np.random.rand(N_APPTS) < 0.07, "cancelled", "completed"))

# durata e prezzo
prov_spec_map = dict(zip(providers["provider_id"].values, providers["specialty"].values))
prov_specs_for_appt = np.array([prov_spec_map[pid] for pid in appt_provider_ids])
durations = np.where(prov_specs_for_appt=="Medicina Generale", np.random.randint(10,25,size=N_APPTS),
            np.where(np.isin(prov_specs_for_appt, ["Dermatologia","Pediatria","Psicologia"]), np.random.randint(15,35,size=N_APPTS),
                     np.random.randint(20,45,size=N_APPTS)))
base_price_map = {s[0]: s[1] for s in specialties}
base_prices_for_appt = np.array([ base_price_map.get(s,50) for s in prov_specs_for_appt ])
extras = ((np.random.rand(N_APPTS) < 0.12) * (np.random.uniform(30,300,size=N_APPTS).astype(int)))
prices = (np.random.normal(loc=base_prices_for_appt, scale=20).astype(int)).clip(min=15) + extras

appointments = pd.DataFrame({
    "appointment_id": np.arange(1,N_APPTS+1),
    "patient_id": appt_patient_ids,
    "provider_id": appt_provider_ids,
    "location_id": appt_location_ids,
    "booking_datetime": booking_datetimes,
    "scheduled_datetime": scheduled_datetimes,
    "lead_time_days": lead_time_days,
    "appointment_type": appointment_type_str,
    "status": statuses,
    "duration_min": durations,
    "price_eur": prices,
    "reminder_sent": reminder_sent
})

# ----- Diagnosi, farmaci, lab, billing, feedback -----
ICD10_list = [
    "I10", "E11", "J06.9", "M54.5", "K21.0", "N39.0", "F41.9", "L20.9", "H52.4", "R51",
    "J45.9", "M25.5", "H66.9", "K29.7", "R10.4", "I48.9", "G43.9", "L03.9", "N30.0", "H52.1",
    "M17.9", "Z00.0", "Z23", "R05", "R07.9", "E78.5", "I25.1", "F32.9", "K21.9", "M79.1"
]
icd_probs = np.ones(len(ICD10_list)) / len(ICD10_list)
completed_mask = appointments["status"]=="completed"
completed_appts = appointments[completed_mask].copy().reset_index(drop=True)
n_completed = len(completed_appts)
chosen_icd = np.random.choice(ICD10_list, size=n_completed, p=icd_probs)

# Boost E11 per pazienti diabetici
patient_diabetes_flag = diabetes[completed_appts["patient_id"].values - 1] == 1
diab_indices = np.where(patient_diabetes_flag)[0]
if len(diab_indices)>0:
    sel = np.random.choice(diab_indices, size=int(len(diab_indices)*0.25), replace=False)
    chosen_icd[sel] = "E11"

diag_df = pd.DataFrame({
    "diagnosis_id": np.arange(1, n_completed+1),
    "appointment_id": completed_appts["appointment_id"].values,
    "patient_id": completed_appts["patient_id"].values,
    "icd10_code": chosen_icd,
    "diagnosis_date": pd.to_datetime(completed_appts["scheduled_datetime"]).dt.date.values
})

# Meds (35% of completed)
ATC_list = ["A02","A10","C09","N02","J01","R03","M01","N05","A03","B01","C07","G03","S01","D07","H02","R01","J05"]
pres_mask = (np.random.rand(n_completed) < 0.35)
pres_count = pres_mask.sum()
med_df = pd.DataFrame({
    "med_id": np.arange(1, pres_count+1),
    "appointment_id": diag_df.loc[pres_mask, "appointment_id"].values,
    "patient_id": diag_df.loc[pres_mask, "patient_id"].values,
    "atc_code": np.random.choice(ATC_list, size=pres_count),
    "dose_info": ["standard"]*pres_count,
    "duration_days": np.random.choice([5,7,14,30], size=pres_count),
    "prescribed_date": diag_df.loc[pres_mask,"diagnosis_date"].values
})

# Lab (25% of completed -> 1 test each, vectorized)
lab_mask = (np.random.rand(n_completed) < 0.25)
sel_appt_ids = diag_df.loc[lab_mask, "appointment_id"].values
sel_patient_ids = diag_df.loc[lab_mask, "patient_id"].values
sel_tests = np.random.choice(["HbA1c","Glucose","Creatinine","TotalCholesterol","TSH","Hemoglobin"], size=sel_appt_ids.size)
lab_ids = np.arange(1, len(sel_appt_ids)+1)
test_name = sel_tests
result_values = np.zeros(len(sel_appt_ids))
unit = np.empty(len(sel_appt_ids), dtype=object)
ref_min = np.zeros(len(sel_appt_ids))
ref_max = np.zeros(len(sel_appt_ids))

for t in ["HbA1c","Glucose","Creatinine","TotalCholesterol","TSH","Hemoglobin"]:
    mask_t = (test_name == t)
    if mask_t.sum()==0:
        continue
    idxs = np.where(mask_t)[0]
    pids = sel_patient_ids[idxs]
    if t=="HbA1c":
        vals = np.random.normal(loc=np.where(diabetes[pids-1]==1, 7.2, 5.4), scale=0.8)
        unit[idxs] = "%"; ref_min[idxs]=4.0; ref_max[idxs]=5.7
    elif t=="Glucose":
        vals = np.random.normal(loc=np.where(diabetes[pids-1]==1,110,92), scale=15)
        unit[idxs]="mg/dL"; ref_min[idxs]=70; ref_max[idxs]=110
    elif t=="Creatinine":
        vals = np.random.normal(loc=0.9, scale=0.2, size=idxs.size); unit[idxs]="mg/dL"; ref_min[idxs]=0.6; ref_max[idxs]=1.3
    elif t=="TotalCholesterol":
        vals = np.random.normal(loc=200, scale=35, size=idxs.size); unit[idxs]="mg/dL"; ref_min[idxs]=120; ref_max[idxs]=200
    elif t=="TSH":
        vals = np.random.normal(loc=2.0, scale=0.8, size=idxs.size); unit[idxs]="mU/L"; ref_min[idxs]=0.4; ref_max[idxs]=4.0
    elif t=="Hemoglobin":
        vals = np.random.normal(loc=14, scale=1.2, size=idxs.size); unit[idxs]="g/dL"; ref_min[idxs]=12; ref_max[idxs]=17
    result_values[idxs] = np.round(vals,3)

appointment_schedule_map = dict(zip(appointments["appointment_id"].values, appointments["scheduled_datetime"].values))
sample_datetimes = [appointment_schedule_map.get(aid) for aid in sel_appt_ids]

lab_results = pd.DataFrame({
    "lab_id": lab_ids,
    "appointment_id": sel_appt_ids,
    "patient_id": sel_patient_ids,
    "test_name": test_name,
    "result_value": result_values,
    "unit": unit,
    "ref_min": ref_min,
    "ref_max": ref_max,
    "sample_datetime": sample_datetimes
})

# Billing e feedback
billing_df = pd.DataFrame({
    "invoice_id": np.arange(1, n_completed+1),
    "appointment_id": completed_appts["appointment_id"].values,
    "patient_id": completed_appts["patient_id"].values,
    "total_amount_eur": completed_appts["price_eur"].values,
    "paid_flag": (np.random.rand(n_completed) < 0.9).astype(int),
    "payment_method": np.random.choice(["card","cash","insurance_billing"], size=n_completed, p=[0.6,0.2,0.2]),
    "invoice_date": pd.to_datetime(completed_appts["scheduled_datetime"]).dt.date.values
})

fb_mask = (np.random.rand(n_completed) < 0.18)
feedback_df = pd.DataFrame({
    "feedback_id": np.arange(1, fb_mask.sum()+1),
    "appointment_id": diag_df.loc[fb_mask,"appointment_id"].values,
    "patient_id": diag_df.loc[fb_mask,"patient_id"].values,
    "rating": np.clip(np.random.normal(loc=4.2, scale=0.8, size=fb_mask.sum()).round().astype(int),1,5),
    "submitted_date": diag_df.loc[fb_mask,"diagnosis_date"].values
})

# Save CSVs
patients.to_csv(os.path.join(OUTPUT_DIR, "patients.csv"), index=False)
providers.to_csv(os.path.join(OUTPUT_DIR, "providers.csv"), index=False)
clinics.to_csv(os.path.join(OUTPUT_DIR, "clinics.csv"), index=False)
appointments.to_csv(os.path.join(OUTPUT_DIR, "appointments.csv"), index=False)
diag_df.to_csv(os.path.join(OUTPUT_DIR, "diagnoses.csv"), index=False)
med_df.to_csv(os.path.join(OUTPUT_DIR, "medications.csv"), index=False)
lab_results.to_csv(os.path.join(OUTPUT_DIR, "lab_results.csv"), index=False)
billing_df.to_csv(os.path.join(OUTPUT_DIR, "billing.csv"), index=False)
feedback_df.to_csv(os.path.join(OUTPUT_DIR, "feedback.csv"), index=False)

# README syntheses
readme = f"""
Simulazione dataset: piattaforma servizi medici - Regione Lazio
Periodo: {START_DATE.date()} → {END_DATE.date()}
Numero records:
 - patients: {len(patients)}
 - providers: {len(providers)}
 - clinics: {len(clinics)}
 - appointments: {len(appointments)}
 - diagnoses: {len(diag_df)}
 - medications: {len(med_df)}
 - lab_results: {len(lab_results)}
 - billing: {len(billing_df)}
 - feedback: {len(feedback_df)}
Files generati in: {OUTPUT_DIR}
"""
with open(os.path.join(OUTPUT_DIR, "README_simulazione.md"), "w") as f:
    f.write(readme)

print("Generazione completata. I file CSV sono salvati in:", OUTPUT_DIR)