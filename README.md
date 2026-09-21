# Luxembourg Financial Sector Employment Analysis

A data analytics portfolio project: how has employment in Luxembourg's financial
sector evolved since 1999, and how does it compare to the national economy? Built
end-to-end with SQL and Power BI, on real STATEC open data - not a tutorial dataset.

![Overview page](<Power BI/screenshots/page1_overview.png>)


## Key Findings

- Financial-sector headcount grew **+113% since 1999**, reaching **51K in 2025**.
- **Financial sector professionals (PSF)** is the standout consistent grower;
  **Credit institutions** still holds the majority share (61.3%) but that share has
  been shrinking for years.
- But its *share* of national employment tells a different story: it peaked at
  **13.3% in 2008**, then declined to **10.4% by 2025** - the sector kept growing,
  the rest of the economy simply grew faster.
- The sector has become steadily more qualification-heavy: **80.6%** of the
  workforce is now tertiary-educated, and **32.2%** are foreign residents.
- The sharpest single-year swings cluster around **2008-2009**, matching
  Luxembourg's documented banking-sector job losses during the financial crisis.

---

## Main Question

How has employment in Luxembourg's financial sector changed over time, and what
trends can be observed across its different segments?

**Key questions answered:**
1. How has total financial-sector headcount changed over the years?
2. How is headcount split across the four segments, and has that mix shifted?
3. Which segment is growing fastest, and which is flat or shrinking?
4. Does financial-sector growth track differently from national employment?
5. Are there demographic signals worth flagging (education, nationality)?
6. Are there visible inflection points worth calling out?

---

## Data Source

STATEC (Luxembourg's national statistics office), via
[data.public.lu](https://data.public.lu), dataset *Population et emploi - Marché du
travail - Emploi*. License: **CC0** (public domain).

| File | Contains |
|---|---|
| Financial sector employment by segment | Headcount: Credit institutions, PSF, Management companies, Investment fund managers |
| Total payroll employment by activity | National employment (comparison baseline) |
| Employment % by activity and education level | Education mix within the financial sector |
| Employment % by activity and nationality | Luxembourgish vs. foreign residents |

Coverage: 1999-2025 (annual); 2010/2014/2018/2022 (education & nationality, published every 4 years).

---

## How It Was Built

1. **Explore** - segments, categories, year coverage, basic stats.
2. **Clean** - SQL Server (T-SQL) views: typed tables, missing-value handling,
   filtering out unrelated metrics mixed into the source files (see note below).
3. **Analyze** - `GROUP BY`, window functions (`SUM() OVER`, `LAG()`), a join
   against the national employment table.
4. **Visualize** - Power BI, connected directly to SQL views, 4 report pages.

**Tools:** SQL Server / SSMS (T-SQL) · Power BI Desktop (DAX for KPI cards)

---

## Dashboard Walkthrough

### Page 1 - Overview
![Overview page](<Power BI/screenshots/page1_overview.png>)
Total headcount trend and the sector's share of national employment side by side -
together they show growth that outpaced, then underperformed, the national economy
after the 2008 crisis.

### Page 2 - Segment Breakdown
![Segment breakdown page](<Power BI/screenshots/page2_segment_breakdown.png>)
Composition, range, share-over-time, and year-over-year growth by segment.
The ~400% growth spike is a base-effect artifact (a very small starting headcount),
not a real hiring event - see Data Notes.

### Page 3 - Finance vs. National + Demographics
![Finance vs national and demographics page](<Power BI/screenshots/page3_finance_vs_national.png>)
Dual-axis comparison against national employment, plus education-level and
nationality mix within the sector over time.

### Page 4 - Data Notes
![Data notes page](<Power BI/screenshots/page4_data_notes.png>)
Largest year-over-year swings (table + scatter), filtered to changes of at least
±1%. The biggest drops cluster around 2008-2009.

---

## Notable Detail: Why 2008

This matches documented history, not just a pattern in the data. Luxembourg's
banking sector lost roughly 770 jobs between September 2008 and September 2009
(ABBL/BCL reporting), with the regulator (CSSF) counting 26,497 banking jobs by
September 2009 - remarkably close to this dataset's own 26,416 for that year.

## Notable Detail: A Caught and Corrected Data Bug

An early KPI card showed an impossible 103.10%. Investigation traced it to STATEC's
education/nationality files each bundling **two different metrics** under the same
category codes, distinguished only by a `UNIT_MEASURE` field - the composition of
the finance sector itself (`PC_EMP_NACE`) vs. a different measure entirely
(`PC_EMP_EDUC_LEVEL`/`PC_EMP_RESID`). Fixed by filtering to `PC_EMP_NACE` in the
cleaning step. Verified: the card dropped to a sensible 80.60%.

## Known Data Limitations

- Some segment/year/category combinations have no recorded value - expected
  (newer regulatory categories, nationality breakdown not tracked everywhere),
  not a cleaning error.
- Management companies data ends 2018; Investment fund managers begins 2019 with
  no overlap - a possible STATEC reclassification, not explicitly confirmed in the
  source's footnotes, so treated here as two distinct segments.
- Education/nationality figures: only 2010, 2014, 2018, 2022 (published every 4
  years); every other chart uses annual data through 2025.

---

## Repository Structure

```
luxembourg-financial-sector-employment/
├── README.md
├── LICENSE
├── sql/
│   ├── financial_sector_employment_LU.sql             # exploration, cleaning, analysis
│   └── financial_sector_employment_views_powerbi.sql  # views feeding Power BI
├── powerbi/
│   └── luxembourg_financial_sector_employment.pbix
└── screenshots/
    ├── page1_overview.png
    ├── page2_segment_breakdown.png
    ├── page3_finance_vs_national.png
    └── page4_data_notes.png
```

---

**Data:** STATEC / LUSTAT via data.public.lu, CC0
**Code:** MIT License (see [LICENSE](LICENSE))
