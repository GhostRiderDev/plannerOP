# Documentación de CargoPlanner

## 1. Introducción

CargoPlanner es un sistema integral de gestión operativa diseñado específicamente para optimizar la planificación de operaciones y la operación de trabajadores en entornos empresariales, con un enfoque particular en sectores como la logística, operaciones portuarias y gestión de recursos humanos. El sistema consta de dos componentes principales: un backend (ServidorCargoPlanner) desarrollado con NestJS y una aplicación frontend multiplataforma (PlannerOP) desarrollada con Flutter.

El desarrollo de CargoPlanner responde a la necesidad creciente de las empresas de optimizar sus recursos humanos y mejorar la eficiencia operativa mediante herramientas digitales que faciliten la toma de decisiones en tiempo real.

## 2. Planteamiento del Problema

En los entornos operativos actuales, especialmente en sectores como logística y operaciones portuarias, las empresas enfrentan múltiples desafíos:

1. **Gestión ineficiente de personal**: Distribución manual de trabajadores que resulta en asignaciones subóptimas y tiempos muertos.
2. **Seguimiento limitado de operaciones**: Dificultad para monitorear en tiempo real el estado de las diferentes tareas y operaciones.
3. **Duplicación de esfuerzos**: Falta de coordinación entre supervisores que provoca sobreoperación o suboperación de personal.
4. **Documentación y reportes manuales**: Generación de informes operativos que consume tiempo y está sujeta a errores humanos.
5. **Comunicación fragmentada**: Canales de comunicación ineficientes entre los diferentes niveles operativos.
6. **Planificación reactiva vs. proactiva**: Dificultad para anticipar necesidades de personal y recursos con suficiente antelación.

La ausencia de sistemas digitales integrados para abordar estos problemas deriva en:
- Incremento en los costos operativos
- Disminución de la productividad
- Mayor tiempo de respuesta ante cambios imprevistos
- Decisiones basadas en información desactualizada o incompleta

## 3. Objetivos

### 3.1 Objetivo General

Desarrollar e implementar un sistema integral de gestión operativa que optimice la planificación, operación y seguimiento de recursos humanos y tareas en entornos empresariales, mejorando la eficiencia operativa y facilitando la toma de decisiones basada en datos en tiempo real.

### 3.2 Objetivos Específicos

1. Diseñar e implementar una interfaz intuitiva que facilite la gestión de asignaciones de trabajadores, grupos de trabajo y seguimiento de tareas.

2. Desarrollar un sistema robusto de backend que soporte la gestión de datos, autenticación y comunicación API para todas las funcionalidades del sistema.

3. Implementar un mecanismo eficiente para el seguimiento en tiempo real de operaciones y estado de disponibilidad de los trabajadores.

4. Crear un sistema flexible de reportes y análisis de datos que permita la exportación de información en formatos estándar para su posterior procesamiento.

5. Establecer un sistema de roles y permisos que garantice la seguridad y el acceso apropiado a la información según el nivel jerárquico del usuario.

6. Desarrollar la plataforma como una solución multiplataforma que pueda ser utilizada en diferentes dispositivos y sistemas operativos.

## 4. Justificación

La implementación de CargoPlanner se justifica por múltiples factores:

### 4.1 Justificación Tecnológica
La digitalización de procesos operativos representa una ventaja competitiva en el mercado actual. CargoPlanner introduce tecnologías modernas (Flutter, NestJS, PostgreSQL) que garantizan escalabilidad, mantenibilidad y adaptabilidad a las necesidades cambiantes del negocio.

### 4.2 Justificación Económica
El sistema permite:
- Reducir costos operativos mediante la optimización de operación de personal
- Minimizar tiempos muertos y maximizar la utilización de recursos humanos
- Disminuir errores en la gestión que podrían resultar en pérdidas económicas
- Mejorar la planificación proactiva, reduciendo costos de respuestas reactivas

### 4.3 Justificación Operativa
CargoPlanner responde directamente a las necesidades operativas de:
- Visualización en tiempo real del estado de operaciones
- Operación eficiente basada en disponibilidad y habilidades
- Seguimiento automatizado de tareas y personal
- Generación automática de reportes y análisis de datos

## 5. Arquitectura del Sistema

CargoPlanner implementa una arquitectura cliente-servidor con separación clara de responsabilidades:

### 5.1 Arquitectura General

```
┌─────────────────────────────────┐      ┌───────────────────────────────┐
│      Cliente (PlannerOP)        │      │    Servidor (CargoPlanner)    │
│                                 │      │                               │
│  ┌─────────┐    ┌─────────┐    │      │    ┌─────────┐   ┌─────────┐  │
│  │   UI    │    │ Estado  │    │      │    │  API    │   │ Lógica  │  │
│  │(Flutter)│◄──►│(Provider)│◄───┼──────┼───►│(NestJS) │◄─►│Negocio  │  │
│  └─────────┘    └─────────┘    │      │    └─────────┘   └─────────┘  │
│         │             ▲        │      │         ▲             │       │
│         ▼             │        │      │         │             ▼       │
│  ┌─────────────────────────┐   │      │    ┌───────────────────────┐  │
│  │     Servicios Cliente   │   │      │    │   Servicios Servidor  │  │
│  └─────────────────────────┘   │      │    └───────────────────────┘  │
│                                 │      │               │               │
└─────────────────────────────────┘      └───────────────┼───────────────┘
                                                         │
                                            ┌────────────▼───────────┐
                                            │    Base de Datos       │
                                            │     (PostgreSQL)       │
                                            └────────────────────────┘
```

### 5.2 Arquitectura del Backend (ServidorCargoPlanner)

El backend sigue una arquitectura de tres capas:

1. **Capa de Presentación**: Controladores NestJS que gestionan las solicitudes HTTP
2. **Capa de Lógica de Negocio**: Servicios que implementan la lógica empresarial
3. **Capa de Datos**: Prisma ORM para la interacción con PostgreSQL

### 5.3 Arquitectura del Frontend (PlannerOP)

La aplicación cliente también sigue una arquitectura de tres capas:

1. **Capa de Presentación**: Widgets de Flutter para la interfaz de usuario
2. **Capa de Lógica de Negocio**: Providers para gestión del estado y reglas de negocio
3. **Capa de Datos**: Servicios para comunicación con API y almacenamiento local

## 6. Tecnologías Implementadas

### 6.1 Backend
- **NestJS**: Framework para construcción de aplicaciones Node.js escalables
- **Prisma**: ORM moderno para interacción con bases de datos
- **PostgreSQL**: Sistema de gestión de base de datos relacional
- **JWT**: Sistema de autenticación basado en tokens
- **TypeScript**: Lenguaje de programación tipado
- **Swagger**: Documentación de API interactiva

### 6.2 Frontend
- **Flutter 3.6+**: Framework multiplataforma para desarrollo de interfaces
- **Provider**: Gestor de estado para Flutter
- **SharedPreferences**: Almacenamiento local de datos
- **Flutter Neumorphic Plus**: Biblioteca de UI para diseño neumórfico
- **FL Chart**: Visualización de datos y gráficos
- **Syncfusion XlsIO**: Exportación de datos a Excel
- **HTTP**: Comunicación con API RESTful
- **JWT**: Autenticación mediante tokens

## 7. Modelo de Datos

### 7.1 Entidades Principales

1. **Worker (Trabajador)**
   - Atributos: id, nombre, documento, área, disponibilidad, estado
   - Relaciones: Asignaciones, Grupos

2. **Assignment (Operación)**
   - Atributos: id, área, tarea, fecha, hora, zona, motonave, estado
   - Relaciones: Trabajadores, Grupos, Supervisores

3. **WorkerGroup (Grupo de Trabajadores)**
   - Atributos: id, nombre, fechas, horarios
   - Relaciones: Trabajadores, Asignaciones

4. **Area (Área)**
   - Atributos: id, nombre, descripción
   - Relaciones: Asignaciones, Trabajadores

5. **User (Usuario)**
   - Atributos: id, nombre, correo, rol, estado
   - Relaciones: Asignaciones (como supervisor)

### 7.2 Diagrama de Entidad-Relación

```
┌───────────┐       ┌───────────────────┐       ┌────────────┐
│  Worker   │◄──────┤WorkerAssignment   ├───────►│Assignment  │
└───────────┘       └───────────────────┘       └────────────┘
      ▲                                               ▲
      │                                               │
      │           ┌───────────────────┐               │
      └───────────┤   WorkerGroup     ├───────────────┘
                  └───────────────────┘
                           ▲
                           │
┌───────────┐              │              ┌────────────┐
│   Area    │◄─────────────┴──────────────►│   User    │
└───────────┘                             └────────────┘
```

## 8. Funcionalidades Principales

### 8.1 Gestión de Trabajadores
- Registro y actualización de información personal
- Control de disponibilidad y estados (Disponible, Asignado, Incapacitado)
- Visualización de historial de asignaciones
- Agrupación por áreas y habilidades

### 8.2 Gestión de Asignaciones
- Creación de nuevas asignaciones con selección de personal
- Establecimiento de fechas, horarios y prioridades
- Seguimiento del ciclo de vida (Pendiente → En Curso → Completada/Cancelada)
- Operación de supervisores responsables

### 8.3 Grupos de Trabajo
- Creación y gestión de equipos con nombre distintivo
- Operación de personal específico a cada grupo
- Establecimiento de horarios específicos independientes
- Seguimiento grupal de actividades y rendimiento

### 8.4 Seguimiento en Tiempo Real
- Actualización automática de estados de asignaciones
- Monitoreo de disponibilidad de trabajadores
- Notificaciones sobre cambios importantes
- Vista centralizada de operaciones activas

### 8.5 Reportes y Análisis
- Generación de reportes operativos detallados
- Exportación de datos a Excel
- Visualización de estadísticas en gráficos interactivos
- Filtrado avanzado por múltiples criterios

### 8.6 Seguridad y Autenticación
- Sistema de inicio de sesión con JWT
- Control de acceso basado en roles
- Protección de API y recursos
- Auditoría de acciones de usuarios

## 9. Flujos de Trabajo Principales

### 9.1 Flujo de Operación de Trabajadores

```
┌───────────┐     ┌───────────────┐     ┌───────────────┐
│  Iniciar  │────▶│  Seleccionar  │────▶│   Configurar  │
│ Creación  │     │ Trabajadores  │     │    Detalles   │
└───────────┘     └───────────────┘     └───────┬───────┘
                                                │
┌───────────┐     ┌───────────────┐     ┌───────▼───────┐
│ Operación│◀────│    Guardar    │◀────│   Seleccionar │
│  Creada   │     │               │     │ Supervisores  │
└───────────┘     └───────────────┘     └───────────────┘
```

### 9.2 Ciclo de Vida de una Operación

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│Pendiente │────▶│ En Curso │────▶│Completada│────▶│ Historial │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
      │                │
      │                │
      ▼                ▼
┌──────────────────────────┐
│       Cancelada          │
└──────────────────────────┘
```

### 9.3 Flujo de Generación de Reportes

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Selección│────▶│  Aplicar │────▶│ Previsua-│────▶│Exportar/ │
│de Filtros│     │  Filtros │     │lización  │     │Compartir │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
```

## 10. Interfaces de Usuario

La aplicación cliente (PlannerOP) organiza sus interfaces en cuatro pestañas principales:

1. **Dashboard**: Panel central con visión general de operaciones activas
   - Indicadores clave de rendimiento
   - Acceso rápido a funciones principales
   - Alertas y notificaciones importantes

2. **Trabajadores**: Gestión completa del personal
   - Lista filtrable de trabajadores
   - Estados de disponibilidad
   - Historiales de operación
   - Gestión de grupos

3. **Asignaciones**: Administración del flujo de trabajo
   - Vistas separadas por estado (Pendientes/En Curso/Completadas)
   - Formulario intuitivo de creación
   - Funciones de filtrado y búsqueda
   - Acciones contextuales según estado

4. **Reportes**: Análisis y exportación de datos
   - Gráficos interactivos de distribución
   - Análisis temporal de operaciones
   - Filtros avanzados por múltiples criterios
   - Exportación a formatos estándar

## 11. Seguridad y Privacidad

CargoPlanner implementa diversas medidas para garantizar la seguridad de los datos:

1. **Autenticación robusta**:
   - Sistema basado en JWT con tiempo de expiración
   - Almacenamiento seguro de credenciales
   - Prevención de ataques comunes (CSRF, XSS)

2. **Control de acceso**:
   - Roles diferenciados (Administrador, Supervisor, Usuario)
   - Permisos granulares por funcionalidad
   - Validación en cliente y servidor

3. **Protección de datos**:
   - Encriptación de datos sensibles
   - Comunicaciones seguras (HTTPS)
   - Validación de entradas en todos los niveles

4. **Auditoría**:
   - Registro de acciones críticas
   - Historial de modificaciones
   - Trazabilidad de cambios

## 12. Despliegue e Implementación

### 12.1 Requisitos de Sistema

**Backend (ServidorCargoPlanner)**:
- Node.js v16+ LTS
- PostgreSQL 13+
- 2GB RAM mínimo recomendado
- Soporte para Docker (opcional)

**Frontend (PlannerOP)**:
- Dispositivos con Android 7.0+ o iOS 12+
- Windows 10+ para versión de escritorio
- 1GB de espacio de almacenamiento
- Conexión a internet para operación normal

### 12.2 Estrategia de Despliegue

El sistema se puede desplegar siguiendo diferentes estrategias:

1. **Despliegue en la nube**:
   - Backend en servicios como AWS, Google Cloud o Azure
   - Base de datos gestionada (RDS, Cloud SQL)
   - Aplicación móvil distribuida vía tiendas oficiales

2. **Despliegue local (on-premise)**:
   - Servidor local para backend y base de datos
   - Distribución interna de aplicación por MDM
   - VPN para acceso remoto seguro

3. **Modelo híbrido**:
   - Backend en la nube con opción de caché local
   - Sincronización periódica para ambientes con conectividad limitada
   - Redundancia de sistemas críticos

## 13. Mantenimiento y Evolución

### 13.1 Estrategia de Mantenimiento

- Actualizaciones periódicas de seguridad
- Corrección de errores mediante metodología ágil
- Monitorización constante de rendimiento
- Pruebas de regresión con cada actualización

### 13.2 Roadmap de Evolución

**Corto plazo (3-6 meses)**:
- Mejoras en la interfaz de usuario basadas en feedback
- Optimización de rendimiento en operaciones de gran volumen
- Ampliación de capacidades de reportes personalizados

**Mediano plazo (6-12 meses)**:
- Integración con sistemas externos (ERP, RRHH)
- Implementación de análisis predictivo para planificación
- Expansión a nuevas plataformas (versión web avanzada)

**Largo plazo (1-2 años)**:
- Módulos de inteligencia artificial para optimización de asignaciones
- Sistema completo de gestión de inventario relacionado
- Expansión a módulos complementarios (facturación, costos)

## 14. Conclusiones y Recomendaciones

CargoPlanner representa una solución integral al problema de la gestión operativa en entornos empresariales, especialmente aquellos con alta demanda de coordinación de personal y tareas.

Su arquitectura modular, enfoque multiplataforma y diseño centrado en el usuario lo posicionan como una herramienta valiosa para mejorar la eficiencia operativa y la toma de decisiones basada en datos.

### Recomendaciones para implementación exitosa:

1. Realizar un análisis detallado de procesos actuales antes de la implementación
2. Planificar una estrategia de migración de datos si existen sistemas previos
3. Establecer un programa de capacitación escalonado por niveles de usuario
4. Implementar inicialmente en áreas piloto antes de un despliegue completo
5. Establecer métricas claras para evaluar el impacto del sistema en la eficiencia operativa

---

## Anexos

### Anexo 1: Glosario de Términos

| Término | Definición |
|---------|------------|
| Operación | Tarea o operación específica a la que se destinan trabajadores |
| Trabajador | Personal disponible para ser asignado a tareas específicas |
| Grupo de Trabajo | Conjunto de trabajadores agrupados para una tarea común |
| Área | División organizacional donde se realizan actividades específicas |
| Motonave | Embarcación o nave relacionada con operaciones logísticas |
| Zona | División geográfica donde se realizan operaciones |

### Anexo 2: Referencias Técnicas

- Documentación oficial de Flutter: https://flutter.dev/docs
- Documentación de NestJS: https://docs.nestjs.com/
- Especificación JWT: https://jwt.io/introduction
- Documentación de Prisma ORM: https://www.prisma.io/docs
- Guías de Flutter Provider: https://pub.dev/packages/provider

---

# INFORME DE PRÁCTICAS LABORALES - TECNOLOGÍA EN DESARROLLO DE SOFTWARE

## 1. Datos Generales

- **Nombre de los Estudiantes:** 
  - Olvadis Hernandez Ledesma
  - Deyler Andres Mena Varela
- **Números de Identificación Estudiantil:** 
  - [Número de identificación de Olvadis]
  - [Número de identificación de Deyler]
- **Carrera:** Tecnología en Desarrollo de Software
- **Institución Educativa:** Politécnico Colombiano Jaime Isaza Cadavid
- **Nombre de la Empresa:** Cargoban - Operador Logístico y Portuario de Urabá
- **Ubicación de la Empresa:** Apartadó, Antioquia, Colombia
- **Periodo de Prácticas:** Enero 2025 - Abril 2025

## 2. Introducción

Las prácticas laborales constituyen un componente fundamental en la formación integral de los estudiantes de Tecnología en Desarrollo de Software. Este informe documenta la experiencia adquirida durante el periodo de prácticas realizadas en Cargoban, un operador logístico y portuario líder en la región de Urabá, donde se tuvo la oportunidad de aplicar los conocimientos teóricos adquiridos durante la carrera en un entorno empresarial real.

La creciente actividad portuaria en la región de Urabá, especialmente con la expansión de operaciones logísticas relacionadas con la exportación de frutas y otros productos, ha generado desafíos significativos en la gestión operativa. En este contexto, las prácticas se enfocaron en el desarrollo e implementación del sistema CargoPlanner, una solución integral diseñada para optimizar la planificación de operaciones y la operación de trabajadores en entornos portuarios.

## 3. Objetivos de la Práctica

### 3.1. Objetivo General

Desarrollar e implementar un sistema de gestión operativa (CargoPlanner) que optimice los procesos de operación de personal y seguimiento de operaciones en Cargoban, aplicando metodologías ágiles de desarrollo y tecnologías modernas para mejorar la eficiencia operativa de la empresa.

### 3.2. Objetivos Específicos

- Analizar los procesos operativos actuales de la empresa para identificar áreas de mejora y requerimientos específicos del sistema.
- Diseñar e implementar una interfaz intuitiva que facilite la gestión de asignaciones de trabajadores portuarios a diferentes operaciones.
- Desarrollar la arquitectura backend robusta que soporte la gestión de datos, autenticación y comunicación API para todas las funcionalidades del sistema.
- Implementar mecanismos de seguimiento en tiempo real para monitorear el estado de operaciones y la disponibilidad de personal.
- Crear un sistema flexible de reportes y análisis que permita la toma de decisiones basada en datos.
- Capacitar al personal de la empresa en el uso y administración del sistema desarrollado.

## 4. Descripción de la Empresa

Cargoban es un operador logístico y portuario líder en la región de Urabá, Colombia. La empresa se especializa en la prestación de servicios logísticos integrales para el comercio exterior, con énfasis en operaciones de carga, descarga y consolidación de contenedores principalmente para la industria bananera y otros productos agrícolas de exportación.

### 4.1 Misión

Proporcionar soluciones logísticas y portuarias integrales, eficientes y seguras que contribuyan a la competitividad de nuestros clientes y al desarrollo económico de la región de Urabá.

### 4.2 Visión

Ser reconocidos para 2030 como el operador logístico y portuario de referencia en la región de Urabá, liderando la transformación digital de la industria y promoviendo prácticas sostenibles en todas nuestras operaciones.

### 4.3 Servicios Principales

- Operaciones de carga y descarga de buques
- Consolidación y desconsolidación de contenedores
- Almacenamiento temporal de mercancías
- Coordinación de cadena logística para exportaciones e importaciones
- Servicios de documentación para comercio exterior

### 4.4 Estructura Organizativa

Cargoban cuenta con aproximadamente 150 empleados organizados en las siguientes áreas:

- Dirección General
- Operaciones Portuarias
- Logística y Transporte
- Administración y Finanzas
- Recursos Humanos
- Tecnología e Innovación (donde se realizaron las prácticas)

## 5. Actividades Realizadas

### 5.1. Proyecto CargoPlanner

#### Título del Proyecto
CargoPlanner: Sistema Integral de Gestión Operativa para Operaciones Portuarias

#### Descripción del Proyecto
CargoPlanner es un sistema diseñado para optimizar la planificación de operaciones y la operación de trabajadores en el entorno portuario de Cargoban. El sistema permite una mejor coordinación entre supervisores, seguimiento en tiempo real de operaciones, gestión eficiente de recursos humanos y generación de reportes analíticos para la toma de decisiones.

#### Tecnologías Utilizadas

**Backend (Desarrollado por Deyler Andres Mena Varela):**
- NestJS como framework principal
- TypeScript para desarrollo
- PostgreSQL como base de datos
- Prisma ORM para interacción con la base de datos
- JWT para autenticación segura
- Swagger para documentación de API

**Frontend (Desarrollado por Olvadis Hernandez Ledesma):**
- Flutter para desarrollo multiplataforma
- Provider para gestión de estado
- Flutter Neumorphic Plus para interfaz de usuario
- FL Chart para visualización de datos y reportes
- HTTP para comunicación con API
- SharedPreferences para almacenamiento local

#### Contribuciones

**Deyler Andres Mena Varela (Desarrollo Backend):**
- Diseño e implementación de la arquitectura del backend
- Desarrollo de endpoints REST para todas las funcionalidades
- Implementación del sistema de autenticación y autorización
- Configuración y gestión de base de datos PostgreSQL con Prisma
- Optimización de consultas y rendimiento del servidor
- Documentación de API con Swagger

**Olvadis Hernandez Ledesma (Desarrollo Frontend):**
- Diseño de interfaz de usuario responsiva y amigable
- Implementación de las pantallas principales de la aplicación
- Desarrollo del sistema de visualización de datos en tiempo real
- Creación de componentes para gestión de asignaciones y seguimiento
- Implementación de sistema de reportes y exportación
- Adaptación de la aplicación para múltiples plataformas (Android, iOS, Windows)

### 5.2. Tareas Diarias

**Actividades Comunes:**
- Participación en reuniones diarias de equipo (stand-ups)
- Revisión y planificación de sprints semanales
- Documentación de código y funcionalidades
- Pruebas unitarias y de integración
- Solución de problemas y optimización

**Actividades Específicas Backend (Deyler):**
- Mantenimiento y actualización de servicios API
- Configuración y optimización de consultas a base de datos
- Implementación de lógica de negocio para asignaciones y operaciones
- Desarrollo de servicios para reportes y análisis
- Gestión de seguridad y permisos

**Actividades Específicas Frontend (Olvadis):**
- Desarrollo de interfaces de usuario según diseños aprobados
- Implementación de lógica para consumo de APIs
- Creación de componentes interactivos y responsivos
- Optimización de rendimiento en dispositivos móviles
- Implementación de cache y estrategias offline-first

### 5.3. Aprendizajes

Durante el periodo de prácticas, se adquirieron y reforzaron numerosos conocimientos y habilidades:

**Aprendizajes Técnicos:**
- Dominio de arquitecturas de microservicios con NestJS
- Desarrollo avanzado de aplicaciones multiplataforma con Flutter
- Implementación de sistemas de autenticación seguros
- Técnicas de optimización de rendimiento en bases de datos
- Patrones de diseño aplicados a desarrollo de software

**Habilidades Blandas:**
- Trabajo efectivo en equipo multidisciplinario
- Comunicación técnica con stakeholders no técnicos
- Gestión del tiempo y planificación de entregas
- Resolución creativa de problemas complejos
- Adaptabilidad a cambios en requerimientos

## 6. Evaluación y Reflexiones

### 6.1. Evaluación Personal

El desarrollo del sistema CargoPlanner presentó diversos desafíos técnicos y logísticos que requirieron soluciones creativas y adaptabilidad. Uno de los mayores desafíos fue la implementación del seguimiento en tiempo real de operaciones en un entorno con conectividad intermitente, lo cual se resolvió mediante la implementación de estrategias de sincronización inteligente y funcionalidad offline.

La experiencia permitió aplicar conocimientos teóricos en un contexto real, comprendiendo las implicaciones prácticas de las decisiones de diseño y arquitectura en un sistema empresarial crítico. La necesidad de balancear funcionalidades avanzadas con usabilidad para usuarios con diferentes niveles de alfabetización digital fue particularmente instructiva.

### 6.2. Evaluación sobre la Empresa

Cargoban demostró ser un excelente espacio para la realización de prácticas profesionales, ofreciendo:

- Un ambiente de trabajo colaborativo que fomenta la innovación
- Mentoría técnica de calidad por parte del equipo de tecnología
- Exposición a problemas reales de la industria logística y portuaria
- Apertura para implementar nuevas tecnologías y metodologías
- Infraestructura adecuada para el desarrollo de proyectos tecnológicos

El apoyo constante de la dirección y la clara definición de objetivos permitieron que el proyecto se desarrollara con éxito. La empresa mostró gran interés en incorporar tecnologías modernas para mejorar sus procesos, lo que generó un entorno ideal para la aplicación de conocimientos académicos en problemas del mundo real.

## 7. Conclusiones

La experiencia de prácticas en Cargoban ha sido excepcionalmente valiosa para la formación profesional, permitiendo consolidar conocimientos teóricos y desarrollar habilidades prácticas en un entorno empresarial real. El desarrollo del sistema CargoPlanner no solo ha mejorado significativamente los procesos operativos de la empresa, sino que también ha proporcionado una experiencia completa de ciclo de vida de desarrollo de software.

La implementación exitosa del sistema demuestra la importancia de combinar sólidos conocimientos técnicos con una comprensión profunda del negocio y las necesidades de los usuarios finales. La experiencia ha reforzado la importancia de la comunicación efectiva, la adaptabilidad y el aprendizaje continuo como competencias fundamentales para un profesional en desarrollo de software.

Los conocimientos adquiridos durante la carrera en el Politécnico Colombiano Jaime Isaza Cadavid fueron fundamentales para enfrentar los desafíos presentados, y la experiencia práctica ha complementado significativamente la formación académica, preparando mejor para los retos del mundo laboral.

## 8. Anexos

- Capturas de pantalla de la aplicación CargoPlanner
- Diagrama de arquitectura del sistema
- Certificado de prácticas emitido por Cargoban
- Carta de recomendación del supervisor de prácticas
- Manual de usuario del sistema CargoPlanner

---

*Informe preparado por:*  
*Olvadis Hernandez Ledesma & Deyler Andres Mena Varela*  
*Estudiantes de Tecnología en Desarrollo de Software*  
*Politécnico Colombiano Jaime Isaza Cadavid*

*Apartadó, 25 de Abril de 2025*

