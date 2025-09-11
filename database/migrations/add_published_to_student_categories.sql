-- Agregar campo published a la tabla student_categories
ALTER TABLE student_categories
ADD COLUMN published BOOLEAN DEFAULT FALSE;

-- Crear índice para mejorar las consultas de publicación
CREATE INDEX IF NOT EXISTS idx_student_categories_published ON student_categories (student_id, published);

-- Comentario para documentar el cambio
COMMENT ON COLUMN student_categories.published IS 'Indica si las respuestas de esta categoría están publicadas para el estudiante';