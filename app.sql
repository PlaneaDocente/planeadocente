
-- ============================================================
-- PLANEA DOCENTE - DDL COMPLETO
-- Sistema de Gestión Educativa para México
-- ============================================================

-- ============================================================
-- FASE 1: FUNDACIÓN - ENUMs y Funciones Base
-- ============================================================

-- Función estándar para timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ENUMs del sistema
CREATE TYPE rol_usuario AS ENUM ('admin', 'director', 'maestro', 'padre');
CREATE TYPE tipo_planeacion AS ENUM ('semanal', 'proyecto', 'automatica');
CREATE TYPE estado_asistencia AS ENUM ('presente', 'ausente', 'justificado', 'retardo');
CREATE TYPE tipo_evidencia AS ENUM ('foto', 'documento', 'video');
CREATE TYPE tipo_actividad AS ENUM ('tarea', 'proyecto', 'clase');
CREATE TYPE tipo_comunicado AS ENUM ('aviso', 'tarea', 'mensaje');
CREATE TYPE nivel_educativo AS ENUM ('preescolar', 'primaria', 'secundaria', 'preparatoria');
CREATE TYPE estado_general AS ENUM ('activo', 'inactivo', 'archivado');

-- ============================================================
-- FASE 2: DDL - TABLAS
-- ============================================================

-- ------------------------------------------------------------
-- MÓDULO: USUARIOS Y PERFILES
-- ------------------------------------------------------------

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    telefono VARCHAR(20),
    rol rol_usuario NOT NULL DEFAULT 'maestro',
    escuela_id UUID,
    estado estado_general DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role rol_usuario NOT NULL DEFAULT 'maestro',
    escuela_id UUID,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, role)
);

CREATE INDEX idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX idx_user_roles_escuela_id ON public.user_roles(escuela_id);
CREATE INDEX idx_profiles_escuela_id ON public.profiles(escuela_id);

-- ------------------------------------------------------------
-- MÓDULO: GESTIÓN ESCOLAR
-- ------------------------------------------------------------

CREATE TABLE public.escuelas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    clave_centro_trabajo VARCHAR(20) UNIQUE,
    direccion TEXT,
    municipio VARCHAR(100),
    estado_republica VARCHAR(100),
    telefono VARCHAR(20),
    director_id UUID,
    nivel nivel_educativo DEFAULT 'primaria',
    logo_url TEXT,
    estado estado_general DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_escuelas_director_id ON public.escuelas(director_id);
CREATE INDEX idx_escuelas_clave ON public.escuelas(clave_centro_trabajo);

CREATE TABLE public.grupos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    grado VARCHAR(20) NOT NULL,
    turno VARCHAR(20) DEFAULT 'matutino',
    ciclo_escolar VARCHAR(20) NOT NULL,
    maestro_id UUID,
    escuela_id UUID NOT NULL,
    capacidad_maxima INTEGER DEFAULT 35,
    estado estado_general DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_grupos_escuela_id ON public.grupos(escuela_id);
CREATE INDEX idx_grupos_maestro_id ON public.grupos(maestro_id);
CREATE INDEX idx_grupos_ciclo ON public.grupos(ciclo_escolar);

CREATE TABLE public.materias (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    grado VARCHAR(20),
    nivel nivel_educativo DEFAULT 'primaria',
    campo_formativo VARCHAR(100),
    horas_semanales INTEGER DEFAULT 5,
    color_hex VARCHAR(7) DEFAULT '#4F46E5',
    escuela_id UUID,
    estado estado_general DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_materias_escuela_id ON public.materias(escuela_id);
CREATE INDEX idx_materias_nivel ON public.materias(nivel);

-- Tabla de relación grupos-materias-maestros
CREATE TABLE public.grupo_materia_maestro (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    grupo_id UUID NOT NULL,
    materia_id UUID NOT NULL,
    maestro_id UUID NOT NULL,
    ciclo_escolar VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(grupo_id, materia_id, ciclo_escolar)
);

CREATE INDEX idx_gmm_grupo_id ON public.grupo_materia_maestro(grupo_id);
CREATE INDEX idx_gmm_materia_id ON public.grupo_materia_maestro(materia_id);
CREATE INDEX idx_gmm_maestro_id ON public.grupo_materia_maestro(maestro_id);

-- ------------------------------------------------------------
-- MÓDULO: ALUMNOS
-- ------------------------------------------------------------

CREATE TABLE public.tutores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre_completo VARCHAR(200) NOT NULL,
    parentesco VARCHAR(50) DEFAULT 'padre/madre',
    telefono VARCHAR(20),
    telefono_emergencia VARCHAR(20),
    email TEXT,
    direccion TEXT,
    ocupacion VARCHAR(100),
    user_id UUID,
    estado estado_general DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_tutores_user_id ON public.tutores(user_id);
CREATE INDEX idx_tutores_email ON public.tutores(email);

CREATE TABLE public.alumnos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    curp VARCHAR(18) UNIQUE,
    fecha_nacimiento DATE,
    genero VARCHAR(20),
    foto_url TEXT,
    numero_lista INTEGER,
    grupo_id UUID,
    escuela_id UUID NOT NULL,
    tutor_id UUID,
    direccion TEXT,
    telefono_emergencia VARCHAR(20),
    condicion_medica TEXT,
    beca BOOLEAN DEFAULT false,
    estado estado_general DEFAULT 'activo',
    ciclo_escolar VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_alumnos_grupo_id ON public.alumnos(grupo_id);
CREATE INDEX idx_alumnos_escuela_id ON public.alumnos(escuela_id);
CREATE INDEX idx_alumnos_tutor_id ON public.alumnos(tutor_id);
CREATE INDEX idx_alumnos_curp ON public.alumnos(curp);
CREATE INDEX idx_alumnos_ciclo ON public.alumnos(ciclo_escolar);

CREATE TABLE public.observaciones_alumnos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    alumno_id UUID NOT NULL,
    maestro_id UUID NOT NULL,
    tipo VARCHAR(50) DEFAULT 'general',
    descripcion TEXT NOT NULL,
    fecha DATE DEFAULT CURRENT_DATE,
    es_conducta BOOLEAN DEFAULT false,
    es_aprendizaje BOOLEAN DEFAULT false,
    es_salud BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_observaciones_alumno_id ON public.observaciones_alumnos(alumno_id);
CREATE INDEX idx_observaciones_maestro_id ON public.observaciones_alumnos(maestro_id);
CREATE INDEX idx_observaciones_fecha ON public.observaciones_alumnos(fecha);

CREATE TABLE public.historial_academico (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    alumno_id UUID NOT NULL,
    ciclo_escolar VARCHAR(20) NOT NULL,
    grado VARCHAR(20),
    grupo_id UUID,
    promedio_final DECIMAL(4,2),
    resultado VARCHAR(50),
    observaciones TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_historial_alumno_id ON public.historial_academico(alumno_id);
CREATE INDEX idx_historial_ciclo ON public.historial_academico(ciclo_escolar);

-- ------------------------------------------------------------
-- MÓDULO: ASISTENCIA
-- ------------------------------------------------------------

CREATE TABLE public.asistencia (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    alumno_id UUID NOT NULL,
    grupo_id UUID NOT NULL,
    maestro_id UUID NOT NULL,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    estado estado_asistencia NOT NULL DEFAULT 'presente',
    hora_registro TIMESTAMPTZ DEFAULT now(),
    observacion TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(alumno_id, fecha)
);

CREATE INDEX idx_asistencia_alumno_id ON public.asistencia(alumno_id);
CREATE INDEX idx_asistencia_grupo_id ON public.asistencia(grupo_id);
CREATE INDEX idx_asistencia_maestro_id ON public.asistencia(maestro_id);
CREATE INDEX idx_asistencia_fecha ON public.asistencia(fecha);

CREATE TABLE public.justificaciones_asistencia (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    asistencia_id UUID NOT NULL,
    alumno_id UUID NOT NULL,
    motivo TEXT NOT NULL,
    documento_url TEXT,
    presentado_por VARCHAR(200),
    fecha_justificacion DATE DEFAULT CURRENT_DATE,
    aprobado_por UUID,
    estado VARCHAR(20) DEFAULT 'pendiente',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_justificaciones_asistencia_id ON public.justificaciones_asistencia(asistencia_id);
CREATE INDEX idx_justificaciones_alumno_id ON public.justificaciones_asistencia(alumno_id);

-- ------------------------------------------------------------
-- MÓDULO: PLANEACIÓN (NEM - Nueva Escuela Mexicana)
-- ------------------------------------------------------------

CREATE TABLE public.planeaciones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    tipo tipo_planeacion NOT NULL DEFAULT 'semanal',
    maestro_id UUID NOT NULL,
    grupo_id UUID,
    materia_id UUID,
    fecha_inicio DATE,
    fecha_fin DATE,
    semana_numero INTEGER,
    campo_formativo VARCHAR(100),
    eje_articulador VARCHAR(100),
    contenido_prioritario TEXT,
    proceso_desarrollo TEXT,
    aprendizajes_esperados TEXT,
    estrategias_didacticas TEXT,
    recursos_materiales TEXT,
    evaluacion_descripcion TEXT,
    generada_por_ia BOOLEAN DEFAULT false,
    prompt_ia TEXT,
    estado VARCHAR(20) DEFAULT 'borrador',
    ciclo_escolar VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_planeaciones_maestro_id ON public.planeaciones(maestro_id);
CREATE INDEX idx_planeaciones_grupo_id ON public.planeaciones(grupo_id);
CREATE INDEX idx_planeaciones_materia_id ON public.planeaciones(materia_id);
CREATE INDEX idx_planeaciones_fecha ON public.planeaciones(fecha_inicio, fecha_fin);
CREATE INDEX idx_planeaciones_tipo ON public.planeaciones(tipo);

CREATE TABLE public.biblioteca_actividades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    tipo tipo_actividad DEFAULT 'clase',
    nivel nivel_educativo DEFAULT 'primaria',
    grado VARCHAR(20),
    materia_nombre VARCHAR(100),
    campo_formativo VARCHAR(100),
    duracion_minutos INTEGER DEFAULT 50,
    recursos TEXT,
    instrucciones TEXT,
    generada_por_ia BOOLEAN DEFAULT false,
    publica BOOLEAN DEFAULT true,
    creada_por UUID,
    veces_usada INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_biblioteca_nivel ON public.biblioteca_actividades(nivel);
CREATE INDEX idx_biblioteca_tipo ON public.biblioteca_actividades(tipo);
CREATE INDEX idx_biblioteca_creada_por ON public.biblioteca_actividades(creada_por);

-- ------------------------------------------------------------
-- MÓDULO: ACTIVIDADES
-- ------------------------------------------------------------

CREATE TABLE public.actividades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    tipo tipo_actividad NOT NULL DEFAULT 'tarea',
    maestro_id UUID NOT NULL,
    grupo_id UUID NOT NULL,
    materia_id UUID,
    planeacion_id UUID,
    fecha_asignacion DATE DEFAULT CURRENT_DATE,
    fecha_entrega DATE,
    puntos_maximos DECIMAL(5,2) DEFAULT 10,
    instrucciones TEXT,
    recursos_url TEXT,
    permite_entrega_digital BOOLEAN DEFAULT true,
    estado VARCHAR(20) DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_actividades_maestro_id ON public.actividades(maestro_id);
CREATE INDEX idx_actividades_grupo_id ON public.actividades(grupo_id);
CREATE INDEX idx_actividades_materia_id ON public.actividades(materia_id);
CREATE INDEX idx_actividades_planeacion_id ON public.actividades(planeacion_id);
CREATE INDEX idx_actividades_fecha_entrega ON public.actividades(fecha_entrega);

CREATE TABLE public.entregas_actividades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    actividad_id UUID NOT NULL,
    alumno_id UUID NOT NULL,
    fecha_entrega TIMESTAMPTZ DEFAULT now(),
    archivo_url TEXT,
    comentario TEXT,
    calificacion DECIMAL(5,2),
    retroalimentacion TEXT,
    estado VARCHAR(20) DEFAULT 'entregado',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(actividad_id, alumno_id)
);

CREATE INDEX idx_entregas_actividad_id ON public.entregas_actividades(actividad_id);
CREATE INDEX idx_entregas_alumno_id ON public.entregas_actividades(alumno_id);

-- ------------------------------------------------------------
-- MÓDULO: EVALUACIONES
-- ------------------------------------------------------------

CREATE TABLE public.rubricas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    maestro_id UUID NOT NULL,
    materia_id UUID,
    grupo_id UUID,
    generada_por_ia BOOLEAN DEFAULT false,
    publica BOOLEAN DEFAULT false,
    estado estado_general DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_rubricas_maestro_id ON public.rubricas(maestro_id);
CREATE INDEX idx_rubricas_materia_id ON public.rubricas(materia_id);

CREATE TABLE public.criterios_rubrica (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    rubrica_id UUID NOT NULL,
    criterio VARCHAR(200) NOT NULL,
    descripcion_excelente TEXT,
    descripcion_bueno TEXT,
    descripcion_regular TEXT,
    descripcion_insuficiente TEXT,
    puntaje_excelente DECIMAL(4,2) DEFAULT 10,
    puntaje_bueno DECIMAL(4,2) DEFAULT 8,
    puntaje_regular DECIMAL(4,2) DEFAULT 6,
    puntaje_insuficiente DECIMAL(4,2) DEFAULT 4,
    peso_porcentaje DECIMAL(5,2) DEFAULT 25,
    orden INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_criterios_rubrica_id ON public.criterios_rubrica(rubrica_id);

CREATE TABLE public.listas_cotejo (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    maestro_id UUID NOT NULL,
    materia_id UUID,
    grupo_id UUID,
    generada_por_ia BOOLEAN DEFAULT false,
    estado estado_general DEFAULT 'activo',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_listas_cotejo_maestro_id ON public.listas_cotejo(maestro_id);

CREATE TABLE public.items_lista_cotejo (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lista_cotejo_id UUID NOT NULL,
    descripcion TEXT NOT NULL,
    orden INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_items_lista_id ON public.items_lista_cotejo(lista_cotejo_id);

CREATE TABLE public.examenes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    maestro_id UUID NOT NULL,
    grupo_id UUID,
    materia_id UUID,
    fecha_aplicacion DATE,
    duracion_minutos INTEGER DEFAULT 60,
    total_puntos DECIMAL(5,2) DEFAULT 100,
    instrucciones TEXT,
    generado_por_ia BOOLEAN DEFAULT false,
    estado VARCHAR(20) DEFAULT 'borrador',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_examenes_maestro_id ON public.examenes(maestro_id);
CREATE INDEX idx_examenes_grupo_id ON public.examenes(grupo_id);
CREATE INDEX idx_examenes_materia_id ON public.examenes(materia_id);

CREATE TABLE public.preguntas_examen (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    examen_id UUID NOT NULL,
    pregunta TEXT NOT NULL,
    tipo VARCHAR(50) DEFAULT 'opcion_multiple',
    opciones JSONB,
    respuesta_correcta TEXT,
    puntos DECIMAL(4,2) DEFAULT 10,
    orden INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_preguntas_examen_id ON public.preguntas_examen(examen_id);

CREATE TABLE public.calificaciones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    alumno_id UUID NOT NULL,
    maestro_id UUID NOT NULL,
    materia_id UUID NOT NULL,
    grupo_id UUID NOT NULL,
    periodo VARCHAR(50) NOT NULL,
    ciclo_escolar VARCHAR(20) NOT NULL,
    calificacion_parcial_1 DECIMAL(4,2),
    calificacion_parcial_2 DECIMAL(4,2),
    calificacion_parcial_3 DECIMAL(4,2),
    calificacion_final DECIMAL(4,2),
    observaciones TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(alumno_id, materia_id, periodo, ciclo_escolar)
);

CREATE INDEX idx_calificaciones_alumno_id ON public.calificaciones(alumno_id);
CREATE INDEX idx_calificaciones_maestro_id ON public.calificaciones(maestro_id);
CREATE INDEX idx_calificaciones_materia_id ON public.calificaciones(materia_id);
CREATE INDEX idx_calificaciones_grupo_id ON public.calificaciones(grupo_id);
CREATE INDEX idx_calificaciones_ciclo ON public.calificaciones(ciclo_escolar);

-- ------------------------------------------------------------
-- MÓDULO: EVIDENCIAS (Portafolio Digital)
-- ------------------------------------------------------------

CREATE TABLE public.evidencias (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    tipo tipo_evidencia NOT NULL DEFAULT 'foto',
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    alumno_id UUID,
    grupo_id UUID,
    maestro_id UUID NOT NULL,
    materia_id UUID,
    actividad_id UUID,
    planeacion_id UUID,
    fecha DATE DEFAULT CURRENT_DATE,
    es_portafolio BOOLEAN DEFAULT false,
    tamano_bytes BIGINT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_evidencias_alumno_id ON public.evidencias(alumno_id);
CREATE INDEX idx_evidencias_grupo_id ON public.evidencias(grupo_id);
CREATE INDEX idx_evidencias_maestro_id ON public.evidencias(maestro_id);
CREATE INDEX idx_evidencias_tipo ON public.evidencias(tipo);
CREATE INDEX idx_evidencias_portafolio ON public.evidencias(es_portafolio);

-- ------------------------------------------------------------
-- MÓDULO: COMUNICACIÓN
-- ------------------------------------------------------------

CREATE TABLE public.comunicados (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    contenido TEXT NOT NULL,
    tipo tipo_comunicado NOT NULL DEFAULT 'aviso',
    remitente_id UUID NOT NULL,
    grupo_id UUID,
    escuela_id UUID,
    para_todos BOOLEAN DEFAULT false,
    fecha_publicacion TIMESTAMPTZ DEFAULT now(),
    fecha_expiracion TIMESTAMPTZ,
    archivo_adjunto_url TEXT,
    estado VARCHAR(20) DEFAULT 'publicado',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_comunicados_remitente_id ON public.comunicados(remitente_id);
CREATE INDEX idx_comunicados_grupo_id ON public.comunicados(grupo_id);
CREATE INDEX idx_comunicados_tipo ON public.comunicados(tipo);
CREATE INDEX idx_comunicados_fecha ON public.comunicados(fecha_publicacion);

CREATE TABLE public.lecturas_comunicados (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    comunicado_id UUID NOT NULL,
    tutor_id UUID NOT NULL,
    leido_en TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(comunicado_id, tutor_id)
);

CREATE INDEX idx_lecturas_comunicado_id ON public.lecturas_comunicados(comunicado_id);
CREATE INDEX idx_lecturas_tutor_id ON public.lecturas_comunicados(tutor_id);

CREATE TABLE public.mensajes_padres (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    remitente_id UUID NOT NULL,
    destinatario_id UUID NOT NULL,
    alumno_id UUID,
    asunto VARCHAR(200),
    mensaje TEXT NOT NULL,
    leido BOOLEAN DEFAULT false,
    leido_en TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_mensajes_remitente_id ON public.mensajes_padres(remitente_id);
CREATE INDEX idx_mensajes_destinatario_id ON public.mensajes_padres(destinatario_id);
CREATE INDEX idx_mensajes_alumno_id ON public.mensajes_padres(alumno_id);

-- ------------------------------------------------------------
-- MÓDULO: CALENDARIO Y RECORDATORIOS
-- ------------------------------------------------------------

CREATE TABLE public.eventos_calendario (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    tipo VARCHAR(50) DEFAULT 'evento',
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ,
    todo_el_dia BOOLEAN DEFAULT false,
    color_hex VARCHAR(7) DEFAULT '#4F46E5',
    creado_por UUID NOT NULL,
    escuela_id UUID,
    grupo_id UUID,
    es_festivo BOOLEAN DEFAULT false,
    es_publico BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_eventos_creado_por ON public.eventos_calendario(creado_por);
CREATE INDEX idx_eventos_escuela_id ON public.eventos_calendario(escuela_id);
CREATE INDEX idx_eventos_fecha ON public.eventos_calendario(fecha_inicio);

CREATE TABLE public.recordatorios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    usuario_id UUID NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    fecha_recordatorio TIMESTAMPTZ NOT NULL,
    tipo VARCHAR(50) DEFAULT 'general',
    referencia_id UUID,
    referencia_tipo VARCHAR(50),
    enviado BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_recordatorios_usuario_id ON public.recordatorios(usuario_id);
CREATE INDEX idx_recordatorios_fecha ON public.recordatorios(fecha_recordatorio);

-- ------------------------------------------------------------
-- MÓDULO: CONFIGURACIÓN DEL SISTEMA
-- ------------------------------------------------------------

CREATE TABLE public.configuracion_sistema (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    escuela_id UUID NOT NULL UNIQUE,
    nombre_sistema VARCHAR(100) DEFAULT 'PlaneaDocente',
    ciclo_escolar_activo VARCHAR(20),
    periodos_evaluacion JSONB DEFAULT '["1er Bimestre","2do Bimestre","3er Bimestre","4to Bimestre","5to Bimestre"]',
    dias_habiles JSONB DEFAULT '["lunes","martes","miercoles","jueves","viernes"]',
    hora_entrada TIME DEFAULT '08:00',
    hora_salida TIME DEFAULT '14:00',
    minutos_tolerancia INTEGER DEFAULT 10,
    escala_calificacion_min DECIMAL(4,2) DEFAULT 0,
    escala_calificacion_max DECIMAL(4,2) DEFAULT 10,
    calificacion_aprobatoria DECIMAL(4,2) DEFAULT 6,
    logo_url TEXT,
    color_primario VARCHAR(7) DEFAULT '#4F46E5',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_config_escuela_id ON public.configuracion_sistema(escuela_id);

-- ============================================================
-- FASE 3: LÓGICA - FUNCIONES DEPENDIENTES DE TABLAS
-- ============================================================

-- Verificar rol del usuario actual
CREATE OR REPLACE FUNCTION public.has_role(_role rol_usuario)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role = _role
  );
$$;

-- Verificar si el usuario es maestro de un grupo específico
CREATE OR REPLACE FUNCTION public.is_maestro_del_grupo(_grupo_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.grupos
    WHERE id = _grupo_id
    AND maestro_id = auth.uid()
  );
$$;

-- Verificar si el usuario es tutor de un alumno
CREATE OR REPLACE FUNCTION public.is_tutor_del_alumno(_alumno_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.alumnos a
    JOIN public.tutores t ON t.id = a.tutor_id
    WHERE a.id = _alumno_id
    AND t.user_id = auth.uid()
  );
$$;

-- ============================================================
-- FASE 4: SEGURIDAD - RLS POLICIES
-- ============================================================

-- PROFILES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven su propio perfil" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins y directores ven todos los perfiles" ON public.profiles
    FOR SELECT USING (has_role('admin') OR has_role('director'));

CREATE POLICY "Usuarios actualizan su propio perfil" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins gestionan perfiles" ON public.profiles
    FOR ALL USING (has_role('admin'));

-- USER_ROLES
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins gestionan roles" ON public.user_roles
    FOR ALL USING (has_role('admin'));

CREATE POLICY "Usuarios ven sus propios roles" ON public.user_roles
    FOR SELECT USING (auth.uid() = user_id);

-- ESCUELAS
ALTER TABLE public.escuelas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos los autenticados ven escuelas" ON public.escuelas
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admins y directores gestionan escuelas" ON public.escuelas
    FOR ALL USING (has_role('admin') OR has_role('director'));

-- GRUPOS
ALTER TABLE public.grupos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros ven sus grupos" ON public.grupos
    FOR SELECT USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

CREATE POLICY "Admins y directores gestionan grupos" ON public.grupos
    FOR ALL USING (has_role('admin') OR has_role('director'));

CREATE POLICY "Maestros actualizan sus grupos" ON public.grupos
    FOR UPDATE USING (maestro_id = auth.uid());

-- MATERIAS
ALTER TABLE public.materias ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Autenticados ven materias" ON public.materias
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admins y directores gestionan materias" ON public.materias
    FOR ALL USING (has_role('admin') OR has_role('director'));

-- GRUPO_MATERIA_MAESTRO
ALTER TABLE public.grupo_materia_maestro ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros ven sus asignaciones" ON public.grupo_materia_maestro
    FOR SELECT USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

CREATE POLICY "Admins gestionan asignaciones" ON public.grupo_materia_maestro
    FOR ALL USING (has_role('admin') OR has_role('director'));

-- TUTORES
ALTER TABLE public.tutores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tutores ven su propio registro" ON public.tutores
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Maestros y admins ven tutores" ON public.tutores
    FOR SELECT USING (has_role('maestro') OR has_role('admin') OR has_role('director'));

CREATE POLICY "Admins gestionan tutores" ON public.tutores
    FOR ALL USING (has_role('admin') OR has_role('director'));

-- ALUMNOS
ALTER TABLE public.alumnos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros ven alumnos de sus grupos" ON public.alumnos
    FOR SELECT USING (
        has_role('admin') OR has_role('director') OR
        is_maestro_del_grupo(grupo_id) OR
        is_tutor_del_alumno(id)
    );

CREATE POLICY "Maestros registran alumnos" ON public.alumnos
    FOR INSERT WITH CHECK (has_role('maestro') OR has_role('admin') OR has_role('director'));

CREATE POLICY "Maestros actualizan alumnos de sus grupos" ON public.alumnos
    FOR UPDATE USING (is_maestro_del_grupo(grupo_id) OR has_role('admin') OR has_role('director'));

-- OBSERVACIONES_ALUMNOS
ALTER TABLE public.observaciones_alumnos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan sus observaciones" ON public.observaciones_alumnos
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

-- HISTORIAL_ACADEMICO
ALTER TABLE public.historial_academico ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Autenticados ven historial" ON public.historial_academico
    FOR SELECT USING (
        has_role('admin') OR has_role('director') OR has_role('maestro') OR
        is_tutor_del_alumno(alumno_id)
    );

CREATE POLICY "Maestros y admins gestionan historial" ON public.historial_academico
    FOR ALL USING (has_role('maestro') OR has_role('admin') OR has_role('director'));

-- ASISTENCIA
ALTER TABLE public.asistencia ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan asistencia de sus grupos" ON public.asistencia
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

CREATE POLICY "Tutores ven asistencia de sus hijos" ON public.asistencia
    FOR SELECT USING (is_tutor_del_alumno(alumno_id));

-- JUSTIFICACIONES_ASISTENCIA
ALTER TABLE public.justificaciones_asistencia ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros y admins gestionan justificaciones" ON public.justificaciones_asistencia
    FOR ALL USING (has_role('maestro') OR has_role('admin') OR has_role('director'));

CREATE POLICY "Tutores ven justificaciones de sus hijos" ON public.justificaciones_asistencia
    FOR SELECT USING (is_tutor_del_alumno(alumno_id));

-- PLANEACIONES
ALTER TABLE public.planeaciones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan sus planeaciones" ON public.planeaciones
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

-- BIBLIOTECA_ACTIVIDADES
ALTER TABLE public.biblioteca_actividades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos ven actividades públicas" ON public.biblioteca_actividades
    FOR SELECT USING (publica = true OR creada_por = auth.uid() OR has_role('admin'));

CREATE POLICY "Maestros crean actividades" ON public.biblioteca_actividades
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Creadores actualizan sus actividades" ON public.biblioteca_actividades
    FOR UPDATE USING (creada_por = auth.uid() OR has_role('admin'));

-- ACTIVIDADES
ALTER TABLE public.actividades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan sus actividades" ON public.actividades
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

CREATE POLICY "Tutores ven actividades del grupo" ON public.actividades
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- ENTREGAS_ACTIVIDADES
ALTER TABLE public.entregas_actividades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros ven todas las entregas de sus actividades" ON public.entregas_actividades
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.actividades a
            WHERE a.id = actividad_id AND a.maestro_id = auth.uid()
        ) OR has_role('admin')
    );

CREATE POLICY "Tutores ven entregas de sus hijos" ON public.entregas_actividades
    FOR SELECT USING (is_tutor_del_alumno(alumno_id));

-- RUBRICAS
ALTER TABLE public.rubricas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan sus rúbricas" ON public.rubricas
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

CREATE POLICY "Todos ven rúbricas públicas" ON public.rubricas
    FOR SELECT USING (publica = true OR maestro_id = auth.uid());

-- CRITERIOS_RUBRICA
ALTER TABLE public.criterios_rubrica ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan criterios de sus rúbricas" ON public.criterios_rubrica
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.rubricas r
            WHERE r.id = rubrica_id AND r.maestro_id = auth.uid()
        ) OR has_role('admin')
    );

-- LISTAS_COTEJO
ALTER TABLE public.listas_cotejo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan sus listas de cotejo" ON public.listas_cotejo
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

-- ITEMS_LISTA_COTEJO
ALTER TABLE public.items_lista_cotejo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan items de sus listas" ON public.items_lista_cotejo
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.listas_cotejo lc
            WHERE lc.id = lista_cotejo_id AND lc.maestro_id = auth.uid()
        ) OR has_role('admin')
    );

-- EXAMENES
ALTER TABLE public.examenes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan sus exámenes" ON public.examenes
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

-- PREGUNTAS_EXAMEN
ALTER TABLE public.preguntas_examen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan preguntas de sus exámenes" ON public.preguntas_examen
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.examenes e
            WHERE e.id = examen_id AND e.maestro_id = auth.uid()
        ) OR has_role('admin')
    );

-- CALIFICACIONES
ALTER TABLE public.calificaciones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan sus calificaciones" ON public.calificaciones
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

CREATE POLICY "Tutores ven calificaciones de sus hijos" ON public.calificaciones
    FOR SELECT USING (is_tutor_del_alumno(alumno_id));

-- EVIDENCIAS
ALTER TABLE public.evidencias ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros gestionan sus evidencias" ON public.evidencias
    FOR ALL USING (maestro_id = auth.uid() OR has_role('admin') OR has_role('director'));

CREATE POLICY "Tutores ven evidencias de sus hijos" ON public.evidencias
    FOR SELECT USING (is_tutor_del_alumno(alumno_id));

-- COMUNICADOS
ALTER TABLE public.comunicados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Maestros y admins crean comunicados" ON public.comunicados
    FOR INSERT WITH CHECK (has_role('maestro') OR has_role('admin') OR has_role('director'));

CREATE POLICY "Todos los autenticados ven comunicados" ON public.comunicados
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Remitentes actualizan sus comunicados" ON public.comunicados
    FOR UPDATE USING (remitente_id = auth.uid() OR has_role('admin'));

-- LECTURAS_COMUNICADOS
ALTER TABLE public.lecturas_comunicados ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tutores gestionan sus lecturas" ON public.lecturas_comunicados
    FOR ALL USING (tutor_id = auth.uid() OR has_role('admin'));

-- MENSAJES_PADRES
ALTER TABLE public.mensajes_padres ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven sus mensajes" ON public.mensajes_padres
    FOR SELECT USING (remitente_id = auth.uid() OR destinatario_id = auth.uid() OR has_role('admin'));

CREATE POLICY "Usuarios envían mensajes" ON public.mensajes_padres
    FOR INSERT WITH CHECK (remitente_id = auth.uid());

CREATE POLICY "Destinatarios actualizan estado de lectura" ON public.mensajes_padres
    FOR UPDATE USING (destinatario_id = auth.uid() OR has_role('admin'));

-- EVENTOS_CALENDARIO
ALTER TABLE public.eventos_calendario ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Autenticados ven eventos públicos" ON public.eventos_calendario
    FOR SELECT USING (es_publico = true OR creado_por = auth.uid() OR has_role('admin'));

CREATE POLICY "Maestros y admins crean eventos" ON public.eventos_calendario
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Creadores gestionan sus eventos" ON public.eventos_calendario
    FOR ALL USING (creado_por = auth.uid() OR has_role('admin') OR has_role('director'));

-- RECORDATORIOS
ALTER TABLE public.recordatorios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios gestionan sus recordatorios" ON public.recordatorios
    FOR ALL USING (usuario_id = auth.uid() OR has_role('admin'));

-- CONFIGURACION_SISTEMA
ALTER TABLE public.configuracion_sistema ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins y directores gestionan configuración" ON public.configuracion_sistema
    FOR ALL USING (has_role('admin') OR has_role('director'));

CREATE POLICY "Autenticados ven configuración" ON public.configuracion_sistema
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- FASE 5: AUTOMATIZACIÓN - TRIGGERS
-- ============================================================

-- Triggers de timestamps para todas las tablas
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_user_roles_updated_at
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_escuelas_updated_at
    BEFORE UPDATE ON public.escuelas
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_grupos_updated_at
    BEFORE UPDATE ON public.grupos
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_materias_updated_at
    BEFORE UPDATE ON public.materias
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_gmm_updated_at
    BEFORE UPDATE ON public.grupo_materia_maestro
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_tutores_updated_at
    BEFORE UPDATE ON public.tutores
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_alumnos_updated_at
    BEFORE UPDATE ON public.alumnos
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_observaciones_updated_at
    BEFORE UPDATE ON public.observaciones_alumnos
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_historial_updated_at
    BEFORE UPDATE ON public.historial_academico
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_asistencia_updated_at
    BEFORE UPDATE ON public.asistencia
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_justificaciones_updated_at
    BEFORE UPDATE ON public.justificaciones_asistencia
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_planeaciones_updated_at
    BEFORE UPDATE ON public.planeaciones
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_biblioteca_updated_at
    BEFORE UPDATE ON public.biblioteca_actividades
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_actividades_updated_at
    BEFORE UPDATE ON public.actividades
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_entregas_updated_at
    BEFORE UPDATE ON public.entregas_actividades
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_rubricas_updated_at
    BEFORE UPDATE ON public.rubricas
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_criterios_updated_at
    BEFORE UPDATE ON public.criterios_rubrica
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_listas_cotejo_updated_at
    BEFORE UPDATE ON public.listas_cotejo
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_items_lista_updated_at
    BEFORE UPDATE ON public.items_lista_cotejo
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_examenes_updated_at
    BEFORE UPDATE ON public.examenes
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_preguntas_updated_at
    BEFORE UPDATE ON public.preguntas_examen
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_calificaciones_updated_at
    BEFORE UPDATE ON public.calificaciones
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_evidencias_updated_at
    BEFORE UPDATE ON public.evidencias
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_comunicados_updated_at
    BEFORE UPDATE ON public.comunicados
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_lecturas_updated_at
    BEFORE UPDATE ON public.lecturas_comunicados
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_mensajes_updated_at
    BEFORE UPDATE ON public.mensajes_padres
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_eventos_updated_at
    BEFORE UPDATE ON public.eventos_calendario
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_recordatorios_updated_at
    BEFORE UPDATE ON public.recordatorios
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_config_updated_at
    BEFORE UPDATE ON public.configuracion_sistema
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Trigger de sincronización de nuevos usuarios
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, rol)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        'maestro'
    );

    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'maestro');

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- FASE 1: ENUMS para Stripe/Suscripciones
-- ============================================

DO $$ BEGIN
    CREATE TYPE ESTADO_SUSCRIPCION AS ENUM (
        'trialing',
        'active',
        'past_due',
        'canceled',
        'unpaid',
        'incomplete'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE INTERVALO_PLAN AS ENUM (
        'month',
        'year'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE ESTADO_PAGO AS ENUM (
        'succeeded',
        'pending',
        'failed',
        'refunded'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- FASE 2: TABLAS
-- ============================================

-- Tabla de planes de suscripción
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR NOT NULL,
    descripcion TEXT,
    precio_centavos INTEGER NOT NULL,
    moneda VARCHAR DEFAULT 'mxn',
    intervalo INTERVALO_PLAN NOT NULL DEFAULT 'month',
    dias_prueba INTEGER DEFAULT 15,
    stripe_price_id VARCHAR,
    stripe_product_id VARCHAR,
    caracteristicas JSONB DEFAULT '[]'::jsonb,
    activo BOOLEAN DEFAULT true,
    orden INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscription_plans_activo ON public.subscription_plans(activo);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_intervalo ON public.subscription_plans(intervalo);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_stripe_price_id ON public.subscription_plans(stripe_price_id);

-- Tabla de suscripciones de usuarios
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    plan_id UUID NOT NULL,
    stripe_customer_id VARCHAR,
    stripe_subscription_id VARCHAR UNIQUE,
    estado ESTADO_SUSCRIPCION NOT NULL DEFAULT 'trialing',
    fecha_inicio TIMESTAMP WITH TIME ZONE DEFAULT now(),
    fecha_fin TIMESTAMP WITH TIME ZONE,
    fecha_prueba_fin TIMESTAMP WITH TIME ZONE DEFAULT (now() + INTERVAL '15 days'),
    cancelar_al_periodo_fin BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_id ON public.subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_customer_id ON public.subscriptions(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_subscription_id ON public.subscriptions(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_estado ON public.subscriptions(estado);
CREATE INDEX IF NOT EXISTS idx_subscriptions_fecha_fin ON public.subscriptions(fecha_fin);

-- Tabla de historial de pagos
CREATE TABLE IF NOT EXISTS public.payment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    subscription_id UUID,
    stripe_payment_intent_id VARCHAR,
    stripe_invoice_id VARCHAR,
    monto_centavos INTEGER NOT NULL,
    moneda VARCHAR DEFAULT 'mxn',
    estado ESTADO_PAGO NOT NULL DEFAULT 'pending',
    descripcion TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    fecha_pago TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payment_history_user_id ON public.payment_history(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_history_subscription_id ON public.payment_history(subscription_id);
CREATE INDEX IF NOT EXISTS idx_payment_history_stripe_payment_intent_id ON public.payment_history(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_payment_history_estado ON public.payment_history(estado);
CREATE INDEX IF NOT EXISTS idx_payment_history_fecha_pago ON public.payment_history(fecha_pago);

-- Tabla de configuración de Stripe (claves del propietario)
CREATE TABLE IF NOT EXISTS public.stripe_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    stripe_publishable_key TEXT,
    stripe_secret_key_encrypted TEXT,
    stripe_webhook_secret_encrypted TEXT,
    modo_prueba BOOLEAN DEFAULT true,
    configurado BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stripe_config_user_id ON public.stripe_config(user_id);

-- ============================================
-- FASE 3: FUNCIONES LÓGICAS
-- ============================================

-- Función para verificar si un usuario tiene suscripción activa
CREATE OR REPLACE FUNCTION public.tiene_suscripcion_activa(_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.subscriptions
        WHERE user_id = _user_id
        AND estado IN ('active', 'trialing')
        AND (fecha_fin IS NULL OR fecha_fin > now())
    );
$$;

-- Función para verificar si un usuario está en período de prueba
CREATE OR REPLACE FUNCTION public.en_periodo_prueba(_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.subscriptions
        WHERE user_id = _user_id
        AND estado = 'trialing'
        AND fecha_prueba_fin > now()
    );
$$;

-- ============================================
-- FASE 4: RLS POLICIES
-- ============================================

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_config ENABLE ROW LEVEL SECURITY;

-- Políticas para subscription_plans
CREATE POLICY "Todos pueden ver planes activos" ON public.subscription_plans
    FOR SELECT
    USING (activo = true);

CREATE POLICY "Solo admins gestionan planes" ON public.subscription_plans
    FOR ALL
    USING (has_role('admin'::rol_usuario));

-- Políticas para subscriptions
CREATE POLICY "Usuarios ven su propia suscripción" ON public.subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins ven todas las suscripciones" ON public.subscriptions
    FOR SELECT
    USING (has_role('admin'::rol_usuario));

CREATE POLICY "Sistema gestiona suscripciones" ON public.subscriptions
    FOR ALL
    USING (auth.uid() = user_id OR has_role('admin'::rol_usuario));

-- Políticas para payment_history
CREATE POLICY "Usuarios ven su historial de pagos" ON public.payment_history
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins ven todo el historial" ON public.payment_history
    FOR SELECT
    USING (has_role('admin'::rol_usuario));

CREATE POLICY "Sistema registra pagos" ON public.payment_history
    FOR INSERT
    WITH CHECK (auth.uid() = user_id OR has_role('admin'::rol_usuario));

-- Políticas para stripe_config
CREATE POLICY "Propietario gestiona su config de Stripe" ON public.stripe_config
    FOR ALL
    USING (auth.uid() = user_id);

-- ============================================
-- FASE 5: TRIGGERS
-- ============================================

-- Trigger para updated_at en subscription_plans
CREATE TRIGGER update_subscription_plans_updated_at
    BEFORE UPDATE ON public.subscription_plans
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Trigger para updated_at en subscriptions
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Trigger para updated_at en payment_history
CREATE TRIGGER update_payment_history_updated_at
    BEFORE UPDATE ON public.payment_history
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Trigger para updated_at en stripe_config
CREATE TRIGGER update_stripe_config_updated_at
    BEFORE UPDATE ON public.stripe_config
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- ============================================
-- DATOS INICIALES: Planes de suscripción
-- ============================================

INSERT INTO public.subscription_plans (nombre, descripcion, precio_centavos, moneda, intervalo, dias_prueba, caracteristicas, orden) VALUES
(
    'Plan Mensual',
    'Acceso completo a PlaneaDocente por un mes',
    19900,
    'mxn',
    'month',
    15,
    '["Planeaciones ilimitadas", "IA para generar contenido", "Gestión de alumnos", "Calificaciones y asistencia", "Comunicados a padres", "Soporte por email"]'::jsonb,
    1
),
(
    'Plan Anual',
    'Acceso completo a PlaneaDocente por un año - Ahorra 2 meses',
    199000,
    'mxn',
    'year',
    15,
    '["Todo lo del plan mensual", "2 meses gratis", "Soporte prioritario", "Acceso anticipado a nuevas funciones", "Exportación avanzada de reportes"]'::jsonb,
    2
);

-- ============================================
-- FASE 1: FUNCIONES BASE Y UTILIDADES
-- ============================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FASE 3: FUNCIONES QUE DEPENDEN DE TABLAS
-- ============================================

-- Función para verificar rol del usuario autenticado
CREATE OR REPLACE FUNCTION public.has_role(_role rol_usuario)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role = _role
  );
$$;

-- Función para verificar si el maestro es del grupo
CREATE OR REPLACE FUNCTION public.is_maestro_del_grupo(_grupo_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.grupos
    WHERE id = _grupo_id
    AND maestro_id = auth.uid()
  );
$$;

-- Función para verificar si el usuario es tutor del alumno
CREATE OR REPLACE FUNCTION public.is_tutor_del_alumno(_alumno_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.alumnos a
    JOIN public.tutores t ON t.id = a.tutor_id
    WHERE a.id = _alumno_id
    AND t.user_id = auth.uid()
  );
$$;

-- Función para obtener la suscripción activa del usuario
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE(
  subscription_id UUID,
  plan_nombre VARCHAR,
  estado ESTADO_SUSCRIPCION,
  fecha_fin TIMESTAMP WITH TIME ZONE,
  fecha_prueba_fin TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT
    s.id,
    sp.nombre,
    s.estado,
    s.fecha_fin,
    s.fecha_prueba_fin
  FROM public.subscriptions s
  JOIN public.subscription_plans sp ON sp.id = s.plan_id
  WHERE s.user_id = _user_id
  AND s.estado IN ('active', 'trialing')
  ORDER BY s.created_at DESC
  LIMIT 1;
$$;

-- Función para verificar si el usuario tiene suscripción activa
CREATE OR REPLACE FUNCTION public.has_active_subscription()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.subscriptions
    WHERE user_id = auth.uid()
    AND estado IN ('active', 'trialing')
    AND (fecha_fin IS NULL OR fecha_fin > now())
  );
$$;

-- ============================================
-- FASE 5: TRIGGERS DE TIMESTAMPS
-- ============================================

-- Trigger para profiles
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para user_roles
DROP TRIGGER IF EXISTS update_user_roles_updated_at ON public.user_roles;
CREATE TRIGGER update_user_roles_updated_at
    BEFORE UPDATE ON public.user_roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para subscriptions
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para subscription_plans
DROP TRIGGER IF EXISTS update_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER update_subscription_plans_updated_at
    BEFORE UPDATE ON public.subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para payment_history
DROP TRIGGER IF EXISTS update_payment_history_updated_at ON public.payment_history;
CREATE TRIGGER update_payment_history_updated_at
    BEFORE UPDATE ON public.payment_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para stripe_config
DROP TRIGGER IF EXISTS update_stripe_config_updated_at ON public.stripe_config;
CREATE TRIGGER update_stripe_config_updated_at
    BEFORE UPDATE ON public.stripe_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para escuelas
DROP TRIGGER IF EXISTS update_escuelas_updated_at ON public.escuelas;
CREATE TRIGGER update_escuelas_updated_at
    BEFORE UPDATE ON public.escuelas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para grupos
DROP TRIGGER IF EXISTS update_grupos_updated_at ON public.grupos;
CREATE TRIGGER update_grupos_updated_at
    BEFORE UPDATE ON public.grupos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para alumnos
DROP TRIGGER IF EXISTS update_alumnos_updated_at ON public.alumnos;
CREATE TRIGGER update_alumnos_updated_at
    BEFORE UPDATE ON public.alumnos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para planeaciones
DROP TRIGGER IF EXISTS update_planeaciones_updated_at ON public.planeaciones;
CREATE TRIGGER update_planeaciones_updated_at
    BEFORE UPDATE ON public.planeaciones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para actividades
DROP TRIGGER IF EXISTS update_actividades_updated_at ON public.actividades;
CREATE TRIGGER update_actividades_updated_at
    BEFORE UPDATE ON public.actividades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para calificaciones
DROP TRIGGER IF EXISTS update_calificaciones_updated_at ON public.calificaciones;
CREATE TRIGGER update_calificaciones_updated_at
    BEFORE UPDATE ON public.calificaciones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para asistencia
DROP TRIGGER IF EXISTS update_asistencia_updated_at ON public.asistencia;
CREATE TRIGGER update_asistencia_updated_at
    BEFORE UPDATE ON public.asistencia
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para materias
DROP TRIGGER IF EXISTS update_materias_updated_at ON public.materias;
CREATE TRIGGER update_materias_updated_at
    BEFORE UPDATE ON public.materias
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para rubricas
DROP TRIGGER IF EXISTS update_rubricas_updated_at ON public.rubricas;
CREATE TRIGGER update_rubricas_updated_at
    BEFORE UPDATE ON public.rubricas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para examenes
DROP TRIGGER IF EXISTS update_examenes_updated_at ON public.examenes;
CREATE TRIGGER update_examenes_updated_at
    BEFORE UPDATE ON public.examenes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para comunicados
DROP TRIGGER IF EXISTS update_comunicados_updated_at ON public.comunicados;
CREATE TRIGGER update_comunicados_updated_at
    BEFORE UPDATE ON public.comunicados
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para tutores
DROP TRIGGER IF EXISTS update_tutores_updated_at ON public.tutores;
CREATE TRIGGER update_tutores_updated_at
    BEFORE UPDATE ON public.tutores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCIÓN Y TRIGGER PARA SINCRONIZAR NUEVOS USUARIOS
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _full_name TEXT;
  _avatar_url TEXT;
BEGIN
  _full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );
  _avatar_url := COALESCE(
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'picture',
    NULL
  );

  -- Insertar perfil
  INSERT INTO public.profiles (id, email, full_name, avatar_url, rol)
  VALUES (
    NEW.id,
    NEW.email,
    _full_name,
    _avatar_url,
    'maestro'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    updated_at = now();

  -- Asignar rol por defecto
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'maestro')
  ON CONFLICT (user_id, role) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Crear trigger en auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- DATOS DE PLANES DE SUSCRIPCIÓN
-- ============================================
-- IMPORTANTE: Reemplaza los stripe_price_id con los IDs reales de tu dashboard de Stripe
-- Dashboard Stripe > Products > Copiar el Price ID (price_xxxx)

INSERT INTO public.subscription_plans (
  nombre,
  descripcion,
  precio_centavos,
  moneda,
  intervalo,
  dias_prueba,
  stripe_price_id,
  stripe_product_id,
  caracteristicas,
  activo,
  orden
) VALUES
(
  'Básico',
  'Ideal para maestros independientes que quieren organizar su trabajo docente',
  19900,
  'mxn',
  'month',
  15,
  'price_REEMPLAZAR_BASICO_MENSUAL',
  'prod_REEMPLAZAR_BASICO',
  '[
    "Hasta 2 grupos",
    "Hasta 40 alumnos por grupo",
    "Planeaciones ilimitadas",
    "Control de asistencia",
    "Calificaciones básicas",
    "Soporte por email"
  ]'::jsonb,
  true,
  1
),
(
  'Profesional',
  'Para maestros que quieren aprovechar al máximo la tecnología en su aula',
  39900,
  'mxn',
  'month',
  15,
  'price_REEMPLAZAR_PRO_MENSUAL',
  'prod_REEMPLAZAR_PRO',
  '[
    "Grupos ilimitados",
    "Alumnos ilimitados",
    "Planeaciones con IA",
    "Exámenes con IA",
    "Rúbricas y listas de cotejo",
    "Comunicados a padres",
    "Evidencias y portafolio",
    "Reportes avanzados",
    "Soporte prioritario"
  ]'::jsonb,
  true,
  2
),
(
  'Institucional',
  'Para escuelas y directivos que necesitan gestionar toda la institución',
  99900,
  'mxn',
  'month',
  15,
  'price_REEMPLAZAR_INST_MENSUAL',
  'prod_REEMPLAZAR_INST',
  '[
    "Todo lo del plan Profesional",
    "Múltiples maestros",
    "Panel de director",
    "Gestión de escuela completa",
    "Estadísticas institucionales",
    "Integración con padres de familia",
    "Soporte dedicado",
    "Capacitación incluida"
  ]'::jsonb,
  true,
  3
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- FASE 1: FUNCIONES UTILITARIAS
-- ============================================================

-- Función estándar para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FASE 3: FUNCIONES DE LÓGICA (dependen de tablas existentes)
-- ============================================================

-- Verificar si el usuario tiene un rol específico
CREATE OR REPLACE FUNCTION public.has_role(_role rol_usuario)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid()
    AND role = _role
  );
$$;

-- Verificar si el usuario es maestro de un grupo específico
CREATE OR REPLACE FUNCTION public.is_maestro_del_grupo(_grupo_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.grupos
    WHERE id = _grupo_id
    AND maestro_id = auth.uid()
  );
$$;

-- Verificar si el usuario es tutor de un alumno específico
CREATE OR REPLACE FUNCTION public.is_tutor_del_alumno(_alumno_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.alumnos a
    JOIN public.tutores t ON t.id = a.tutor_id
    WHERE a.id = _alumno_id
    AND t.user_id = auth.uid()
  );
$$;

-- Verificar si el usuario tiene suscripción activa
CREATE OR REPLACE FUNCTION public.has_active_subscription()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.subscriptions
    WHERE user_id = auth.uid()
    AND estado IN ('active', 'trialing')
    AND (fecha_fin IS NULL OR fecha_fin > now())
  );
$$;

-- Obtener el plan activo del usuario actual
CREATE OR REPLACE FUNCTION public.get_user_subscription_plan()
RETURNS TABLE(
  plan_nombre VARCHAR,
  estado TEXT,
  fecha_prueba_fin TIMESTAMPTZ,
  fecha_fin TIMESTAMPTZ,
  stripe_subscription_id VARCHAR
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT
    sp.nombre AS plan_nombre,
    s.estado::TEXT,
    s.fecha_prueba_fin,
    s.fecha_fin,
    s.stripe_subscription_id
  FROM public.subscriptions s
  JOIN public.subscription_plans sp ON sp.id = s.plan_id
  WHERE s.user_id = auth.uid()
  ORDER BY s.created_at DESC
  LIMIT 1;
$$;

-- Función para sincronizar nuevos usuarios de auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Crear perfil del usuario
  INSERT INTO public.profiles (id, email, full_name, avatar_url, rol)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    NEW.raw_user_meta_data->>'avatar_url',
    'maestro'
  )
  ON CONFLICT (id) DO NOTHING;

  -- Asignar rol por defecto
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'maestro')
  ON CONFLICT (user_id, role) DO NOTHING;

  RETURN NEW;
END;
$$;

-- ============================================================
-- FASE 5: TRIGGERS
-- ============================================================

-- Trigger para sincronizar nuevos usuarios de Supabase Auth
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Triggers de updated_at para todas las tablas
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_roles_updated_at ON public.user_roles;
CREATE TRIGGER update_user_roles_updated_at
  BEFORE UPDATE ON public.user_roles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER update_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payment_history_updated_at ON public.payment_history;
CREATE TRIGGER update_payment_history_updated_at
  BEFORE UPDATE ON public.payment_history
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_stripe_config_updated_at ON public.stripe_config;
CREATE TRIGGER update_stripe_config_updated_at
  BEFORE UPDATE ON public.stripe_config
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_planeaciones_updated_at ON public.planeaciones;
CREATE TRIGGER update_planeaciones_updated_at
  BEFORE UPDATE ON public.planeaciones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_actividades_updated_at ON public.actividades;
CREATE TRIGGER update_actividades_updated_at
  BEFORE UPDATE ON public.actividades
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_alumnos_updated_at ON public.alumnos;
CREATE TRIGGER update_alumnos_updated_at
  BEFORE UPDATE ON public.alumnos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_grupos_updated_at ON public.grupos;
CREATE TRIGGER update_grupos_updated_at
  BEFORE UPDATE ON public.grupos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_materias_updated_at ON public.materias;
CREATE TRIGGER update_materias_updated_at
  BEFORE UPDATE ON public.materias
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_calificaciones_updated_at ON public.calificaciones;
CREATE TRIGGER update_calificaciones_updated_at
  BEFORE UPDATE ON public.calificaciones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_asistencia_updated_at ON public.asistencia;
CREATE TRIGGER update_asistencia_updated_at
  BEFORE UPDATE ON public.asistencia
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_comunicados_updated_at ON public.comunicados;
CREATE TRIGGER update_comunicados_updated_at
  BEFORE UPDATE ON public.comunicados
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_escuelas_updated_at ON public.escuelas;
CREATE TRIGGER update_escuelas_updated_at
  BEFORE UPDATE ON public.escuelas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tutores_updated_at ON public.tutores;
CREATE TRIGGER update_tutores_updated_at
  BEFORE UPDATE ON public.tutores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_rubricas_updated_at ON public.rubricas;
CREATE TRIGGER update_rubricas_updated_at
  BEFORE UPDATE ON public.rubricas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_examenes_updated_at ON public.examenes;
CREATE TRIGGER update_examenes_updated_at
  BEFORE UPDATE ON public.examenes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_evidencias_updated_at ON public.evidencias;
CREATE TRIGGER update_evidencias_updated_at
  BEFORE UPDATE ON public.evidencias
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- DATOS INICIALES: PLANES DE SUSCRIPCIÓN
-- IMPORTANTE: Reemplaza los stripe_price_id con los IDs reales
-- de tu dashboard de Stripe (Productos > Precios)
-- ============================================================

INSERT INTO public.subscription_plans (
  nombre,
  descripcion,
  precio_centavos,
  moneda,
  intervalo,
  dias_prueba,
  stripe_price_id,
  stripe_product_id,
  caracteristicas,
  activo,
  orden
) VALUES
(
  'Básico',
  'Ideal para maestros independientes que quieren organizar su trabajo docente.',
  19900,
  'mxn',
  'month',
  15,
  'price_REEMPLAZAR_BASICO_MENSUAL',
  'prod_REEMPLAZAR_BASICO',
  '[
    "1 grupo activo",
    "Hasta 40 alumnos",
    "Planeaciones ilimitadas",
    "Registro de asistencia",
    "Calificaciones básicas",
    "Soporte por email"
  ]'::jsonb,
  true,
  1
),
(
  'Profesional',
  'Para maestros que necesitan herramientas avanzadas y generación con IA.',
  39900,
  'mxn',
  'month',
  15,
  'price_REEMPLAZAR_PRO_MENSUAL',
  'prod_REEMPLAZAR_PRO',
  '[
    "Grupos ilimitados",
    "Alumnos ilimitados",
    "Planeaciones con IA",
    "Exámenes con IA",
    "Rúbricas y listas de cotejo",
    "Comunicados a padres",
    "Evidencias y portafolio",
    "Reportes avanzados",
    "Soporte prioritario"
  ]'::jsonb,
  true,
  2
),
(
  'Escuela',
  'Solución completa para directores y equipos docentes de toda la escuela.',
  99900,
  'mxn',
  'month',
  15,
  'price_REEMPLAZAR_ESCUELA_MENSUAL',
  'prod_REEMPLAZAR_ESCUELA',
  '[
    "Todo lo del plan Profesional",
    "Hasta 20 maestros",
    "Panel de director",
    "Gestión centralizada",
    "Estadísticas por escuela",
    "Configuración personalizada",
    "Integración con padres de familia",
    "Soporte dedicado",
    "Capacitación incluida"
  ]'::jsonb,
  true,
  3
)
ON CONFLICT DO NOTHING;
