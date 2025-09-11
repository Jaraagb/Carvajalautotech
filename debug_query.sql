-- Query para entender la estructura de las tablas y datos

-- 1. Verificar estructura de la tabla student_answers_detailed
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE
    table_name = 'student_answers_detailed'
ORDER BY ordinal_position;

-- 2. Verificar estructura de la tabla questions
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE
    table_name = 'questions'
ORDER BY ordinal_position;

-- 3. Ver algunos datos de ejemplo de student_answers_detailed
SELECT * FROM student_answers_detailed LIMIT 5;

-- 4. Ver algunos datos de ejemplo de questions
SELECT
    id,
    question,
    options,
    correct_answer,
    explanation,
    category_id
FROM questions
LIMIT 5;

-- 5. Verificar si existe alguna relación entre las tablas
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
WHERE
    tc.constraint_type = 'FOREIGN KEY'
    AND (
        tc.table_name = 'student_answers_detailed'
        OR tc.table_name = 'questions'
    );

-- 6. Query para obtener preguntas con respuestas de un estudiante específico
-- (Esta sería la query que necesitamos en el código)
SELECT
    q.id as question_id,
    q.question,
    q.options,
    q.correct_answer,
    q.explanation,
    q.category_id,
    sa.answer as student_answer,
    sa.is_correct,
    sa.time_spent,
    sa.student_id
FROM
    questions q
    LEFT JOIN student_answers_detailed sa ON q.id = sa.question_id
WHERE
    q.category_id = 'YOUR_CATEGORY_ID_HERE'
    AND sa.student_id = 'YOUR_STUDENT_ID_HERE'
ORDER BY q.id;

-- 7. Verificar si hay datos en las tablas
SELECT 'student_answers_detailed' as table_name, COUNT(*) as record_count
FROM student_answers_detailed
UNION ALL
SELECT 'questions' as table_name, COUNT(*) as record_count
FROM questions;

-- 8. Buscar tablas que contengan respuestas individuales por pregunta
SELECT table_name
FROM information_schema.tables
WHERE
    table_schema = 'public'
    AND (
        table_name LIKE '%answer%'
        OR table_name LIKE '%student%'
    )
ORDER BY table_name;

-- 9. Verificar estructura de student_answers (tabla base)
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE
    table_name = 'student_answers'
ORDER BY ordinal_position;

-- 10. Query correcta para obtener preguntas con respuestas (usar esta en el código)
SELECT
    q.id as question_id,
    q.question,
    q.options,
    q.correct_answer,
    q.explanation,
    q.category_id,
    sa.answer as student_answer,
    sa.is_correct,
    sa.time_spent,
    sa.student_id
FROM
    questions q
    LEFT JOIN student_answers sa ON q.id = sa.question_id
WHERE
    q.category_id = 'a449091e-2916-4355-9f3f-77257f598293'
    AND sa.student_id = 'c3af29f7-5b6a-4d10-a7f2-cee32b24092e'
ORDER BY q.id;