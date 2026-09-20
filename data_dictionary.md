# Data Dictionary — Medical Platform Report

Descrizione dello schema dati per la piattaforma simulata di servizi medici (Regione Lazio). Fonte: `python/generate_sim_med_lazio.py` (logica di generazione) e `sql/01_schema_creation.sql` (schema relazionale).

Periodo dati: 2023-01-01 → 2025-12-31. Tutti i dati sono **sintetici**, generati con seed fisso (`np.random.seed(42)`) per riproducibilità.

---

## 1. `patients`

Anagrafica pazienti.

| Campo | Tipo | Descrizione |
|---|---|---|
| `patient_id` | INT (PK) | Identificativo univoco paziente |
| `age` | INT | Età al momento della generazione, campionata per fasce (0-17, 18-34, 35-54, 55-74, 75-95) |
| `birth_date` | DATE | Data di nascita calcolata da `age` |
| `gender` | VARCHAR(10) | `M` / `F` |
| `city` | VARCHAR(100) | Città di residenza (Roma, Latina, Frosinone, Viterbo, Rieti — pesata 70% su Roma) |
| `postcode` | VARCHAR(10) | CAP — **generato casualmente** (range 10000–19000), non corrisponde ai CAP reali delle province laziali. Vedi Nota metodologica §5 |
| `enrollment_date` | DATE | Data di iscrizione alla piattaforma |
| `hypertension` | BOOLEAN | Ipertensione (1/0) — prevalenza crescente con l'età |
| `diabetes` | BOOLEAN | Diabete (1/0) — prevalenza crescente con l'età |
| `asthma_copd` | BOOLEAN | Asma/BPCO (1/0) |
| `ischemic_heart` | BOOLEAN | Cardiopatia ischemica (1/0) |
| `obesity` | BOOLEAN | Obesità (1/0) |
| `insurance_type` | VARCHAR(50) | `out_of_pocket` (60%) / `insurance` (30%) / `ssn` (10%) |

## 2. `providers`

Medici/professionisti sanitari.

| Campo | Tipo | Descrizione |
|---|---|---|
| `provider_id` | INT (PK) | Identificativo univoco provider |
| `specialty` | VARCHAR(100) | Una tra 12 specialità (Medicina Generale, Cardiologia, Ortopedia, Dermatologia, Oculistica, Pediatria, Ginecologia, Neurologia, Otorinolaringoiatria, Psicologia, Endocrinologia, Gastroenterologia) |
| `city` | VARCHAR(100) | Città in cui opera prevalentemente |
| `joined_date` | DATE | Data di ingresso in piattaforma |
| `active_flag` | BOOLEAN | Provider attivo (sempre 1 nel dataset attuale) |
| `location_id` | INT | Struttura di riferimento — **riferimento logico** a `clinics.location_id` (non vincolato da FOREIGN KEY nello schema attuale) |

## 3. `clinics`

Strutture/sedi.

| Campo | Tipo | Descrizione |
|---|---|---|
| `location_id` | INT (PK) | Identificativo struttura |
| `city` | VARCHAR(100) | Città della struttura |
| `capacity` | INT | Capacità (1–5, valore arbitrario di simulazione) |

## 4. `appointments`

Tabella transazionale centrale.

| Campo | Tipo | Descrizione |
|---|---|---|
| `appointment_id` | INT (PK) | Identificativo univoco appuntamento |
| `patient_id` | INT (FK → patients) | Paziente |
| `provider_id` | INT (FK → providers) | Provider |
| `location_id` | INT (FK → clinics) | Struttura |
| `booking_datetime` | DATETIME | Data/ora di prenotazione |
| `scheduled_datetime` | DATETIME | Data/ora pianificata dell'appuntamento |
| `lead_time_days` | INT | Giorni tra prenotazione e appuntamento (distribuzione esponenziale, max 365) |
| `appointment_type` | VARCHAR(50) | `in-person` / `telemedicine` (quota telemedicina in crescita 12%→17%→22% dal 2023 al 2025) |
| `status` | VARCHAR(50) | `completed` / `no-show` / `cancelled` |
| `duration_min` | INT | Durata in minuti, variabile per specialità |
| `price_eur` | DECIMAL(10,2) | Prezzo della prestazione |
| `reminder_sent` | BOOLEAN | Reminder inviato (1/0) — riduce la probabilità di no-show |

**Nota su `status`:** la probabilità di no-show dipende da propensione individuale del paziente, lead time, età, tipo di appuntamento e invio reminder — vedi logica completa nello script Python.

## 5. `diagnoses`

Diagnosi associate agli appuntamenti completati.

| Campo | Tipo | Descrizione |
|---|---|---|
| `diagnosis_id` | INT (PK) | Identificativo diagnosi |
| `appointment_id` | INT (FK → appointments) | Appuntamento di riferimento |
| `patient_id` | INT (FK → patients) | Paziente |
| `icd10_code` | VARCHAR(10) | Codice ICD-10 (vedi legenda sotto) |
| `diagnosis_date` | DATE | Data diagnosi (= data appuntamento) |

### Legenda codici ICD-10 utilizzati

> I codici sono reali (classificazione OMS ICD-10), ma **l'assegnazione ai pazienti è sintetica/casuale** — con un boost intenzionale del codice `E11` sui pazienti con flag `diabetes=1`, per dare coerenza minima al dataset. Non rappresentano percorsi clinici realistici.

| Codice | Descrizione |
|---|---|
| I10 | Ipertensione essenziale |
| E11 | Diabete mellito di tipo 2 |
| J06.9 | Infezione acuta alte vie respiratorie, non specificata |
| M54.5 | Lombalgia |
| K21.0 | Malattia da reflusso gastroesofageo con esofagite |
| N39.0 | Infezione delle vie urinarie, sede non specificata |
| F41.9 | Disturbo d'ansia, non specificato |
| L20.9 | Dermatite atopica, non specificata |
| H52.4 | Presbiopia |
| R51 | Cefalea |
| J45.9 | Asma, non specificato |
| M25.5 | Dolore articolare |
| H66.9 | Otite media, non specificata |
| K29.7 | Gastrite, non specificata |
| R10.4 | Dolore addominale, altro/non specificato |
| I48.9 | Fibrillazione/flutter atriale, non specificato |
| G43.9 | Emicrania, non specificata |
| L03.9 | Cellulite, non specificata |
| N30.0 | Cistite acuta |
| H52.1 | Miopia |
| M17.9 | Gonartrosi (artrosi del ginocchio), non specificata |
| Z00.0 | Visita medica generale senza riscontro di anomalie |
| Z23 | Vaccinazione |
| R05 | Tosse |
| R07.9 | Dolore toracico, non specificato |
| E78.5 | Iperlipidemia, non specificata |
| I25.1 | Cardiopatia ischemica aterosclerotica |
| F32.9 | Episodio depressivo, non specificato |
| K21.9 | Malattia da reflusso gastroesofageo senza esofagite |
| M79.1 | Mialgia |

## 6. `medications`

Prescrizioni farmacologiche (35% degli appuntamenti completati).

| Campo | Tipo | Descrizione |
|---|---|---|
| `med_id` | INT (PK) | Identificativo prescrizione |
| `appointment_id` | INT (FK → appointments) | Appuntamento di riferimento |
| `patient_id` | INT (FK → patients) | Paziente |
| `atc_code` | VARCHAR(10) | Codice ATC (vedi legenda sotto) |
| `dose_info` | VARCHAR(100) | Sempre `standard` nel dataset attuale (placeholder, non granulare) |
| `duration_days` | INT | Durata terapia: 5, 7, 14 o 30 giorni |
| `prescribed_date` | DATE | Data prescrizione (= data diagnosi) |

### Legenda codici ATC utilizzati (livello sottogruppo terapeutico)

| Codice | Descrizione |
|---|---|
| A02 | Farmaci per disturbi correlati all'acidità |
| A10 | Farmaci per il diabete |
| C09 | Agenti attivi sul sistema renina-angiotensina |
| N02 | Analgesici |
| J01 | Antibatterici per uso sistemico |
| R03 | Farmaci per malattie ostruttive delle vie respiratorie |
| M01 | Antinfiammatori e antireumatici |
| N05 | Psicolettici |
| A03 | Farmaci per disturbi gastrointestinali funzionali |
| B01 | Antitrombotici |
| C07 | Beta-bloccanti |
| G03 | Ormoni sessuali e modulatori dell'apparato genitale |
| S01 | Oftalmologici |
| D07 | Corticosteroidi dermatologici |
| H02 | Corticosteroidi sistemici |
| R01 | Preparati nasali |
| J05 | Antivirali per uso sistemico |

## 7. `lab_results`

Esami di laboratorio (25% degli appuntamenti completati).

| Campo | Tipo | Descrizione |
|---|---|---|
| `lab_id` | INT (PK) | Identificativo esame |
| `appointment_id` | INT (FK → appointments) | Appuntamento di riferimento |
| `patient_id` | INT (FK → patients) | Paziente |
| `test_name` | VARCHAR(100) | `HbA1c`, `Glucose`, `Creatinine`, `TotalCholesterol`, `TSH`, `Hemoglobin` |
| `result_value` | DECIMAL(10,2) | Valore risultato (distribuzione realistica, più alta per pazienti diabetici su HbA1c/Glucose) |
| `unit` | VARCHAR(20) | Unità di misura |
| `ref_min` / `ref_max` | DECIMAL(10,2) | Range di riferimento clinico standard |
| `sample_datetime` | DATETIME | Data/ora prelievo (= data/ora appuntamento) |

## 8. `billing`

Fatturazione.

| Campo | Tipo | Descrizione |
|---|---|---|
| `invoice_id` | INT (PK) | Identificativo fattura |
| `appointment_id` | INT (FK → appointments) | Appuntamento di riferimento |
| `patient_id` | INT (FK → patients) | Paziente |
| `total_amount_eur` | DECIMAL(10,2) | Importo (= `appointments.price_eur`) |
| `paid_flag` | BOOLEAN | 1 = pagata, 0 = non pagata (90% pagate) |
| `payment_method` | VARCHAR(50) | `card` (60%) / `cash` (20%) / `insurance_billing` (20%) |
| `invoice_date` | DATE | Data fattura (= data appuntamento) |

## 9. `feedback`

Feedback pazienti post-visita (18% degli appuntamenti completati).

| Campo | Tipo | Descrizione |
|---|---|---|
| `feedback_id` | INT (PK) | Identificativo feedback |
| `appointment_id` | INT (FK → appointments) | Appuntamento di riferimento |
| `patient_id` | INT (FK → patients) | Paziente |
| `rating` | INT | Voto 1–5 (distribuzione centrata su 4,2) |
| `submitted_date` | DATE | Data invio feedback |

---

## Note di data quality

Le seguenti verifiche sono eseguite in `sql/02_data_quality_validation.sql`:
- Conteggio righe per tutte le 9 tabelle
- Integrità referenziale: appuntamenti orfani rispetto a `patients`, `providers`, `clinics` (atteso: 0)
- Controllo prezzi negativi in `appointments` (atteso: 0)
- Distribuzione status appuntamenti, durata (min/max/media), `paid_flag`, `reminder_sent`

## Nota metodologica generale

Tutti i dati sono sintetici e non rappresentano persone reali. I codici ICD-10 e ATC sono standard reali, utilizzati per dare realismo strutturale al dataset, ma le osservazioni restano simulazioni — non riflettono percorsi clinici o epidemiologici reali. I CAP sono generati casualmente e non corrispondono ai prefissi reali delle province del Lazio.
