-- Agregar campo explanation a la tabla questions
ALTER TABLE questions ADD COLUMN explanation TEXT;

-- Agregar comentario para documentar el campo
COMMENT ON COLUMN questions.explanation IS 'Explicación de por qué esta respuesta es correcta, mostrada en los resultados del quiz';

-- Opcional: Agregar un índice para búsquedas
CREATE INDEX IF NOT EXISTS idx_questions_explanation ON questions (explanation)
WHERE
    explanation IS NOT NULL;