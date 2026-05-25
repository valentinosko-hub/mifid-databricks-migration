-- Module: ReplaceChar UDF and static special-character dictionary validation
-- SQL Server behavior requirements:
-- - trim BEFORE replacement
-- - do NOT trim after replacement
-- - replace š, Š, ß, É, é
-- - replace hyphen/underscore with spaces
-- - remove listed punctuation/symbol characters and digits 0-9
-- - avoid incorrect chr() mappings for š / Š / ƒ

CREATE OR REPLACE FUNCTION main.regtech_ops_stg.bi_output_regtechops_fn_replacechar(input_value STRING)
RETURNS STRING
RETURN
CASE
  WHEN input_value IS NULL THEN NULL
  ELSE
    regexp_replace(
      regexp_replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(trim(input_value), 'š', 's'),
                    'Š', 'S'
                  ),
                  'ß', 's'
                ),
                'É', 'E'
              ),
              'é', 'e'
            ),
            '-', ' '
          ),
          '_', ' '
        ),
        '[\\|\\\\/~\\{\\};:\",\\.\\[\\]!@#\\$%\\^&\\*\\(\\)\\+=`´\\?0-9]',
        ''
      ),
      '[¶ƒ²©¸\\u00A0\\u0081\\u008F\\u00AD]',
      ''
    )
END;

