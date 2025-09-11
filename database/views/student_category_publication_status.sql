-- Vista para mostrar el estado de publicación de categorías por estudiante
CREATE OR REPLACE VIEW student_category_publication_status AS
SELECT 
    sc.student_id,
    sc.category_id,
    sc.published,
    c.created_at as assigned_at,
    s.full_name as student_name,
    s.email as student_email,
    c.name as category_name,
    c.description as category_description,
    -- Contar total de respuestas en esta categoría para este estudiante
    COALESCE(answer_stats.total_answers, 0) as total_answers,
    -- Contar respuestas correctas
    COALESCE(answer_stats.correct_answers, 0) as correct_answers,
    -- Calcular porcentaje si hay respuestas
    CASE 
        WHEN COALESCE(answer_stats.total_answers, 0) > 0 
        THEN ROUND((COALESCE(answer_stats.correct_answers, 0)::DECIMAL / answer_stats.total_answers) * 100, 2)
        ELSE 0 
    END as success_percentage
FROM 
    student_categories sc
    INNER JOIN app_users_enriched s ON sc.student_id = s.id
    INNER JOIN categories c ON sc.category_id = c.id
    LEFT JOIN (
        SELECT 
            student_id,
            category_id,
            COUNT(*) as total_answers,
            SUM(CASE WHEN is_correct = true THEN 1 ELSE 0 END) as correct_answers
        FROM student_answers_detailed
        GROUP BY student_id, category_id
    ) answer_stats ON sc.student_id = answer_stats.student_id 
                  AND sc.category_id = answer_stats.category_id
ORDER BY 
    s.full_name, c.name;