from fastapi import HTTPException, status

from app.core.enums import IncidenteEstado, TRANSICIONES_ESTADO_INCIDENTE


class EstadoIncidenteValidator:
    ALIASES_ESTADO = {
        "en_proceso": "en_progreso",
    }

    @staticmethod
    def parse_estado(valor: str) -> IncidenteEstado:
        valor_normalizado = EstadoIncidenteValidator.ALIASES_ESTADO.get(valor, valor)
        try:
            return IncidenteEstado(valor_normalizado)
        except ValueError as exc:
            validos = [estado.value for estado in IncidenteEstado]
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Estado inválido. Válidos: {validos}",
            ) from exc

    @classmethod
    def validar_transicion(cls, estado_actual: str, estado_nuevo: str) -> None:
        actual = cls.parse_estado(estado_actual)
        nuevo = cls.parse_estado(estado_nuevo)

        if actual == nuevo:
            return

        permitidos = TRANSICIONES_ESTADO_INCIDENTE.get(actual, set())
        if nuevo not in permitidos:
            permitidos_str = [estado.value for estado in permitidos]
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    f"Transición inválida de '{actual.value}' a '{nuevo.value}'. "
                    f"Permitidos desde '{actual.value}': {permitidos_str}"
                ),
            )
