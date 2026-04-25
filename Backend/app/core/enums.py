from enum import Enum


class IncidenteEstado(str, Enum):
    PENDIENTE = "pendiente"
    ANALIZANDO = "analizando"
    NOTIFICANDO = "notificando"
    ASIGNADO = "asignado"
    EN_PROGRESO = "en_progreso"
    EN_PROCESO = "en_progreso"
    RESUELTO = "resuelto"
    CANCELADO = "cancelado"
    CERRADO = "cerrado"


TRANSICIONES_ESTADO_INCIDENTE: dict[IncidenteEstado, set[IncidenteEstado]] = {
    IncidenteEstado.PENDIENTE: {
        IncidenteEstado.ANALIZANDO,
        IncidenteEstado.CANCELADO,
    },
    IncidenteEstado.ANALIZANDO: {
        IncidenteEstado.NOTIFICANDO,
        IncidenteEstado.CANCELADO,
    },
    IncidenteEstado.NOTIFICANDO: {
        IncidenteEstado.ASIGNADO,
        IncidenteEstado.CANCELADO,
    },
    IncidenteEstado.ASIGNADO: {
        IncidenteEstado.EN_PROGRESO,
        IncidenteEstado.CANCELADO,
    },
    IncidenteEstado.EN_PROGRESO: {
        IncidenteEstado.RESUELTO,
        IncidenteEstado.CANCELADO,
    },
    IncidenteEstado.RESUELTO: {
        IncidenteEstado.CERRADO,
    },
    IncidenteEstado.CANCELADO: set(),
    IncidenteEstado.CERRADO: set(),
}
