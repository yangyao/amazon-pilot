-- Migration: Fix competitor_analysis_results.analysis_data constraint
-- Purpose: Allow NULL values for analysis_data during initial record creation
-- Date: 2025-09-14

-- Remove NOT NULL constraint from analysis_data field
-- This allows creating analysis records before LLM processing completes
ALTER TABLE competitor_analysis_results
    ALTER COLUMN analysis_data DROP NOT NULL;

-- Update table comment to reflect the corrected constraint
COMMENT ON COLUMN competitor_analysis_results.analysis_data IS 'Raw comparison data (NULL until LLM analysis completes)';

-- Update status workflow comment
COMMENT ON COLUMN competitor_analysis_results.status IS 'Workflow: pending -> processing -> completed/failed';

-- Add comment about the data lifecycle
COMMENT ON TABLE competitor_analysis_results IS 'LLM-generated competitor analysis reports. analysis_data is NULL initially, filled when OpenAI processing completes.';