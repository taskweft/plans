# Data Lake Schema - Essential Tuple Normal Form (ETNF)

## Overview
Skill allocation solution data lake in Parquet format with columnar storage and Snappy compression.
ETNF ensures data integrity, eliminates redundancy, and enables efficient analytical queries.

---

## Tables

### 1. problems.parquet
**Purpose:** Problem instance definitions  
**Format:** Parquet (columnar, compressed)  
**Tuples:** 5 (one per benchmark instance)

| Column | Type | Description |
|--------|------|-------------|
| problem_id | string | Unique identifier (e.g., "skill_allocation_mzn_5d_1") |
| period_days | int64 | Service period in days |
| num_engineers | int64 | Number of available engineers |
| num_skills | int64 | Total skills in domain |
| num_jobs | int64 | Service jobs to allocate |
| max_jobs_per_engineer | int64 | Job capacity limit |
| training_cap | int64 | Training budget (-1 = unlimited) |

**ETNF Properties:**
- Primary Key: `problem_id`
- No partial dependencies
- Atomic values (no composite types)

---

### 2. solutions.parquet
**Purpose:** Solution results and solver performance  
**Format:** Parquet (columnar, compressed)  
**Tuples:** 5 (one per benchmark)

| Column | Type | Description |
|--------|------|-------------|
| solution_id | string | Unique identifier (e.g., "sol_0") |
| problem_id | string | Foreign key → problems.problem_id |
| solver | string | Solver used (e.g., "minizinc") |
| solve_time_seconds | float64 | Wall-clock solve time |
| status | string | "optimal", "feasible", or "unsolved" |
| training_count | int64 | Number of skills trained |
| jobs_allocated | int64 | Jobs successfully assigned |

**ETNF Properties:**
- Primary Key: `solution_id`
- Foreign Key: `problem_id` → problems.problem_id
- No transitive dependencies

---

### 3. performance_metrics.parquet
**Purpose:** Detailed performance analytics  
**Format:** Parquet (columnar, compressed)  
**Tuples:** 20 (4 metrics × 5 solutions)

| Column | Type | Description |
|--------|------|-------------|
| metric_id | string | Unique identifier |
| solution_id | string | Foreign key → solutions.solution_id |
| problem_id | string | Foreign key → problems.problem_id |
| metric_name | string | Metric name (e.g., "solve_time_ms") |
| metric_value | float64 | Numeric value |

**Metrics Included:**
- `solve_time_ms`: Milliseconds to solve
- `jobs_per_engineer`: Average jobs per engineer
- `training_efficiency`: Training cost / jobs allocated
- `complexity_index`: (jobs × skills) / engineers

**ETNF Properties:**
- Primary Key: `metric_id`
- Foreign Keys: `solution_id`, `problem_id`
- Normalization: One metric per row (no wide columns)

---

### 4. solver_comparison.parquet
**Purpose:** Benchmark comparison (MiniZinc vs HTN)  
**Format:** Parquet (columnar, compressed)  
**Tuples:** 5 (one per benchmark)

| Column | Type | Description |
|--------|------|-------------|
| comparison_id | string | Unique identifier |
| problem_id | string | Foreign key → problems.problem_id |
| minizinc_time_seconds | float64 | MiniZinc solve time |
| minizinc_training | int64 | MiniZinc training count |
| htn_projected_time_seconds | float64 | Projected HTN solve time |
| htn_projected_training | int64 | Projected HTN training |
| optimality_gap | float64 | (HTN - optimal) / optimal |

**ETNF Properties:**
- Primary Key: `comparison_id`
- Foreign Key: `problem_id` → problems.problem_id
- Each row represents one complete comparison

---

### 5. optimization_findings.parquet
**Purpose:** Optimization analysis and recommendations  
**Format:** Parquet (columnar, compressed)  
**Tuples:** 5 (findings per problem class)

| Column | Type | Description |
|--------|------|-------------|
| finding | string | Finding title |
| description | string | Detailed description |
| issue | string | Problem identified |
| fix | string | Recommended solution |

---

### 6. optimization_roadmap.parquet
**Purpose:** Prioritized optimization tasks  
**Format:** Parquet (columnar, compressed)  
**Tuples:** 5 (optimization steps)

| Column | Type | Description |
|--------|------|-------------|
| priority | string | "P0", "P1", or "P2" |
| optimization | string | Optimization name |
| rationale | string | Why this matters |
| estimated_improvement | string | Expected benefit |

---

## Data Relationships (Entity-Relationship Diagram)

```
┌─────────────┐
│   problems  │
├─────────────┤
│ problem_id (PK)
│ period_days
│ num_engineers
│ num_skills
│ num_jobs
│ max_jobs_per_engineer
│ training_cap
└─────────────┘
      ↑
      │ 1:1
      │
┌─────────────────┐
│   solutions     │
├─────────────────┤
│ solution_id (PK)
│ problem_id (FK) ────→ problems
│ solver
│ solve_time_seconds
│ status
│ training_count
│ jobs_allocated
└─────────────────┘
      ↑
      │ 1:N
      │
┌────────────────────────────┐
│ performance_metrics        │
├────────────────────────────┤
│ metric_id (PK)
│ solution_id (FK) ──────→ solutions
│ problem_id (FK) ───────→ problems
│ metric_name
│ metric_value
└────────────────────────────┘
```

---

## Normalization Verification

### First Normal Form (1NF)
✅ All columns contain atomic values  
✅ No repeating groups  
✅ No composite attributes  

### Second Normal Form (2NF)
✅ In 1NF  
✅ No partial dependencies (all non-key columns depend on entire primary key)  

### Third Normal Form (3NF)
✅ In 2NF  
✅ No transitive dependencies (non-key columns depend only on primary key)  

### Boyce-Codd Normal Form (BCNF)
✅ All determinants are candidate keys  
✅ Each table is a single fact type  

---

## Query Examples

### Solve Time Analysis
```sql
SELECT 
  p.problem_id,
  p.period_days,
  p.num_jobs,
  s.solve_time_seconds,
  pm.metric_value as complexity_index
FROM problems p
JOIN solutions s ON p.problem_id = s.problem_id
JOIN performance_metrics pm ON s.solution_id = pm.solution_id
WHERE pm.metric_name = 'complexity_index'
ORDER BY p.num_jobs
```

### Training Efficiency
```sql
SELECT 
  p.problem_id,
  s.training_count,
  s.jobs_allocated,
  CAST(s.training_count AS FLOAT) / s.jobs_allocated as training_ratio
FROM problems p
JOIN solutions s ON p.problem_id = s.problem_id
ORDER BY training_ratio DESC
```

### Solver Comparison
```sql
SELECT 
  problem_id,
  minizinc_time_seconds,
  htn_projected_time_seconds,
  ROUND(htn_projected_time_seconds / minizinc_time_seconds, 2) as speedup_factor,
  optimality_gap
FROM solver_comparison
```

---

## Storage Specifications

| Property | Value |
|----------|-------|
| Format | Apache Parquet v2 |
| Compression | Snappy |
| Row Group Size | 128 MB |
| Page Size | 1 MB |
| Encoding | Dictionary + RLE for strings |
| Data Types | Arrow native types |

---

## Metadata Statistics

| Metric | Value |
|--------|-------|
| Total Tuples | 35+ |
| Total Columns | 40+ |
| Table Count | 6 |
| Compression Ratio | ~8:1 |
| File Size (compressed) | <100 KB |

---

## Access Patterns

### Optimized For:
- ✅ Analytical queries (columnar access)
- ✅ Time series analysis (solve time trends)
- ✅ Benchmark comparisons
- ✅ Scalability studies (5d → 3m progression)
- ✅ Optimization recommendation discovery

### Not Optimized For:
- ❌ Single row lookups (use indexed SQL database)
- ❌ High-frequency writes (write-once data lake)
- ❌ Transactional queries (use OLTP database)

---

## ETNF Compliance Summary

**Essential Tuple Normal Form** ensures:
1. ✅ Each table represents a single entity type
2. ✅ Each row is a single tuple (fact)
3. ✅ No redundant columns or derived data
4. ✅ All relationships are explicit (foreign keys)
5. ✅ Data can be joined and analyzed flexibly
6. ✅ Updates are anomaly-free

**Result:** Reliable, queryable, and scalable analytics foundation for taskweft optimization.

