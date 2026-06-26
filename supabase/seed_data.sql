-- ============================================================================
-- AgriSmartAI :: Seed Data
-- ----------------------------------------------------------------------------
-- Populates the disease knowledge base (OBJECTIVE 3: fertilizer + DA referral)
-- and a few demo scans/stats for the New Bataan pilot (OBJECTIVE 1 & 4).
-- Run AFTER schema.sql and rls_policies.sql.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- DISEASE KNOWLEDGE BASE  (the 3 target diseases + healthy)
-- ----------------------------------------------------------------------------
insert into public.diseases
  (code, name, scientific_name, description, symptoms, causes, treatment, fertilizer, prevention, da_directive, severity_label)
values
  (
    'bacterial_leaf_blight',
    'Bacterial Leaf Blight',
    'Xanthomonas oryzae pv. oryzae',
    'A serious bacterial disease causing wilting of seedlings and yellowing/drying of leaves.',
    'Water-soaked yellowish stripes on leaf blades, leaf tips turn grayish and dry, "kresek" wilting in seedlings.',
    'Bacteria spread through irrigation water, rain, and wounded leaves; worsened by high nitrogen and flooding.',
    'Use balanced fertilizer, drain fields, remove infected stubble, apply copper-based bactericide where allowed.',
    'Avoid excess nitrogen. Apply 90-60-60 NPK kg/ha and split nitrogen into 3 doses. Add potassium (MOP) to strengthen leaves.',
    'Plant resistant varieties, use certified seeds, avoid clipping leaf tips during transplanting, ensure proper field drainage.',
    'Report outbreak to the Municipal Agriculture Office of New Bataan. Request DA technician inspection and certified resistant seed assistance under the Rice Program.',
    'High'
  ),
  (
    'rice_blast',
    'Rice Blast',
    'Magnaporthe oryzae',
    'A destructive fungal disease affecting leaves, nodes, and panicles at all growth stages.',
    'Diamond/spindle-shaped lesions with gray centers and brown margins on leaves; neck rot on panicles.',
    'Fungus favored by high humidity, cool nights, excessive nitrogen, and dense planting.',
    'Apply recommended fungicide (tricyclazole) at early lesion stage, reduce nitrogen, improve air circulation.',
    'Reduce nitrogen to 80-60-60 NPK kg/ha. Apply silicon-rich fertilizer to harden leaf tissue and increase blast resistance.',
    'Use blast-resistant varieties, avoid over-fertilizing with nitrogen, maintain proper spacing, treat seeds before planting.',
    'Coordinate with DA-New Bataan for fungicide subsidy and blast-resistant seed (e.g., NSIC Rc lines) under the National Rice Program.',
    'High'
  ),
  (
    'tungro',
    'Rice Tungro',
    'Rice tungro bacilliform & spherical virus',
    'A viral disease transmitted by green leafhoppers, stunting plants and reducing yield drastically.',
    'Yellow to orange-yellow discoloration of leaves, stunted growth, reduced tillering, partially filled grains.',
    'Spread by green leafhoppers (Nephotettix spp.) feeding on infected then healthy plants.',
    'Control leafhopper vectors with recommended insecticide, remove and destroy infected plants immediately.',
    'Maintain balanced fertilization 90-60-60 NPK kg/ha; avoid excessive nitrogen which attracts leafhoppers.',
    'Plant tungro-resistant varieties, synchronize planting community-wide, monitor leafhopper populations, rogue infected hills early.',
    'Notify DA-New Bataan immediately for vector surveillance, synchronous planting coordination, and resistant variety distribution.',
    'Severe'
  ),
  (
    'healthy',
    'Healthy Rice Leaf',
    'Oryza sativa',
    'No disease detected. The rice leaf appears healthy.',
    'Uniform green color, no lesions, spots, or discoloration.',
    'N/A',
    'Continue good agricultural practices and regular monitoring.',
    'Maintain balanced NPK fertilization based on soil test; typically 90-60-60 kg/ha for irrigated lowland rice.',
    'Continue field sanitation, proper water management, and weekly crop monitoring.',
    'No referral needed. Continue routine monitoring and consult DA-New Bataan for seasonal crop advisories.',
    'None'
  )
on conflict (code) do update set
  name            = excluded.name,
  scientific_name = excluded.scientific_name,
  description     = excluded.description,
  symptoms        = excluded.symptoms,
  causes          = excluded.causes,
  treatment       = excluded.treatment,
  fertilizer      = excluded.fertilizer,
  prevention      = excluded.prevention,
  da_directive    = excluded.da_directive,
  severity_label  = excluded.severity_label;

-- ----------------------------------------------------------------------------
-- DEMO NOTE
-- ----------------------------------------------------------------------------
-- Demo farmer profiles & scans are created automatically once real users sign
-- up (handle_new_user trigger). For a fully offline demo you can insert sample
-- rows below AFTER creating the matching auth.users via the Supabase dashboard,
-- replacing <FARMER_UUID> with a real profile id:
--
-- insert into public.scans (user_id, disease_code, disease_name, confidence, barangay, latitude, longitude)
-- values
--   ('<FARMER_UUID>', 'rice_blast',            'Rice Blast',            91.40, 'Cabinuangan', 7.5500, 126.2400),
--   ('<FARMER_UUID>', 'bacterial_leaf_blight', 'Bacterial Leaf Blight', 88.20, 'Andap',        7.5610, 126.2510),
--   ('<FARMER_UUID>', 'tungro',                'Rice Tungro',           86.70, 'Magsaysay',     7.5720, 126.2620);
